require "./web/*"

module GPhoto2
  module Web
    @@cameras : Array(CameraWrapper)? = nil
    @@cameras_mutex : Mutex = Mutex.new

    def self.cameras : Array(CameraWrapper)
      return @@cameras.not_nil! if @@cameras
      @@cameras_mutex.synchronize do
        @@cameras ||= GPhoto2::Camera.all.map &->CameraWrapper.new(Camera)
      end
    end

    def self.reset_cameras : Void
      return unless @@cameras
      @@cameras_mutex.synchronize do
        @@cameras.try &.each &.camera.close
        @@cameras = nil
      end
    end

    @[AlwaysInline]
    def self.camera_by_id(id) : GPhoto2::Camera
      GPhoto2.log id

      found = cameras.select &.camera.id.==(id)
      unless wrapper = found.first?
        raise CameraNotFoundError.new
      end
      # need to unwrap camera object
      wrapper.camera
    end

    @[AlwaysInline]
    def self.camera_by_id(id, exit = false, &block)
      GPhoto2.log id

      found = cameras.select &.camera.id.==(id)
      unless wrapper = found.first?
        raise CameraNotFoundError.new
      end
      wrapper.pool.connection do |camera|
        yielded_value = yield camera
        camera.exit if exit
        yielded_value
      end
    end
  end
end
