require "json"
require "compress/zip"
require "pool/connection"
require "gphoto2"
require "kemal"
require "raven"
require "raven/integrations/kemal"
require "vips"

require "./ext/*"
require "./gphoto2/web"

Raven::Configuration::IGNORE_DEFAULT << GPhoto2::Web::CameraNotFoundError
