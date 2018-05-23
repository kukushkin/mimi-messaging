module Mimi
  module Messaging
    class Request
      attr_reader :response

      def send_response(data = {})
        return if !get? || replied?
        raise ArgumentError, 'Invalid response format, Hash is expected' unless data.is_a?(Hash)
        reply_to_queue_name = metadata[:reply_to]
        raw_message = Mimi::Messaging::Message.encode(data)
        @response = Mimi::Messaging::Message.new(Mimi::Messaging::Message.decode(raw_message))
        request_processor.connection.post(
          reply_to_queue_name, raw_message, correlation_id: metadata[:correlation_id]
        )
        @replied = true
      end
    end # class Request
  end # module Messaging
end # module Mimi
