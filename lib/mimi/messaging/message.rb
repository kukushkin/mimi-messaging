# frozen_string_literal: true

module Mimi
  module Messaging
    #
    # A Message is a Hash and additional headers structure.
    #
    class Message < Hash
      attr_reader :headers

      # Creates a Message out of Hash or another Message.
      #
      # @param message_or_hash [Hash,Message]
      # @param headers [Hash,nil] additional headers to attach to the message
      #
      def initialize(message_or_hash, headers = nil)
        unless message_or_hash.is_a?(Hash) # or a Message
          raise ArgumentError, "Message or Hash is expected as argument"
        end

        # copy attributes
        message_or_hash.each { |k, v| self[k] = v.dup }

        # copy headers
        headers ||= {}
        if message_or_hash.is_a?(Mimi::Messaging::Message)
          @headers = message_or_hash.headers.merge(headers)
        else
          @headers = headers
        end
      end
    end # class Message
  end # module Messaging
end # module Mimi