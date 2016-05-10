module Mimi
  module Messaging
    class Request
      attr_reader :request_processor, :delivery_info, :metadata, :raw_message, :params

      def initialize(request_processor, d, m, p)
        @request_processor = request_processor
        @delivery_info = d
        @metadata = m
        @raw_message = p
        @params = Params.new(Mimi::Messaging::Message.decode(@raw_message))
      end

      def method_name
        metadata.headers && metadata.headers['method_name']
      end

      def type
        request_processor.request_type(@delivery_info, @metadata, @raw_message)
      end

      def canonical_name
        "#{type.to_s.upcase} #{request_processor.resource_name}/#{method_name}"
      end

      def params_symbolized
        Hashie.symbolize_keys(params.to_hash)
      end

      def get?
        type == :get
      end

      def send_response(data = {})
        return if !get? || replied?
        raise ArgumentError, 'Invalid response format, Hash is expected' unless data.is_a?(Hash)
        reply_to_queue_name = metadata[:reply_to]
        raw_message = Mimi::Messaging::Message.encode(data)
        request_processor.connection.post(
          reply_to_queue_name, raw_message, correlation_id: metadata[:correlation_id]
        )
        @replied = true
      end

      def replied?
        @replied
      end

      class Params < Hashie::Mash
        def to_s
          to_hash.to_s
        end
      end # class Params
    end # class Request
  end # module Messaging
end # module Mimi
