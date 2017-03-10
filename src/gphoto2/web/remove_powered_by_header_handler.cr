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
