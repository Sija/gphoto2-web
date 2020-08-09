require "digest/sha1"
require "gphoto2"

module GPhoto2
  class Camera
    getter id : String do
      sn = self[:serialnumber]?
      id = sn.try(&.some?) ? sn.to_s : port
      Digest::SHA1.hexdigest "#{model}-#{id}"
    end
  end

  class Camera
    def to_json(json : JSON::Builder)
      {
        id:        id,
        model:     model,
        port:      port,
        abilities: abilities,
      }.to_json(json)
    end
  end

  class CameraAbilities
    def to_json(json : JSON::Builder)
      {
        driver_status:     status.to_s,
        device_type:       device_type.to_s,
        operations:        operations.to_s,
        file_operations:   file_operations.to_s,
        folder_operations: folder_operations.to_s,
      }.to_json(json)
    end
  end

  class CameraFolder
    private def zip_visitor(zip, folder : CameraFolder, root : String? = nil)
      folder.files.each do |file|
        pathname = root ? File.join(root, file.path) : file.path
        pathname = pathname[1..] if pathname.starts_with? '/'
        mtime = file.info.file?.try(&.mtime) || Time.local
        entry = Compress::Zip::Writer::Entry.new pathname, time: mtime

        zip.add entry, file.to_slice
      end
      folder.folders.each do |child|
        zip_visitor(zip, child, root)
      end
    end

    def to_zip_file(io : IO, root : String? = nil) : Nil
      root ||= name

      Compress::Zip::Writer.open(io) do |zip|
        zip_visitor zip, self, root
      end
    end

    def to_zip_file(root : String? = nil) : File
      File.tempfile(prefix: "camera.fs", suffix: ".zip") do |file|
        to_zip_file(file, root)
      end
    end

    def to_zip_file(root : String? = nil) : Nil
      tempfile = to_zip_file(root)
      begin
        yield tempfile
      ensure
        tempfile.delete
      end
    end
  end

  class CameraFolder
    def to_json(json : JSON::Builder)
      {
        path:    path,
        name:    name,
        folders: folders,
        files:   files,
      }.to_json(json)
    end
  end

  class CameraFile
    def to_json(json : JSON::Builder)
      {
        path:   path,
        folder: folder,
        name:   name,
        info:   info.file?,
      }.to_json(json)
    end
  end

  class CameraFileInfo
    class File
      def to_json(json : JSON::Builder)
        {
          type:      type,
          size:      size,
          mtime:     mtime,
          readable:  readable?,
          deletable: deletable?,
          width:     width,
          height:    height,
        }.to_json(json)
      end
    end
  end

  class CameraWidget
    class Base
      def none?
        value = to_s.downcase.presence
        value.in?(nil, "none")
      end

      def some?
        !none?
      end

      def to_json(json : JSON::Builder)
        {
          name:     name,
          label:    label,
          info:     info,
          type:     type.to_s,
          value:    value, # rescue NotImplementedError ?
          readonly: readonly?,
        }.to_json(json)
      end
    end

    class Window
      def to_json(json : JSON::Builder)
        {
          name:     name,
          label:    label,
          info:     info,
          type:     type.to_s,
          children: children,
        }.to_json(json)
      end
    end

    class Section
      def to_json(json : JSON::Builder)
        {
          name:     name,
          label:    label,
          info:     info,
          type:     type.to_s,
          children: children,
        }.to_json(json)
      end
    end
  end
end
