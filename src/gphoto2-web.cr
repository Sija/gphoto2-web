require "tempfile"
require "json"
require "gphoto2"
require "kemal"
require "pool/connection"
require "zip-crystal/zip"

require "./ext/*"
require "./gphoto2/web"

module GPhoto2
  module Web
    class RemovePoweredByHeaderHandler
      include HTTP::Handler

      def call(context)
        context.response.headers.delete "X-Powered-By"
        call_next context
      end
    end
  end
end

Kemal.config.add_handler GPhoto2::Web::RemovePoweredByHeaderHandler.new
Kemal.run
