require 'bunny'

module Mimi
  module Messaging
    class MockConnection
      attr_reader :queue_prefix

      # Creates a Connection with given connection params
      #
      # @param params [Hash] Connection params as accepted by Bunny
      # @param params[:queue_prefix] [String] (optional) Use this connection for all communication
      #                                       related to queues, having names starting with given
      #                                       prefix
      #
      def initialize(params = {})
        @queue_prefix = params[:queue_prefix]
        @channel_pool = {}
        bunny_params = {
          host: params[:mq_host],
          port: params[:mq_port],
          username: params[:mq_username],
          password: params[:mq_password],
          vhost: params[:mq_vhost]
        }
        @connection = { mock_connection: bunny_params }
      end

      # Starts the connection, opening actual connection to RabbitMQ
      #
      def start
        @started = true
      end

      # Stops the connection
      #
      def stop
        @channel_pool = {}
        @started = false
      end

      def started?
        @started
      end

      def channel
        raise ConnectionError unless started?
        @channel_pool[Thread.current.object_id] ||= create_channel
      end

      def create_channel(opts = {})
        MockChannel.new(@connection, opts)
      end

      def reply_queue
        raise ConnectionError unless started?
        channel.reply_queue
      end

      def post(queue_name, raw_message, params = {})
        channel.post(queue_name, raw_message, params)
      end

      def get(queue_name, raw_message, params = {})
        channel.get(queue_name, raw_message, params)
      end

      def broadcast(queue_name, raw_message, params = {})
        channel.broadcast(queue_name, raw_message, params)
      end

      class MockChannel
        attr_reader :options, :connection

        DEFAULT_OPTIONS = {
          concurrency: 1
        }
        DEFAULT_GET_TIMEOUT = 60 # seconds

        def initialize(connection, opts = {})
          @connection = connection
          @options = DEFAULT_OPTIONS.merge(opts)
          @channel = { mock_channel: @connection, opts: options[:concurrency] }
          @mutex = Mutex.new
        end

        def create_queue(name, opts = {})
          raise "Not implemented"
        end

        def reply_queue
          @reply_queue ||= create_queue('', exclusive: true)
        end

        def ack(tag)
          raise "Not implemented"
        end

        def fanout(name)
          raise "Not implemented"
        end

        def active?
          true
        end

        # Sends a raw RabbitMQ message to a given direct exchange
        #
        # @param queue_name [String] Queue name to send the message to
        # @param raw_message [String]
        # @param params [Hash] Message params (metadata)
        #
        def post(queue_name, raw_message, params = {})
          true
        end

        # Sends a raw RabbitMQ message to a given direct exchange and listens for response
        #
        # @param queue_name [String] Queue name to send the message to
        # @param raw_message [String]
        # @param params [Hash] Message params (metadata)
        #
        # @param params[:timeout] [Integer] (optional) Timeout in seconds
        #
        # @return [nil,Array]
        #
        def get(queue_name, raw_message, params = {})
          nil
        end

        # Sends a raw RabbitMQ message to a given fanout exchange
        #
        # @param fanout_name [String] Fanout exchange name to send the message to
        # @param raw_message [String]
        # @param params [Hash] Message params (metadata)
        #
        def broadcast(fanout_name, raw_message, params = {})
          true
        end

        private

        def publish(exchange, raw_message, params = {})
          true
        end
      end # class Channel
    end # class Connection
  end # module Messaging
end # module Mimi
