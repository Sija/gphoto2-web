require "./gphoto2-web"

Raven.configure do |config|
  config.async = true
  config.current_environment = Kemal.config.env
end

Kemal.config do |config|
  config.powered_by_header = false
  config.logger = Raven::Kemal::LogHandler.new(Kemal::LogHandler.new)
  config.add_handler Raven::Kemal::ExceptionHandler.new
end

Kemal.run
