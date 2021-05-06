require "gphoto2"

module GPhoto2
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
