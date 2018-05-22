module Mimi
  module Messaging
    class RequestProcessor
      attr_reader :result

      def self.started?
        !@consumer.nil?
      end

      # Mock start
      #
      def self.start
        return if abstract?
        raise "#{name} already started" if started?
        logger.debug "#{self} starting to serve '#{resource_name}' (#{exposed_methods})"
        @queue = construct_queue
        @consumer_mutex = Mutex.new
        @consumer_mutex.synchronize do
          @consumer = true
        end
        # consumer created, mutex released
      end

      # Mock stop
      #
      def self.stop
        return if abstract?
        raise "#{name} already stopped" unless started?
        @consumer_mutex.synchronize do
          @consumer = nil
        end
        @consumer = nil
        @queue = nil
        @channel = nil
        @connection = nil
      end

      # MockRequestProcessor helper GET methods
      #
      # @param method_name [Symbol]
      # @param message [Hash]
      #
      # @return [Mimi::Messaging::Message]
      #
      def self.get(method_name, message)
        metadata    = Mimi::Messaging::Message.new(
          correlation_id: 1,
          reply_to: 'mock_client',
          headers: {
            'method_name' =>  method_name.to_s,
            'c' => 'mock-context'
          }
        )
        d           = Mimi::Messaging::Message.new()
        raw_message = Mimi::Messaging::Message.new(message).to_msgpack
        request_processor = new(d, metadata, raw_message)
        request_processor.result
      end

      # MockRequestProcessor helper POST method
      #
      # @param method_name [Symbol]
      # @param message [Hash]
      #
      # @return [Mimi::Messaging::Message]
      #
      def self.post(method_name, message)
        metadata    = Mimi::Messaging::Message.new(
          headers: {
            'method_name' =>  method_name.to_s,
            'c' => 'context-id'
          }
        )
        d           = Mimi::Messaging::Message.new()
        raw_message = Mimi::Messaging::Message.new(message)
        request_processor = new(d, metadata, raw_message)
        nil
      end

      # MockRequestProcessor helper BROADCAST method
      #
      # @param method_name [Symbol]
      # @param message [Hash]
      #
      # @return [Mimi::Messaging::Message]
      #
      def self.broadcast(method_name, message)
        post(method_name, message)
      end
    end # class RequestProcessor
  end # module Messaging
end # module Mimi
