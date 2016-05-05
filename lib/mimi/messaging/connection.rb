require 'bunny'

module Mimi
  module Messaging
    class Connection
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
        @connection = Bunny.new(bunny_params)
      end

      # Starts the connection, opening actual connection to RabbitMQ
      #
      def start
        @connection.start
      end

      # Stops the connection
      #
      def stop
        @connection.close
        @channel_pool = {}
      end

      def started?
        @connection.status == :open
      end

      def channel
        raise ConnectionError unless started?
        @channel_pool[Thread.current.object_id] ||= create_channel
      end

      def create_channel(opts = {})
        Channel.new(@connection, opts)
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

      class Channel
        attr_reader :options, :connection

        DEFAULT_OPTIONS = {
          concurrency: 1
        }
        DEFAULT_GET_TIMEOUT = 60 # seconds

        def initialize(connection, opts = {})
          @connection = connection
          @options = DEFAULT_OPTIONS.merge(opts)
          @channel = @connection.create_channel(nil, options[:concurrency])
          @mutex = Mutex.new
        end

        def create_queue(name, opts = {})
          @channel.queue(name, opts)
        end

        def reply_queue
          @reply_queue ||= create_queue('', exclusive: true)
        end

        def ack(tag)
          @channel.ack(tag)
        end

        def fanout(name)
          @channel.fanout(name)
        end

        def active?
          @channel && @channel.active
        end

        # Sends a raw RabbitMQ message to a given direct exchange
        #
        # @param queue_name [String] Queue name to send the message to
        # @param raw_message [String]
        # @param params [Hash] Message params (metadata)
        #
        def post(queue_name, raw_message, params = {})
          x = @channel.default_exchange
          params = { routing_key: queue_name }.merge(params.dup)
          publish(x, raw_message, params)
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
          correlation_id = Time.now.utc.to_f.to_s
          params = params.dup.merge(
            reply_to: reply_queue.name,
            correlation_id: correlation_id
          )
          post(queue_name, raw_message, params)
          response = nil
          begin
            Timeout.timeout(params[:timeout] || DEFAULT_GET_TIMEOUT) do
              loop do
                d, m, p = reply_queue.pop
                next if d && m.correlation_id != correlation_id
                response = [d, m, p] if d
                break if response
                sleep 0.001 # s
              end
            end
          rescue Timeout::Error
            # respond with nil
          end
          response
        end

        # Sends a raw RabbitMQ message to a given fanout exchange
        #
        # @param fanout_name [String] Fanout exchange name to send the message to
        # @param raw_message [String]
        # @param params [Hash] Message params (metadata)
        #
        def broadcast(fanout_name, raw_message, params = {})
          x = @channel.fanout(fanout_name)
          publish(x, raw_message, params)
        end

        private

        def publish(exchange, raw_message, params = {})
          # HACK: Connection-level mutex reduces throughoutput, hopefully improves stability (ku)
          @mutex.synchronize do
            # TODO: may be make publishing an atomic operation using a separate thread? (ku)
            exchange.publish(raw_message, params)
          end
        rescue StandardError => e
          # Raising fatal error:
          unless Thread.main == Thread.current
            Thread.main.raise ConnectionError, "failed to publish message in a child thread: #{e}"
          end
          raise ConnectionError, "failed to publish message: #{e}"
        end
      end # class Channel
    end # class Connection
  end # module Messaging
end # module Mimi
