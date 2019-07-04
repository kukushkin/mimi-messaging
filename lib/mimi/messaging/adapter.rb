# frozen_string_literal: true

module Mimi
  module Messaging
    #
    # An abstract messaging Adapter
    #
    class Adapter
      #
      # Registers adapter class with given adapter name
      #
      # @param adapter_name [String,Symbol]
      #
      def self.register_adapter_name(adapter_name)
        adapter_name = adapter_name.to_s
        if Mimi::Messaging::Adapter.registered_adapters.key?(adapter_name)
          raise "Mimi::Messaging adapter '#{adapter_name}' is already registered"
        end
        Mimi::Messaging::Adapter.registered_adapters[adapter_name] = self
      end

      # Returns a Hash containing all registered adapters.
      #
      # The Hash
      #
      # @return [Hash{String => Class < Mimi::Messaging::Adapter}]
      #
      def self.registered_adapters
        @registered_adapters ||= {}
      end

      #
      # Creates an Adapter instance
      #
      def initialize(params = {})
      end

      # Opens the connection and then starts all request processors and event listeners.
      #
      # All the request processors, event listeners and a message serializer must be
      # registered before the adapter is started.
      #
      def start
        raise "Method #start() is not implemented by #{self.class}"
      end

      # Stops all request processors and event listeners and then closes the connection
      #
      def stop
        raise "Method #stop() is not implemented by #{self.class}"
      end

      # Sends the command to the given target
      #
      # @param target [String] "<queue>/<method>"
      # @param message [Hash]
      # @param opts [Hash] additional options
      #
      # @return nil
      # @raise [SomeError]
      #
      def command(target, message, opts = {})
        raise "Method #command() is not implemented by #{self.class}"
      end


      # Executes the query to the given target and returns response
      #
      # @param target [String] "<queue>/<method>"
      # @param message [Hash]
      # @param opts [Hash] additional options, e.g. :timeout
      #
      # @return [Hash]
      # @raise [SomeError,TimeoutError]
      #
      def query(target, message, opts = {})
        raise "Method #query() is not implemented by #{self.class}"
      end

      # Broadcasts the event with the given target
      #
      # @param target [String] "<topic>/<event_type>", e.g. "customers/created"
      # @param message [Hash]
      # @param opts [Hash] additional options
      #
      def broadcast(target, message, opts = {})
        raise "Method #broadcast() is not implemented by #{self.class}"
      end

      # Registers a request (command and/or query) processor.
      #
      # Processor must respond to #call() which accepts 2 arguments (method, request).
      # It must #ack! or #nack! request and it must return a Hash if the request is #query?
      #
      # If the processor raises an error, the request will be NACK-ed and accepted again
      # at a later time.
      #
      # @param queue_name [String] "<queue>"
      # @param processor [#call()]
      # @param opts [Hash] additional adapter-specific options
      #
      def register_request_processor(queue_name, processor, opts = {})
        raise "Method #register_request_processor() is not implemented by #{self.class}"
      end

      # Registers an event listener without a queue
      #
      # @param event_topic [String] "<topic>"
      # @param listener [#call()] something responding to #call() with 2 arguments (event_type, event)
      # @param opts [Hash] additional adapter-specific options
      #
      def register_event_listener(event_topic, listener)
        raise "Method #register_event_listener() is not implemented by #{self.class}"
      end

      # Registers an event listener with a queue
      #
      # @param event_topic [String] "<topic>"
      # @param queue_name [String] "<queue>"
      # @param listener [#call()] something responding to #call() with 2 arguments (event_type, event)
      # @param opts [Hash] additional adapter-specific options
      #
      def register_event_listener_with_queue(event_topic, queue_name, listener, opts = {})
        raise "Method #register_event_listener_with_queue() is not implemented by #{self.class}"
      end

      # Registers the message serializer
      #
      # Message serializer must implement methods #serialize(Hash) -> String
      # and #deserialize(String) -> Hash
      #
      # @param serializer [#serialize(),#deserialize()]
      #
      def register_message_serializer(serializer)
        raise "Message serializer is already registered in #{self.class}" if @serializer
        if !serializer.respond_to?(:serialize) || !serializer.respond_to?(:deserialize)
          raise "Invalid message serializer passed to #{self.class}"
        end
        @serializer = serializer
      end

      protected

      # Serializes a message (Hash) to be sent on-the-wire using configured serializer
      #
      # @param message [Hash]
      # @return [String]
      #
      def serialize(message)
        raise "Message serializer is not registered in #{self.class}" unless @serializer
        @serializer.serialize(message)
      end

      # Deserializes a message (String) received on-the-wire to a Hash
      #
      # @param message [String]
      # @return [Hash]
      #
      def deserialize(message)
        raise "Message serializer is not registered in #{self.class}" unless @serializer
        @serializer.deserialize(message)
      end
    end # class Adapter
  end # module Messaging
end # module Mimi
