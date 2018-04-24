module Mimi
  module Messaging
    class Notification < Hashie::Mash
      def self.notification(name, _opts = {})
        @notification_name = name
      end

      def self.notification_name
        @notification_name || default_notification_name
      end

      def self.default_notification_name
        Mimi::Messaging::RequestProcessor.class_name_to_resource_name(self, 'notification')
      end

      def self.broadcast(name, data = {}, opts = {})
        headers = { method_name: name.to_s, Mimi::Messaging::CONTEXT_ID_KEY => logger.context_id }
        Mimi::Messaging.broadcast(
          notification_name, Message.encode(data), opts.merge(headers: headers)
        )
      end

      def broadcast(name, opts = {})
        self.class.broadcast(name, self, opts)
      end

      def to_s
        to_hash.to_s
      end
    end # class Notification
  end # module Messaging
end # module Mimi
