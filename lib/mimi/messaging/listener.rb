module Mimi
  module Messaging
    class Listener < RequestProcessor
      DEFAULT_DURABLE_QUEUE_OPTIONS = {
        exclusive: false,
        durable: true,
        auto_delete: false
      }

      DEFAULT_TEMPORARY_QUEUE_OPTIONS = {
        exclusive: true,
        durable: false,
        auto_delete: true
      }

      abstract!

      queue_options DEFAULT_TEMPORARY_QUEUE_OPTIONS

      def self.queue(name = nil, opts = {})
        return super unless name
        queue_name(name)
        if name && name != ''
          queue_options(DEFAULT_DURABLE_QUEUE_OPTIONS.merge(opts))
        else
          queue_options(DEFAULT_TEMPORARY_QUEUE_OPTIONS.merge(opts))
        end
      end

      def self.default_queue_name
        ''
      end

      # Sets or gets notification resource name
      #
      def self.notification(name = nil, _opts = {})
        notification_name name
        true
      end

      # Sets or gets queue name
      #
      def self.notification_name(name = nil)
        if name && @notification_name
          raise "#{self} has already registered '#{@notification_name}' as notification name"
        end
        (@notification_name ||= name) || default_notification_name
      end

      # Default (inferred) notification name
      #
      def self.default_notification_name
        class_name_to_resource_name(name, 'listener')
      end

      def self.resource_name
        notification_name
      end

      def self.request_type(_d, _m, _p)
        :broadcast
      end

      def self.construct_queue
        exchange = channel.fanout(resource_name)
        q = channel.create_queue(queue_name, queue_options)
        q.bind(exchange)
        q
      end
    end # class Listener
  end # module Messaging
end # module Mimi
