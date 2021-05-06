require "digest/sha1"
require "compress/zip"
require "gphoto2"

require "./gphoto2/*"

module GPhoto2
  class Camera
    getter id : String do
      sn = self[:serialnumber]?
      id = sn.try(&.some?) ? sn.to_s : port
      Digest::SHA1.hexdigest "#{model}-#{id}"
    end
  end

  class CameraWidget::Base
    def none? : Bool
      value = to_s.downcase.presence
      value.in?(nil, "none")
    end

    def some? : Bool
      !none?
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
end
