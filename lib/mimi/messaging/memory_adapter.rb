# frozen_string_literal: true

module Mimi
  module Messaging
    class MemoryAdapter < Adapter
      register_adapter_name "memory"

      # blah

      # Starts the adapter
      #
      def start
      end

      def stop
      end

      def query(target, message, opts = {})
        message_serialized = serialize(message)
        puts "QUERY: #{target} #{message_serialized}"
        # raise "Method #query() is not implemented by #{self.class}"
        {}
      end
    end # class MemoryAdapter
  end # module Messaging
end # module Mimi
