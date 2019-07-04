# frozen_string_literal: true

require "mimi/core"
require_relative "messaging/version"
require_relative "messaging/adapter"
require_relative "messaging/memory_adapter"
require_relative "messaging/json_serializer"

module Mimi
  module Messaging
    #
    # Configure the Messaging module
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
      adapter.start
    end

    # Stops the Messaging module
    #
    def self.stop
      adapter.stop
    end
  end # module Messaging
end # module Mimi
