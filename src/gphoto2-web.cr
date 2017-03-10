require "tempfile"
require "json"
require "zip"
require "gphoto2"
require "kemal"
require "pool/connection"

require "./ext/*"
require "./gphoto2/web"

Kemal.config.add_handler GPhoto2::Web::RemovePoweredByHeaderHandler.new
Kemal.run
