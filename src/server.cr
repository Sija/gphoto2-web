require "./gphoto2-web"

Log.setup do |config|
  config.bind "raven.*", :warn, Log::IOBackend.new
  config.bind "*", :debug, Raven::LogBackend.new(record_breadcrumbs: true)
  config.bind "*", :warn, Raven::LogBackend.new(capture_exceptions: true)
  config.bind "*", :fatal, Raven::LogBackend.new(capture_all: true)
end

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
