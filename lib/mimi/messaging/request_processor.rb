require_relative 'request_processor/dsl'
require_relative 'request_processor/context'

module Mimi
  module Messaging
    class RequestProcessor
      extend DSL
      include Context

      abstract!
      queue_options exclusive: false, auto_delete: true

      RequestError = Mimi::Messaging::RequestError

      def self.inherited(request_processor_class)
        request_processor_class.parent = self
        Mimi::Messaging.register_request_processor_class(request_processor_class)
      end

      def self.resource_name
        queue_name
      end

      def self.request_type(_d, metadata, _p)
        metadata.reply_to ? :get : :post
      end

      def self.started?
        !@consumer.nil?
      end

      def self.connection
        @connection ||= Mimi::Messaging.connection_for(resource_name)
      end

      def self.channel
        @channel ||= connection.create_channel(options)
      end

      def self.construct_queue
        channel.create_queue(queue_name, queue_options)
      end

      def self.start
        return if abstract?
        raise "#{name} already started" if started?
        logger.debug "#{self} starting to serve '#{resource_name}' (#{exposed_methods})"
        @queue = construct_queue
        @consumer_mutex = Mutex.new
        @consumer_mutex.synchronize do
          @consumer = @queue.subscribe(manual_ack: true) do |d, m, p|
            begin
              new(d, m, p)
            rescue StandardError => e
              logger.error e.to_s
              logger.debug e.backtrace.join("\n")
            ensure
              @consumer_mutex.synchronize do
                @consumer.channel.ack(d.delivery_tag) if @consumer.channel && @consumer.channel.active
              end
            end
          end
        end
        # consumer created, mutex released
      end

      def self.stop
        return if abstract?
        raise "#{name} already stopped" unless started?
        @consumer_mutex.synchronize do
          @consumer.cancel if @consumer
        end
        @consumer = nil
        @queue = nil
        @channel = nil
        @connection = nil
      end

      def initialize(d, m, p)
        initialize_logging_context!(m.headers)
        @request = Mimi::Messaging::Request.new(self.class, d, m, p)
        @result = nil
        method_name = request.method_name
        begin
          catch(:halt) do
            @result = __execute_method(method_name)
          end
        rescue StandardError => e
          __execute_error_handlers(e)
        end
      end

      # Initializes logging context.
      #
      # Starts a new logging contenxt or inherits a context id from the message headers.
      #
      # @param headers [Hash,nil] message headers
      #
      def initialize_initialize_logging_context!(headers)
        context_id = (headers || {})[Mimi::Messaging::CONTEXT_ID_KEY]
        if context_id
          logger.context_id = context_id
        else
          logger.new_context_id!
        end
      end

      # Request logger
      #
      # Usage:
      #   options log_requests: true
      # Or:
      #   options log_requests: { log_level: :info }
      #
      before do
        opts = self.class.options[:log_requests]
        next unless opts
        message = "#{request.canonical_name}: #{params}"
        level = opts.is_a?(Hash) ? (opts[:log_level] || 'debug') : 'debug'
        logger.send level.to_sym, message
      end

      # Request benchmark logger
      #
      # Usage:
      #   options log_benchmarks: true
      # Or:
      #   options log_benchmarks: { log_level: :info }
      #
      around do |b|
        opts = self.class.options[:log_benchmarks]
        t_start = Time.now
        b.call
        next unless opts
        message = "#{request.canonical_name}: completed in %.1fms" % [(Time.now - t_start) * 1000.0]
        level = opts.is_a?(Hash) ? (opts[:log_level] || 'debug') : 'debug'
        logger.send level.to_sym, message
      end

      # Default error handler for StandardError and its descendants
      #
      error StandardError do |e|
        logger.error "#{request.canonical_name}: #{e} (#{e.class})"
        logger.debug((e.backtrace || ['<no backtrace>']).join("\n"))
        halt
      end

      private

      attr_reader :request

      def __execute_method(method_name)
        unless method_name && method_name.is_a?(String)
          raise 'RequestProcessor method name is not specified in the request'
        end
        method_name = method_name.to_sym
        unless self.class.exposed_methods.include?(method_name)
          raise "RequestProcessor method (\##{method_name}) is not exposed"
        end

        method = self.class.instance_method(method_name.to_sym)
        accepted_params = request.params_symbolized.only(*method.parameters.map(&:last))
        result = nil
        method_block = proc do
          args = [method_name]
          args << accepted_params unless accepted_params.empty?
          catch(:halt) do
            result = send(*args)
          end
        end
        self.class.filters(:before).each { |f| __execute(&f[:block]) }
        wrapped_block = self.class.filters(:around).reduce(method_block) do |a, e|
          __bind(a, &e[:block])
        end
        wrapped_block.call
        self.class.filters(:after, false).each { |f| __execute(&f[:block]) }
        result
      end

      def __execute_error_handlers(error)
        catch(:halt) do
          result = self.class.filters(:error, false).reduce(error) do |a, e|
            if e[:args].any? { |error_klass| a.is_a?(error_klass) }
              __execute(a, &e[:block])
            else
              a
            end
          end
          logger.error "Error '#{error}' (#{error.class}) unprocessed by error handlers " \
            "(result=#{result.class})"
        end
      rescue StandardError => e
        logger.error "Error raised by error handler '#{request.canonical_name}': #{e}"
        logger.debug e.backtrace.join("\n")
      end

      def reply(_data = {})
        logger.warn "#{self.class}#reply not implemented"
        halt
      end

      def halt
        throw :halt
      end

      def params
        request.params
      end

      def logger
        Mimi::Messaging.logger
      end

      def self.logger
        Mimi::Messaging.logger
      end
    end # class RequestProcessor
  end # module Messaging
end # module Mimi
