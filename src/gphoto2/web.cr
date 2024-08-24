require "./web/*"

module GPhoto2
  module Web
    @@cameras : Array(CameraWrapper)?
    @@cameras_mutex : Mutex = Mutex.new

    def self.cameras(&)
      @@cameras_mutex.synchronize do
        @@cameras ||=
          Camera.all.map &->CameraWrapper.new(Camera)

        yield @@cameras.not_nil! # ameba:disable Lint/NotNil
      end
    end

    def self.reset_cameras : Nil
      return unless @@cameras

      @@cameras_mutex.synchronize do
        @@cameras.try &.each &.camera.close
        @@cameras = nil
      end
    end

    def self.camera_by_id(id, *, exit = false, &)
      Debug.log id

      cameras do |cameras|
        wrapper = cameras.find &.camera.id.to_s.==(id)
        wrapper || raise CameraNotFoundError.new

        wrapper.pool.connection do |camera|
          yield camera
        ensure
          camera.exit if exit
        end
      end
    end
  end
end
