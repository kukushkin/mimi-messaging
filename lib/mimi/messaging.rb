require 'mimi/core'
require 'mimi/logger'

module Mimi
  module Messaging
    include Mimi::Core::Module
    include Mimi::Logger::Instance

    # key in the message headers that is used to pass context id
    CONTEXT_ID_KEY = 'c'.freeze

    default_options(
      require_files: 'app/messaging/**/*.rb',
      mq_host: 'localhost',
      mq_port: 5672,
      mq_username: nil,
      mq_password: nil,
      mq_vhost: nil
    )

    def self.module_path
      Pathname.new(__dir__).join('..').join('..').expand_path
    end

    def self.module_manifest
      {
        mq_host: {
          desc: 'RabbitMQ host',
          default: 'localhost'
        },
        mq_port: {
          desc: 'RabbitMQ port',
          default: 5672
        },
        mq_username: {
          desc: 'RabbitMQ username',
          default: nil
        },
        mq_password: {
          desc: 'RabbitMQ password',
          default: nil
        }
      }
    end

    def self.configure(*)
      super
      connections << Mimi::Messaging::Connection.new(module_options)
    end

    # @return [Array<Mimi::Messaging::Connection>]
    #
    def self.connections
      @connections ||= []
    end

    # @return [Array<Class < Mimi::Messaging::RequestProcessor>]
    #
    def self.request_processor_classes
      @request_processor_classes ||= []
    end

    # @param [Class < Mimi::Messaging::RequestProcessor]
    #
    def self.register_request_processor_class(request_processor_class)
      request_processor_classes << request_processor_class
    end

    # Selects the connection to be used for sending/receiving messages from/to given queue
    #
    # @param queue_name [String]
    # @return [Mimi::Messaging::Connection]
    #
    def self.connection_for(queue_name)
      connection_for_queue = connections.select do |c|
        c.queue_prefix && (
          (c.queue_prefix.is_a?(String) && queue_name.start_with?(c.queue_prefix)) ||
          (c.queue_prefix.is_a?(Array) && c.queue_prefix.any? { |qp| queue_name.start_with?(qp) })
        )
      end.first
      return connection_for_queue if connection_for_queue
      connections.select { |c| c.queue_prefix.nil? }.first
    end

    def self.post(queue_name, raw_message, params = {})
      connection_for(queue_name).post(queue_name, raw_message, params)
    end

    def self.get(queue_name, raw_message, params = {})
      connection_for(queue_name).get(queue_name, raw_message, params)
    end

    def self.broadcast(queue_name, raw_message, params = {})
      connection_for(queue_name).broadcast(queue_name, raw_message, params)
    end

    def self.start
      Mimi.require_files(module_options[:require_files]) if module_options[:require_files]
      connections.each(&:start)
      request_processor_classes.each(&:start)
      super
    end

    def self.stop
      request_processor_classes.each(&:stop)
      connections.each(&:stop)
      super
    end
  end # module Messaging
end # module Mimi

require_relative 'messaging/version'
require_relative 'messaging/errors'
require_relative 'messaging/connection'
require_relative 'messaging/message'
require_relative 'messaging/request'
require_relative 'messaging/request_processor'
require_relative 'messaging/provider'
require_relative 'messaging/model'
require_relative 'messaging/model_provider'
require_relative 'messaging/notification'
require_relative 'messaging/listener'
require_relative 'messaging/msgpack/type_packer'
require_relative 'messaging/msgpack/msgpack_ext'
