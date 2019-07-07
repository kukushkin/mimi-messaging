# frozen_string_literal: true

#
# Using Mimi::Messaging lower-level abstraction,
# without using the adapter directly
#

require "mimi/messaging"
require "logger"

# Base class for a request (command and query) processor with DSL magic
#
class RequestProcessor
  attr_reader :message

  def initialize(message, _opts = {})
    @message = message
  end

  def self.call_command(method_name, message, _opts)
    puts "#{self}: COMMAND #{method_name} #{message.to_h}"
    new(message, _opts).send(method_name.to_sym)
  end

  def self.call_query(method_name, message, _opts)
    puts "#{self}: QUERY #{method_name} #{message.to_h}"
    new(message, _opts).send(method_name.to_sym)
  end

  # Subclass exposes itself by declaring the queue that is used to accept requests
  #
  def self.queue(queue_name)
    Mimi::Messaging.register_command_processor(queue_name, self)
    Mimi::Messaging.register_query_processor(queue_name, self)
  end
end # class RequestProcessor

# Base class for an event listener with DSL magic
#
class EventListener
  attr_reader :message

  def initialize(message, _opts = {})
    @message = message
  end

  def self.call_event(method_name, message, _opts)
    puts "#{self}: EVENT #{method_name} #{message.to_h}"
    new(message, _opts).send(method_name.to_sym)
  end

  # Subclass exposes itself by declaring the event topic that it is going to listen for,
  # and an optional :using_queue parameter.
  #
  def self.listen(event_topic, params = {})
    if params[:using_queue]
      Mimi::Messaging.register_event_processor_with_queue(
        event_topic, params[:using_queue], self
      )
    else
      Mimi::Messaging.register_event_processor(event_topic, params[:using_queue], self)
    end
  end
end # class EventListener

#
# An example request processor class
#
class HelloProcessor < RequestProcessor
  queue "hello"

  def world
    puts "#{self}: HELLO, WORLD"
    { a: 1 }
  end
end # class HelloProcessor

#
# An example event listener class
#
class HelloListener < EventListener
  listen "hello", using_queue: "listener.hello"

  def world
    puts "#{self}: HELLO, WORLD. EVENT"
  end
end # class HelloListener

#
Mimi::Messaging.use(
  serializer: Mimi::Messaging::JsonSerializer,
  logger: Logger.new(STDOUT)
)
Mimi::Messaging.configure(mq_adapter: :memory)
Mimi::Messaging.start

Mimi::Messaging.command("hello/world", a: 123)
puts

result = Mimi::Messaging.query("hello/world", b: 456)
puts "Response: #{result}"
puts

Mimi::Messaging.broadcast("hello/world", c: 789)
