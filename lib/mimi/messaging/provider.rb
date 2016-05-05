module Mimi
  module Messaging
    class Provider < RequestProcessor
      abstract!
      queue_options exclusive: false, auto_delete: true

      def self.default_queue_name
        class_name_to_resource_name(name, 'provider')
      end

      def initialize(d, m, p)
        super
        begin
          catch(:halt) do
            reply(@result) unless request.replied?
          end
        rescue StandardError => e
          __execute_error_handlers(e)
        end
        if request.get? && !request.replied?
          logger.error "No response sent to #{request.canonical_name}"
        end
      end

      # Default error handler for RequestError and its descendants
      #
      error RequestError do |e|
        logger.warn "#{request.canonical_name}: #{e} (#{e.params})"
        reply error: e.message, params: e.params
      end

      # Default error handler for StandardError and its descendants
      #
      error StandardError do |e|
        logger.error "#{request.canonical_name}: #{e} (#{e.class})"
        logger.debug((e.backtrace || ['<no backtrace>']).join("\n"))
        reply error: e.message
      end

      private

      def reply(data = {})
        request.send_response(data)
        halt
      end
    end # class Provider
  end # module Messaging
end # module Mimi
