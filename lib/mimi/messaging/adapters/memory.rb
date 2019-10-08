# frozen_string_literal: true

require "timeout"

module Mimi
  module Messaging
    module Adapters
      #
      # A Memory is an in-memory implementation of a messaging adapter.
      #
      # All message dispatching happens within a single thread, the same as the caller's,
      # so all ivocations are synchronous.
      #
      # The Memory purpose is only to use in tests and for the higher abstractions
      # development.
      #
      class Memory < Base
        register_adapter_name "memory"

        def start
        end

        def stop
        end

        def command(target, message, opts = {})
          message_serialized = serialize(message)
          dispatch_command(target, message_serialized, opts)
          nil
        end

        def query(target, message, opts = {})
          message_serialized = serialize(message)
          response_serialized = dispatch_query(target, message_serialized, opts)
          deserialize(response_serialized)
        end

        def event(target, message, opts = {})
          message_serialized = serialize(message)
          dispatch_event(target, message_serialized, opts)
        end

        def start_request_processor(queue_name, processor, _opts = {})
          super
          request_processors[queue_name] ||= []
          request_processors[queue_name] << processor
        end

        def start_event_processor(topic_name, processor, _opts = {})
          super
          event_processors[topic_name] ||= []
          event_processors[topic_name] << processor
        end

        def start_event_processor_with_queue(topic_name, queue_name, processor, opts = {})
          super
          event_processors_with_queue[topic_name] ||= {}
          event_processors_with_queue[topic_name][queue_name] ||= []
          event_processors_with_queue[topic_name][queue_name] << processor
        end

        def stop_all_processors
          @request_processors = {}
          @event_processors = {}
          @event_processors_with_queue = {}
        end

        private

        def dispatch_command(target, message_serialized, _opts = {})
          queue_name, method_name = target.split("/")
          message = deserialize(message_serialized)
          return unless request_processors[queue_name]

          # pick random processor serving the target
          processor = request_processors[queue_name].sample
          processor.call_command(method_name, message, {})
        end

        def dispatch_query(target, message_serialized, _opts = {})
          queue_name, method_name = target.split("/")
          message = deserialize(message_serialized)
          raise Timeout::Error unless request_processors[queue_name]

          # pick random processor serving the target
          processor = request_processors[queue_name].sample
          response = processor.call_query(method_name, message, {})
          serialize(response)
        end

        def dispatch_event(target, message_serialized, _opts = {})
          topic_name, event_type = target.split("#")
          processors = event_processors[topic_name] || []
          processor_queues = event_processors_with_queue[topic_name] || {}
          processor_queues.values.each do |same_queue_processors|
            processors << same_queue_processors.sample
          end

          message = deserialize(message_serialized)
          processors.each do |processor|
            processor.call_event(event_type, message, {})
          end
        end

        def request_processors
          @request_processors ||= {}
        end

        def event_processors
          @event_processors ||= {}
        end

        def event_processors_with_queue
          @event_processors_with_queue ||= {}
        end
      end # class Memory
    end # module Adapters
  end # module Messaging
end # module Mimi
