# frozen_string_literal: true

#
# Using Mimi::Messaging lower-level abstraction,
# without using the adapter directly
#

require "mimi/messaging"
require "logger"
require_relative "basic_request_processor"
require_relative "basic_event_listener"

#
# An example request processor class
#
class HelloProcessor < BasicRequestProcessor
  queue "hello"

  def world
    puts "hello/world request received: #{message}"
    { a: 1 }
  end

  def command
    puts "hello/command request received: #{message}"
  end
end # class HelloProcessor

#
# An example event listener class
#
class HelloListener < BasicEventListener
  topic "hello", using_queue: "listener.hello"

  def world
    puts "hello/world event received: #{message}"
  end
end # class HelloListener

#
Mimi::Messaging.use(
  serializer: Mimi::Messaging::JsonSerializer,
  logger: Logger.new(STDOUT)
)
Mimi::Messaging.configure(mq_adapter: :memory)
Mimi::Messaging.start

result = Mimi::Messaging.command("hello/world", a: 123)
puts "Response: #{result}"
puts

result = Mimi::Messaging.query("hello/world", b: 456)
puts "Response: #{result}"
puts

Mimi::Messaging.event("hello#world", c: 789)
puts

Mimi::Messaging.stop
