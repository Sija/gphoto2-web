require "http"
require "json"
require "mime"
require "log"
require "compress/zip"
require "pool/connection"
require "debug"
require "exif"
require "gphoto2"
require "kemal"
require "raven"
require "raven/integrations/kemal"
require "vips"

require "./ext/*"
require "./gphoto2/web"

Raven::Configuration::IGNORE_DEFAULT << GPhoto2::Web::CameraNotFoundError
Raven::Configuration::IGNORE_DEFAULT << EXIF::NoDataError
