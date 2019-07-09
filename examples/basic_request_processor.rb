# frozen_string_literal: true

# Base class for a request (command and query) processor with DSL magic.
#
# Usage:
#   class HelloProcessor < BasicRequestProcessor
#     queue "hello"
#
#     def world
#      puts "hello/world called with the message: #{message}"
#     end
#   end
#
#
class BasicRequestProcessor
  attr_reader :message

  def initialize(message, _opts = {})
    @message = message
  end

  def self.call_command(method_name, message, opts)
    new(message, opts).send(method_name.to_sym)
  end

  def self.call_query(method_name, message, opts)
    result = new(message, opts).send(method_name.to_sym)
    return result if result.is_a?(Hash)

    raise "#{name}##{method_name}() is expected to return a Hash, but returned #{result.class}"
  end

  # Subclass exposes itself by declaring the queue that is used to accept requests
  #
  def self.queue(queue_name)
    Mimi::Messaging.register_request_processor(queue_name, self)
  end
end # class BasicRequestProcessor
