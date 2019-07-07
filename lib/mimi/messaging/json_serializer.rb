# frozen_string_literal: true

require "json"

module Mimi
  module Messaging
    #
    # JSON serializer.
    #
    # De/Serializes a message (Hash) from/into a JSON object
    #
    module JsonSerializer
      #
      # Serialize given message into JSON object
      #
      # @param message [Hash]
      # @return [String]
      #
      def self.serialize(message)
        unless message.is_a?(Hash)
          raise ArgumentError, "Invalid message passed to #{self}#serialize, Hash is expected"
        end

        message.to_json
      rescue StandardError => e
        raise "#{self} failed to serialize a message: #{e}"
      end

      # Deserializes a JSON into a message
      #
      # @param message [String]
      # @return [Hash]
      #
      def self.deserialize(message)
        unless message.is_a?(String)
          raise ArgumentError, "Invalid message passed to #{self}#deserialize, String is expected"
        end

        JSON.parse(message)
      rescue StandardError => e
        raise "#{self} failed to deserialize a message: #{e}"
      end
    end # module JsonSerializer
  end # module Messaging
end # module Mimi
