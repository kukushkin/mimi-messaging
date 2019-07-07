# frozen_string_literal: true

require "mimi/core"
require_relative "messaging/adapter"
require_relative "messaging/errors"
require_relative "messaging/json_serializer"
require_relative "messaging/memory_adapter"
require_relative "messaging/version"

module Mimi
  #
  # Mimi::Messaging implements a messaging layer of a microservice application.
  #
  # Usage: [TBD]
  #
  module Messaging
    # Target validation pattern.
    # "[<name>.][...]<name>/<name>"
    # Where <name> consists of valid identifier characters: A-Za-z0-9_
    #
    TARGET_REGEX = %r{^((\w+)\.)*(\w+)\/(\w+)$}.freeze

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
      @options = options.dup
      adapter_name = options[:mq_adapter].to_s
      adapter_class = Mimi::Messaging::Adapter.registered_adapters[adapter_name]
      unless adapter_class
        registered_adapter_names = Mimi::Messaging::Adapter.registered_adapters.keys
        raise(
          Error,
          "Failed to find adapter with name '#{adapter_name}', " \
          " registered adapters are: #{registered_adapter_names.join(', ')}"
        )
      end

      @adapter = adapter_class.new(@options)
      raise ArgumentError, "Message serializer is not registered" unless @serializer

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
    def self.stop
      params = { # defaults
        adapter: true,
        processors: true
      }.merge(params)

      if params[:processors]
        stop_all_message_processors
        started!(:processors, false)
      end

      if params[:adapter]
        adapter.stop # TODO: stopping adapter without stopping processors? TBD
        started!(:adapter, false)
      end

      true
    end

    # Sends the command to the given target
    #
    # Example:
    #   Mimi::Messaging.command("users/create", name: "John Smith")
    #
    # @param target [String] "<queue>/<method>"
    # @param message [Hash]
    # @param opts [Hash] additional adapter-specific options
    #
    # @return nil
    #
    def self.command(target, message = {}, opts = {})
      raise ArgumentError, "Invalid target argument" unless TARGET_REGEX.match(target)
      raise ArgumentError, "Invalid message, Hash is expected" unless message.is_a?(Hash)
      raise Error, "Failed to send command, adapter is not started" unless started?(:adapter)

      adapter.command(target, message, opts)
    end

    # Executes the query to the given target and returns response
    #
    # Raises Timeout::Error if the response from the target was not received in time.
    #
    # @param target [String] "<queue>/<method>"
    # @param message [Hash]
    # @param opts [Hash] additional options, e.g. :timeout
    #
    # @return [Hash]
    #
    def self.query(target, message = {}, opts = {})
      raise ArgumentError, "Invalid target argument" unless TARGET_REGEX.match(target)
      raise ArgumentError, "Invalid message, Hash is expected" unless message.is_a?(Hash)
      raise Error, "Failed to send query, adapter is not started" unless started?(:adapter)

      adapter.query(target, message, opts)
    end

    # Broadcasts the event with the given target
    #
    # @param target [String] "<topic>/<event_type>", e.g. "customers/created"
    # @param message [Hash]
    # @param opts [Hash] additional options
    #
    def self.broadcast(target, message = {}, opts = {})
      raise ArgumentError, "Invalid target argument" unless TARGET_REGEX.match(target)
      raise ArgumentError, "Invalid message, Hash is expected" unless message.is_a?(Hash)
      raise Error, "Failed to broadcast event, adapter is not started" unless started?(:adapter)

      adapter.broadcast(target, message, opts)
    end

    # Registers the command processor.
    #
    # If the adapter and the processors are started, the processor
    # will be automatically started (registered with the adapter).
    #
    # Processor must respond to #call_command() which accepts 3 arguments:
    # (method, message, opts).
    #
    # TBD: It must #ack! or #nack! the message.
    #
    # If the processor raises an error, the message will be NACK-ed and accepted again
    # at a later time.
    #
    # @param target_base [String] "<queue>"
    # @param processor [#call_command()]
    # @param opts [Hash] additional adapter-specific options
    #
    def self.register_command_processor(target_base, processor, opts = {})
      # validates processor
      if !processor.respond_to?(:call_command) || processor.method(:call_command).arity < 3
        raise(
          ArgumentError,
          "Invalid command processor passed to .register_command_processor(), " \
          "expected to respond to #call_command(method_name, request, opts)"
        )
      end

      message_processor_params = {
        type: :command,
        target_base: target_base,
        processor: processor,
        opts: opts.dup,
        registered: false
      }
      if started?(:adapter) && started?(:processors)
        start_message_processor(message_processor_params)
      end
      message_processors << message_processor_params
    end

    # Registers a query processor.
    #
    # If the adapter and the processors are started, the processor
    # will be automatically started (registered with the adapter).
    #
    # Processor must respond to #call_query() which accepts 3 arguments:
    # (method, message, opts).
    #
    # TBD: The #call_query() method should return a Hash (response message)
    # TBD: It must #ack! or #nack! the message.
    #
    # If the processor raises an error, the message will be NACK-ed and accepted again
    # at a later time.
    #
    # @param target_base [String] "<queue>"
    # @param processor [#call_query()]
    # @param opts [Hash] additional adapter-specific options
    #
    def self.register_query_processor(target_base, processor, opts = {})
      # validates processor
      if !processor.respond_to?(:call_query) || processor.method(:call_query).arity < 3
        raise(
          ArgumentError,
          "Invalid query processor passed to .register_query_processor(), " \
          "expected to respond to #call_query(method_name, request, opts)"
        )
      end

      message_processor_params = {
        type: :query,
        target_base: target_base,
        processor: processor,
        opts: opts.dup,
        registered: false
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
    # @param event_topic [String] "<topic>"
    # @param processor [#call_event()]
    # @param opts [Hash] additional adapter-specific options
    #
    def self.register_event_processor(event_topic, processor, opts = {})
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
        event_topic: event_topic,
        processor: processor,
        opts: opts.dup,
        registered: false
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
    # @param event_topic [String] "<topic>"
    # @param queue_name [String] "<queue>"
    # @param processor [#call_event()]
    # @param opts [Hash] additional adapter-specific options
    #
    def self.register_event_processor_with_queue(event_topic, queue_name, processor, opts = {})
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
        event_topic: event_topic,
        queue_name: queue_name,
        processor: processor,
        opts: opts.dup,
        registered: false
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

    # Starts (registers) the message processor
    #
    # @param message_processor_params [Hash]
    #
    def self.start_message_processor(message_processor_params)
      return if message_processor_params[:registered] # do not register processor twice

      p = message_processor_params
      case p[:type]
      when :command
        adapter.register_command_processor(p[:target_base], p[:processor], p[:opts])
      when :query
        adapter.register_query_processor(p[:target_base], p[:processor], p[:opts])
      when :event
        adapter.register_event_processor(p[:event_topic], p[:processor], p[:opts])
      when :event_with_queue
        adapter.register_event_processor_with_queue(
          p[:event_topic], p[:queue_name], p[:processor], p[:opts]
        )
      else
        raise "Unexpected message processor type: #{message_processor[:type].inspect}"
      end
      message_processor_params[:registered] = true
    end
    private_class_method :start_message_processor

    # Starts (registers) all message processors
    #
    def self.start_all_message_processors
      message_processors.each { |p| start_message_processor(p) }
    end
    private_class_method :start_all_message_processors

    # Stops (deregisters) all message processors
    #
    def self.stop_all_message_processors
      adapter.deregister_all_processors
    end
    private_class_method :stop_all_message_processors
  end # module Messaging
end # module Mimi
