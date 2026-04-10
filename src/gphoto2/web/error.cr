module GPhoto2::Web
  class CameraNotFoundError < Exception
    def initialize
      super("Camera not found")
    end
  end
end
