module GPhoto2
  module Web
    class CameraWrapper
      getter camera : GPhoto2::Camera

      getter pool : ConnectionPool(GPhoto2::Camera) do
        ConnectionPool.new(capacity: 1, timeout: @timeout) { camera }
      end

      def initialize(@camera, @timeout = 10.0); end

      # forward_missing_to :camera
    end
  end
end
