require "./gphoto2-web"

production = Kemal.config.env == "production"

Log.setup do |c|
  severity =
    production ? Log::Severity::Info : Log::Severity::Debug

  c.bind "raven.*", severity, Log::IOBackend.new
  c.bind "*", :debug, Raven::LogBackend.new(record_breadcrumbs: true)
  c.bind "*", :warn, Raven::LogBackend.new(capture_exceptions: true)
  c.bind "*", :fatal, Raven::LogBackend.new(capture_all: true)
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
