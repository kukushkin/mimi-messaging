# frozen_string_literal: true

require "timeout"

module Mimi
  module Messaging
    module Adapters
      #
      # A Test is a mock adapter object for running tests.
      #
      class Test < Base
        register_adapter_name "test"

        def start
        end

        def stop
        end

        def command(target, message, opts = {})
        end

        def query(target, message, opts = {})
        end

        def event(target, message, opts = {})
        end

        def start_request_processor(queue_name, processor, _opts = {})
          super
          true
        end

        def start_event_processor(event_topic, processor, _opts = {})
          super
          true
        end

        def start_event_processor_with_queue(event_topic, queue_name, processor, opts = {})
          super
          true
        end

        def stop_all_processors
          true
        end
      end # class Test
    end # module Adapters
  end # module Messaging
end # module Mimi
