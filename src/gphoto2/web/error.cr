module GPhoto2
  module Web
    class CameraNotFoundError < Exception
      def initialize
        super("Camera not found")
      end
    end
  end
end
