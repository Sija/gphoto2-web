require "tempfile"
require "json"
require "zip"
require "gphoto2"
require "kemal"
require "pool/connection"
require "raven"
require "raven/integrations/kemal"

require "./ext/*"
require "./gphoto2/web"

Raven.configure do |config|
  config.async = true
end

Kemal.config do |config|
  config.logger = Raven::Kemal::LogHandler.new(Kemal::CommonLogHandler.new)

  config.add_handler Raven::Kemal::ExceptionHandler.new
  config.add_handler GPhoto2::Web::RemovePoweredByHeaderHandler.new
end

Kemal.run
