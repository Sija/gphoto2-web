require "gphoto2"
require "hashids"

module GPhoto2
  @@hashids = Hashids.new

  def self.hashids
    @@hashids
  end

  class Camera
    getter id : String do
      sn = self[:serialnumber]?
      id = if sn.try(&.some?)
             [model.hash, sn.to_s.hash]
           else
             [model.hash, port.hash]
           end
      GPhoto2.hashids.encode id
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
        info:   info.try(&.file),
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
        value = self.to_s.downcase
        value.empty? || value == "none"
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
