# frozen_string_literal: true

require "mimi/core"
require_relative "messaging/version"
require_relative "messaging/adapter"
require_relative "messaging/memory_adapter"
require_relative "messaging/json_serializer"

module Mimi
  #
  # Mimi::Messaging implements a messaging layer for the application.
  #
  module Messaging
    #
    # Configure up the Messaging module
    #
    # Messaging layer configuration for logger, message serializer etc.
    #
    def self.use(options)
      @serializer = options[:serializer] if options.key?(:serializer)
      @logger = options[:logger] if options.key?(:logger)
    end

    #
    # Configure the Messaging adapter
    #
    # @param options [Hash]
    # @option options [Logger,Mimi::Logger] :logger
    # @option options [String,Symbol] :mq_adapter Adapter type, one of "memory", "test"
    #
    def self.configure(options)
      @options = options.dup
      adapter_name = options[:mq_adapter].to_s
      adapter_class = Mimi::Messaging::Adapter.registered_adapters[adapter_name]
      unless adapter_class
        registered_adapter_names = Mimi::Messaging::Adapter.registered_adapters.keys
        raise "Failed to find adapter with name '#{adapter_name}', " +
          " registered adapters are: #{registered_adapter_names.join(", ")}"
      end
      @adapter = adapter_class.new(@options)
    end

    # Returns the configured adapter
    #
    # @return [Mimi::Messaging::Adapter]
    #
    def self.adapter
      raise "Mimi::Messaging adapter is not configured" unless @adapter
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
    def self.start
      adapter.register_message_serializer(@serializer) if @serializer
      adapter.start
    end

    # Stops the Messaging module
    #
    def self.stop
      adapter.stop
    end

    # Returns configured logger
    #
    # @return [Logger] or compatible
    #
    def self.logger
      @logger
    end

    def self.command(target, message = {}, opts = {})
      adapter.command(target, message, opts)
    end

    def self.query(target, message = {}, opts = {})
      adapter.query(target, message, opts)
    end

    def self.broadcast(target, message = {}, opts = {})
      adapter.broadcast(target, message, opts)
    end

    def self.register_command_processor(target_base, processor, opts = {})
      adapter.register_command_processor(target_base, processor, opts)
    end

    def self.register_query_processor(target_base, processor, opts = {})
      adapter.register_query_processor(target_base, processor, opts)
    end

    def self.register_event_processor(event_topic, processor, opts = {})
      adapter.register_event_processor(event_topic, processor, opts)
    end

    def self.register_event_processor_with_queue(event_topic, queue_name, processor, opts = {})
      adapter.register_event_processor_with_queue(event_topic, queue_name, processor, opts)
    end
  end # module Messaging
end # module Mimi
