# frozen_string_literal: true

module Mimi
  module Messaging
    module Adapters
      #
      # An abstract messaging adapter.
      #
      # An adapter implementation must implement the following methods:
      # * #start()
      # * #stop()
      # * #command(target, message, opts)
      # * #query(target, message, opts)
      # * #event(target, message, opts)
      # * #start_request_processor(queue_name, processor, opts)
      # * #start_event_processor(topic_name, processor, opts)
      # * #start_event_processor_with_queue(topic_name, queue_name, processor, opts)
      # * #stop_all_processors
      #
      # An adapter implementation must register itself using `.register_adapter_name` method.
      #
      class Base
        attr_reader :serializer

        # Registers adapter class with given adapter name
        #
        # @param adapter_name [String,Symbol]
        #
        def self.register_adapter_name(adapter_name)
          adapter_name = adapter_name.to_s
          if Mimi::Messaging::Adapters.registered_adapters.key?(adapter_name)
            raise "Mimi::Messaging adapter '#{adapter_name}' is already registered"
          end

          Mimi::Messaging::Adapters.registered_adapters[adapter_name] = self
        end

        # Creates an Adapter instance
        #
        # @param params [Hash] adapter-specific configuration parameters
        #
        def initialize(params = {})
        end

        # Starts the adapter.
        #
        # All the message processors must be started after the adapter is started.
        # Before the adapter is started it MAY respond with an error to an attempt
        # to start a message processor.
        #
        # Serializer must be registered before any message is sent or received.
        #
        def start
          raise "Method #start() is not implemented by #{self.class}"
        end

        # Stops all message processors and then stops the adapter.
        #
        def stop
          raise "Method #stop() is not implemented by #{self.class}"
        end

        # Sends the command to the given target
        #
        # @param target [String] "<queue>/<method>"
        # @param message [Mimi::Messaging::Message]
        # @param opts [Hash] additional options
        #
        # @return nil
        # @raise [SomeError]
        #
        def command(_target, _message, _opts = {})
          raise "Method #command(target, message, opts) is not implemented by #{self.class}"
        end

        # Executes the query to the given target and returns response
        #
        # @param target [String] "<queue>/<method>"
        # @param message [Mimi::Messaging::Message]
        # @param opts [Hash] additional options, e.g. :timeout
        #
        # @return [Hash]
        # @raise [SomeError,TimeoutError]
        #
        def query(_target, _message, _opts = {})
          raise "Method #query(target, message, opts) is not implemented by #{self.class}"
        end

        # Broadcasts the event with the given target
        #
        # @param target [String] "<topic>#<event_type>", e.g. "customers#created"
        # @param message [Mimi::Messaging::Message]
        # @param opts [Hash] additional options
        #
        def event(_target, _message, _opts = {})
          raise "Method #event(target, message, opts) is not implemented by #{self.class}"
        end

        # Starts a request (command/query) processor.
        #
        # Processor must respond to #call_command() AND #call_query()
        # which accepts 3 arguments: (method, message, opts).
        #
        # TBD: It must #ack! or #nack! the message.
        #
        # If the processor raises an error, the message will be NACK-ed and accepted again
        # at a later time.
        #
        # NOTE: Method must be overloaded by a subclass.
        #
        # @param queue_name [String] "<queue>"
        # @param processor [#call_command(),#call_query()]
        # @param opts [Hash] additional adapter-specific options
        #
        def start_request_processor(_queue_name, processor, _opts = {})
          # validates processor
          if (
            processor.respond_to?(:call_command) && processor.method(:call_command).arity >= 3 &&
            processor.respond_to?(:call_query) && processor.method(:call_query).arity >= 3
          )
            return
          end

          raise(
            ArgumentError,
            "Invalid request processor passed to #{self.class}##{__method__}(), " \
            "expected to respond to #call_command(method_name, message, opts) AND #call_query(...)"
          )
        end

        # Starts an event processor without a queue
        #
        # Processor must respond to #call_event() which accepts 3 arguments:
        # (method, message, opts).
        #
        # TBD: It must #ack! or #nack! the message.
        #
        # If the processor raises an error, the message will be NACK-ed and accepted again
        # at a later time.
        #
        # @param topic_name [String] "<topic>"
        # @param processor [#call_event()]
        # @param opts [Hash] additional adapter-specific options
        #
        def start_event_processor(_topic_name, processor, _opts = {})
          # validates processor
          return if processor.respond_to?(:call_event) && processor.method(:call_event).arity >= 3

          raise(
            ArgumentError,
            "Invalid event processor passed to #{self.class}##{__method__}(), " \
            "expected to respond to #call_event(event_type, message, opts)"
          )
        end

        # Starts an event processor with a queue
        #
        # Processor must respond to #call_event() which accepts 3 arguments:
        # (method, message, opts).
        #
        # TBD: It must #ack! or #nack! the message.
        #
        # If the processor raises an error, the message will be NACK-ed and accepted again
        # at a later time.
        #
        # @param topic_name [String] "<topic>"
        # @param queue_name [String] "<queue>"
        # @param processor [#call_event()]
        # @param opts [Hash] additional adapter-specific options
        #
        def start_event_processor_with_queue(_topic_name, _queue_name, processor, _opts = {})
          # validates processor
          return if processor.respond_to?(:call_event) && processor.method(:call_event).arity >= 3

          raise(
            ArgumentError,
            "Invalid event processor passed to #{self.class}##{__method__}(), " \
            "expected to respond to #call_event(event_type, message, opts)"
          )
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

        # Stops all message (command, query and event) processors.
        #
        # Stops currently registered processors and stops accepting new messages
        # for processors.
        #
        def stop_all_processors
          raise "Method #stop_all_processors() is not implemented by #{self.class}"
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
      end # class Base
    end # module Adapters
  end # module Messaging
end # module Mimi
