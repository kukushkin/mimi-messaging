# frozen_string_literal: true

require "mimi/core"
require_relative "messaging/adapters"
require_relative "messaging/errors"
require_relative "messaging/json_serializer"
require_relative "messaging/message"
require_relative "messaging/version"

module Mimi
  #
  # Mimi::Messaging implements a messaging layer of a microservice application.
  #
  # Usage: [TBD]
  #
  module Messaging
    # Request target validation pattern:
    # "[<name>.][...]<name>/<identifier>"
    # Where <name> consists of characters: A-Za-z0-9_-
    # and <method_name> can be any of: A-Za-z0-9_
    #
    # Example:
    # "shop.orders/list"
    #
    REQUEST_TARGET_REGEX = %r{^([\w\-]+\.)*([\w\-]+)\/(\w+)$}.freeze

    # Event target validation pattern:
    # "[<name>.][...]<name>#<identifier>"
    # Where <name> consists of characters: A-Za-z0-9_-
    # and <method_name> can be any of: A-Za-z0-9_
    #
    # Example:
    # "shop.orders#created"
    #
    EVENT_TARGET_REGEX = %r{^([\w\-]+\.)*([\w\-]+)\#(\w+)$}.freeze

    # By default Mimi::Messaging logs at given level
    DEFAULT_LOG_AT_LEVEL = :info

    #
    # Configure up the Messaging module
    #
    # Sets up Messaging layer dependencies configuration, e.g.
    # configures logger, message serializer etc.
    #
    def self.use(options)
      @serializer = options[:serializer] if options.key?(:serializer)
      @logger = options[:logger] if options.key?(:logger)
    end

    # Configure the Messaging layer
    #
    # Configures the adapter (type) and the adapter specific options.
    #
    # @param options [Hash] options passed to the adapter
    # @option options [String,Symbol] :mq_adapter Adapter type, one of "memory", "test" etc
    #
    def self.configure(options)
      raise ArgumentError, "Hash is expected as options" unless options.is_a?(Hash)
      raise ConfigurationError, ":mq_adapter is expected to be set" unless options.key?(:mq_adapter)

      @options = options.dup
      adapter_name = options[:mq_adapter].to_s
      adapter_class = Mimi::Messaging::Adapters.registered_adapters[adapter_name]
      unless adapter_class
        registered_adapter_names = Mimi::Messaging::Adapters.registered_adapters.keys
        raise(
          ConfigurationError,
          "Failed to find adapter with name '#{adapter_name}', " \
          " registered adapters are: #{registered_adapter_names.join(', ')}"
        )
      end

      @adapter = adapter_class.new(@options)
      raise ConfigurationError, "Message serializer is not registered" unless @serializer

      @adapter.register_message_serializer(@serializer)
    end

    # Returns the configured adapter
    #
    # @return [Mimi::Messaging::Adapter]
    #
    def self.adapter
      raise Error, "Mimi::Messaging adapter is not configured" unless @adapter

      @adapter
    end

    # Returns the module configured options
    #
    # @return [Hash]
    #
    def self.options
      @options
    end

    # Starts the Messaging module
    #
    # Starts the adapter if it is not started yet, and registers
    # the current message serializer with it. Starting the adapter opens connections
    # with a message broker.
    #
    # Automatically starts all currently registered message processors, unless
    # the :processors option is false.
    #
    # Example:
    #   # to only start the adapter, so that we can send messages,
    #   # but not process incoming messages:
    #   Mimi::Messaging.start(processors: false)
    #
    #   # to start everything
    #   Mimi::Messaging.start
    #
    # @param params [Hash] additional parameters
    # @option params [true,false] :adapter (default: true)
    #   start the adapter
    # @option params [true,false] :processors (default: true)
    #   automatically registers message processors
    #
    def self.start(params = {})
      adapter # ensures that adapter is configured
      log("#{name} starting with adapter '#{options[:mq_adapter]}'")
      params = { # defaults
        adapter: true,
        processors: true
      }.merge(params)

      if !started?(:adapter) && params[:adapter]
        adapter.start
        started!(:adapter)
      end

      if !started?(:processors) && params[:processors]
        start_all_message_processors
        started!(:processors)
      end

      true
    end

    # Stops the Messaging module
    #
    # Stops all currently registered message processors, unless :processors
    # option is false.
    #
    # Stops the adapter, unless :adapter option is false. Stopping the adapter
    # closes connections with a message broker.
    #
    # Example:
    #   # to start everything
    #   Mimi::Messaging.start
    #
    #   # to only stop the message processors, so that we can send messages
    #   # but not process incoming messages:
    #   Mimi::Messaging.stop(adapter: false, processors: true)
    #
    #   # to stop everything
    #   Mimi::Messaging.stop
    #
    # @param params [Hash] additional parameters
    # @option params [true,false] :processors (default: true)
    #   deregister all message processors
    # @option params [true,false] :adapter (default: true)
    #   deregister all message processors
    #
    def self.stop(params = {})
      params = { # defaults
        adapter: true,
        processors: true
      }.merge(params)

      if params[:processors]
        stop_all_processors
        started!(:processors, false)
      end

      if params[:adapter]
        adapter.stop # TODO: stopping adapter without stopping processors? TBD
        started!(:adapter, false)
      end

      log("#{name} stopped")
      true
    end

    # Sends the command to the given target
    #
    # Example:
    #   Mimi::Messaging.command("users/create", name: "John Smith")
    #
    # @param target [String] "<queue>/<method>"
    # @param message [Hash,Mimi::Messaging::Message]
    # @param opts [Hash] additional adapter-specific options
    #
    # @return nil
    #
    def self.command(target, message = {}, opts = {})
      raise ArgumentError, "Invalid target argument" unless REQUEST_TARGET_REGEX.match(target)
      raise ArgumentError, "Invalid message, Hash or Message is expected" unless message.is_a?(Hash)
      raise Error, "Failed to send command, adapter is not started" unless started?(:adapter)

      adapter.command(target, Mimi::Messaging::Message.new(message), opts)
    end

    # Executes the query to the given target and returns response
    #
    # Raises Timeout::Error if the response from the target was not received in time.
    #
    # Example:
    #   result = Mimi::Messaging.query("users/find", id: 157)
    #
    # @param target [String] "<queue>/<method>"
    # @param message [Hash,Mimi::Messaging::Message]
    # @param opts [Hash] additional options, e.g. :timeout
    #
    # @return [Hash]
    #
    def self.query(target, message = {}, opts = {})
      raise ArgumentError, "Invalid target argument" unless REQUEST_TARGET_REGEX.match(target)
      raise ArgumentError, "Invalid message, Hash or Message is expected" unless message.is_a?(Hash)
      raise Error, "Failed to send query, adapter is not started" unless started?(:adapter)

      adapter.query(target, Mimi::Messaging::Message.new(message), opts)
    end

    # Broadcasts the event with the given target
    #
    # @param target [String] "<topic>#<event_type>", e.g. "customers#created"
    # @param message [Hash,Mimi::Messaging::Message]
    # @param opts [Hash] additional options
    #
    def self.event(target, message = {}, opts = {})
      raise ArgumentError, "Invalid target argument" unless EVENT_TARGET_REGEX.match(target)
      raise ArgumentError, "Invalid message, Hash or Message is expected" unless message.is_a?(Hash)
      raise Error, "Failed to broadcast event, adapter is not started" unless started?(:adapter)

      adapter.event(target, Mimi::Messaging::Message.new(message), opts)
    end

    # Registers the request (command/query) processor.
    #
    # If the adapter and the processors are started, the processor
    # will be automatically started (registered with the adapter).
    #
    # Processor must respond to #call_command() AND #call_query()
    # which accepts 3 arguments: (method, message, opts).
    #
    # TBD: It must #ack! or #nack! the message.
    #
    # If the processor raises an error, the message will be NACK-ed and accepted again
    # at a later time.
    #
    # @param queue_name [String] "<queue>"
    # @param processor [#call_command()]
    # @param opts [Hash] additional adapter-specific options
    #
    def self.register_request_processor(queue_name, processor, opts = {})
      # validates processor
      unless (
        processor.respond_to?(:call_command) && processor.method(:call_command).arity >= 3 &&
        processor.respond_to?(:call_query) && processor.method(:call_query).arity >= 3
      )
        raise(
          ArgumentError,
          "Invalid request processor passed to .register_request_processor(), " \
          "expected to respond to #call_command(...) AND #call_query(method_name, request, opts)"
        )
      end

      message_processor_params = {
        type: :request,
        queue_name: queue_name,
        processor: processor,
        opts: opts.dup,
        started: false
      }
      if started?(:adapter) && started?(:processors)
        start_message_processor(message_processor_params)
      end
      message_processors << message_processor_params
    end

    # Registers an event processor without a queue
    #
    # If the adapter and the processors are started, the processor
    # will be automatically started (registered with the adapter).
    #
    # Processor must respond to #call_event() which accepts 3 arguments:
    # (method, message, opts).
    #
    # TBD: It must #ack! or #nack! the message.
    #
    # If the processor raises an error, the message will be NACK-ed and accepted again
    # at a later time.
    #
    # @param topic_name [String] "<topic>"
    # @param processor [#call_event()]
    # @param opts [Hash] additional adapter-specific options
    #
    def self.register_event_processor(topic_name, processor, opts = {})
      # validates processor
      if !processor.respond_to?(:call_event) || processor.method(:call_event).arity < 3
        raise(
          ArgumentError,
          "Invalid event processor passed to .register_event_processor(), " \
          "expected to respond to #call_event(method_name, request, opts)"
        )
      end

      message_processor_params = {
        type: :event,
        topic_name: topic_name,
        processor: processor,
        opts: opts.dup,
        started: false
      }
      if started?(:adapter) && started?(:processors)
        start_message_processor(message_processor_params)
      end
      message_processors << message_processor_params
    end

    # Registers an event processor with a queue
    #
    # If the adapter and the processors are started, the processor
    # will be automatically started (registered with the adapter).
    #
    # Processor must respond to #call_event() which accepts 3 arguments:
    # (method, message, opts).
    #
    # TBD: It must #ack! or #nack! the message.
    #
    # If the processor raises an error, the message will be NACK-ed and accepted again
    # at a later time.
    #
    # @param topic_name [String] "<topic>"
    # @param queue_name [String] "<queue>"
    # @param processor [#call_event()]
    # @param opts [Hash] additional adapter-specific options
    #
    def self.register_event_processor_with_queue(topic_name, queue_name, processor, opts = {})
      # validates processor
      if !processor.respond_to?(:call_event) || processor.method(:call_event).arity < 3
        raise(
          ArgumentError,
          "Invalid event processor passed to .register_event_processor_with_queue(), " \
          "expected to respond to #call_event(method_name, request, opts)"
        )
      end

      message_processor_params = {
        type: :event,
        topic_name: topic_name,
        queue_name: queue_name,
        processor: processor,
        opts: opts.dup,
        started: false
      }
      if started?(:adapter) && started?(:processors)
        start_message_processor(message_processor_params)
      end
      message_processors << message_processor_params
    end

    # private-ish methods below
    # Not a part of the end-user API, but still accessible by other components

    # Returns configured logger
    #
    # @return [Logger] or compatible
    #
    def self.logger
      @logger
    end

    # Logs with configured logger at configured logging level
    #
    # @param message [String]
    #
    def self.log(message)
      return unless logger

      log_at_level = options[:mq_log_at_level] || DEFAULT_LOG_AT_LEVEL
      log_at_level = log_at_level.to_sym
      return if log_at_level == :none

      logger.send(log_at_level, message)
    end

    # Returns true if the given subsystem started
    #
    # Example:
    #   started?(:adapter)
    #
    # @param name [Symbol]
    # @return [true,false]
    #
    def self.started?(name)
      @started ||= {}
      @started[name]
    end
    private_class_method :started?

    # Sets the state of the given subsystem
    #
    # Example:
    #   started!(:adapter, false)
    #
    # @param name [Symbol]
    # @param value [true,false] (default: true)
    #
    def self.started!(name, value = true)
      @started ||= {}
      @started[name] = !!value
    end
    private_class_method :started!

    # Returns the set of registered message processors
    #
    # @return [Array{Hash}]
    #
    def self.message_processors
      @message_processors ||= []
    end
    private_class_method :message_processors

    # Starts the message processor at the configured and started adapter
    #
    # @param message_processor_params [Hash]
    #
    def self.start_message_processor(message_processor_params)
      return if message_processor_params[:started] # do not start processor twice

      p = message_processor_params
      case p[:type]
      when :request
        log "#{self} starting request processor #{p[:processor]}@#{p[:queue_name]}"
        adapter.start_request_processor(p[:queue_name], p[:processor], p[:opts])
      when :event
        log "#{self} starting event processor #{p[:processor]}@#{p[:topic_name]}"
        adapter.start_event_processor(p[:topic_name], p[:processor], p[:opts])
      when :event_with_queue
        log "#{self} starting event processor #{p[:processor]}@#{p[:topic_name]}/#{p[:queue_name]}"
        adapter.start_event_processor_with_queue(
          p[:topic_name], p[:queue_name], p[:processor], p[:opts]
        )
      else
        raise "Unexpected message processor type: #{message_processor[:type].inspect}"
      end
      message_processor_params[:started] = true
    end
    private_class_method :start_message_processor

    # Starts all registered message processors at the adapter
    #
    def self.start_all_message_processors
      message_processors.each { |p| start_message_processor(p) }
    end
    private_class_method :start_all_message_processors

    # Stops all registered message processors at the adapter
    #
    def self.stop_all_processors
      log "#{self} stopping all message processors"
      adapter.stop_all_processors
      message_processors.each { |p| p[:started] = false }
    end
    private_class_method :stop_all_processors

    # Deregisters all message processors
    #
    def self.unregister_all_processors
      stop_all_processors
      message_processors.replace([])
    end
  end # module Messaging
end # module Mimi
