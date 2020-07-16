module GPhoto2
  module Web
    class CameraWrapper
      getter camera : Camera
      getter pool : ConnectionPool(Camera) do
        ConnectionPool.new(
          capacity: 1,
          timeout: @timeout.total_seconds
        ) { camera }
      end

      def initialize(@camera, @timeout : Time::Span = 10.seconds)
      end

      # forward_missing_to :camera
    end
  end
end
