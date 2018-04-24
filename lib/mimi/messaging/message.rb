require 'json'
require 'msgpack'

module Mimi
  module Messaging
    class Message < Hashie::Mash
      def self.queue(name, _opts = {})
        @queue_name = name
      end

      def self.queue_name
        @queue_name || default_queue_name
      end

      def self.default_queue_name
        Mimi::Messaging::RequestProcessor.class_name_to_resource_name(self, 'message')
      end

      def self.get(name, data = {}, opts = {})
        headers = { method_name: name.to_s, Mimi::Messaging::CONTEXT_ID_KEY => logger.context_id }
        _d, _m, response = Mimi::Messaging.get(
          queue_name, encode(data), opts.deep_merge(headers: headers)
        )
        raise Timeout::Error unless response
        message = new(decode(response))
        raise RequestError.new(message.error, Message.new(message.params)) if message.error?
        message
      end

      def self.post(name, data = {}, opts = {})
        headers = { method_name: name.to_s, Mimi::Messaging::CONTEXT_ID_KEY => logger.context_id }
        Mimi::Messaging.post(
          queue_name, encode(data), opts.deep_merge(headers: headers)
        )
      end

      def self.add_method(name, &block)
        self.class.instance_eval do
          define_method(name, &block)
        end
      end

      def self.methods(*names)
        names.each do |method_name|
          add_method(method_name) do |*params|
            get(method_name, *params)
          end
          add_method("#{method_name}!") do |*params|
            post(method_name, *params)
            nil
          end
        end
      end

      def self.encode(data)
        MessagePack.pack(data) # data.to_json
      end

      def self.decode(raw_message)
        MessagePack.unpack(raw_message) # JSON.parse(raw_message)
      end

      def to_s
        to_hash.to_s
      end
    end # class Message
  end # module Messaging
end # module Mimi
