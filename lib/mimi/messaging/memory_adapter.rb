# frozen_string_literal: true

require "timeout"

module Mimi
  module Messaging
    #
    # A MemoryAdapter is an in-memory implementation of a messaging adapter.
    #
    # All message dispatching happens within a single thread, the same as the caller's,
    # so all ivocations are synchronous.
    #
    # The MemoryAdapter purpose is only to use in tests and for the higher abstractions
    # development.
    #
    class MemoryAdapter < Adapter
      register_adapter_name "memory"

      def start
      end

      def stop
      end

      def command(target, message, opts = {})
        message_serialized = serialize(message)
        dispatch_command(target, message_serialized, opts)
      end

      def query(target, message, opts = {})
        message_serialized = serialize(message)
        response_serialized = dispatch_query(target, message_serialized, opts)
        deserialize(response_serialized)
      end

      def broadcast(target, message, opts = {})
        message_serialized = serialize(message)
        dispatch_event(target, message_serialized, opts)
      end

      def register_command_processor(queue_name, processor, _opts = {})
        super
        registered_command_processors[queue_name] ||= []
        registered_command_processors[queue_name] << processor
      end

      def register_query_processor(queue_name, processor, _opts = {})
        super
        registered_query_processors[queue_name] ||= []
        registered_query_processors[queue_name] << processor
      end

      def register_event_processor(event_topic, processor, _opts = {})
        super
        registered_event_processors[event_topic] ||= []
        registered_event_processors[event_topic] << processor
      end

      def register_event_processor_with_queue(event_topic, queue_name, processor, opts = {})
        super
        registered_event_processors_with_queue[event_topic] ||= {}
        registered_event_processors_with_queue[event_topic][queue_name] ||= []
        registered_event_processors_with_queue[event_topic][queue_name] << processor
      end

      def deregister_all_processors
        @registered_command_processors = {}
        @registered_query_processors = {}
        @registered_event_processors = {}
        @registered_event_processors_with_queue = {}
      end

      private

      def dispatch_command(target, message_serialized, _opts = {})
        target_base, method_name = target.split("/")
        message = deserialize(message_serialized)
        return unless registered_command_processors[target_base]

        # pick random processor serving the target
        processor = registered_command_processors[target_base].sample
        processor.call_command(method_name, message, {})
      end

      def dispatch_query(target, message_serialized, _opts = {})
        target_base, method_name = target.split("/")
        message = deserialize(message_serialized)
        raise Timeout::Error unless registered_query_processors[target_base]

        # pick random processor serving the target
        processor = registered_query_processors[target_base].sample
        response = processor.call_query(method_name, message, {})
        serialize(response)
      end

      def dispatch_event(target, message_serialized, _opts = {})
        target_base, event_type = target.split("/")
        processors = registered_event_processors[target_base] || []
        processor_queues = registered_event_processors_with_queue[target_base] || {}
        processor_queues.values.each do |same_queue_processors|
          processors << same_queue_processors.sample
        end

        message = deserialize(message_serialized)
        processors.each do |processor|
          processor.call_event(event_type, message, {})
        end
      end

      def registered_command_processors
        @registered_command_processors ||= {}
      end

      def registered_query_processors
        @registered_query_processors ||= {}
      end

      def registered_event_processors
        @registered_event_processors ||= {}
      end

      def registered_event_processors_with_queue
        @registered_event_processors_with_queue ||= {}
      end
    end # class MemoryAdapter
  end # module Messaging
end # module Mimi
