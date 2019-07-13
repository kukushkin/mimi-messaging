# frozen_string_literal: true

#
# In this example we're going to use only the adapter for communication
# between several components.
#
require "mimi/messaging"

#
# Simplistic processor for command/query/event messages.
#
class HelloProcessor
  def initialize(name)
    @name = name
  end

  def to_s
    "<#{@name}>"
  end

  def call_command(method_name, message, _opts)
    puts "#{self}: COMMAND #{method_name} #{message.to_h}"
  end

  def call_query(method_name, message, _opts)
    puts "#{self}: QUERY #{method_name} #{message.to_h}"
    { b: "hello" }
  end

  def call_event(method_name, message, _opts)
    puts "#{self}: EVENT #{method_name} #{message.to_h}"
  end
end # class HelloProcessor

adapter = Mimi::Messaging::Adapters::Memory.new
adapter.register_message_serializer(Mimi::Messaging::JsonSerializer)
adapter.start

adapter.start_request_processor("hello", HelloProcessor.new("A"))
adapter.start_request_processor("hello", HelloProcessor.new("B"))
adapter.start_request_processor("hello", HelloProcessor.new("C"))

adapter.start_event_processor("hello", HelloProcessor.new("D"))
adapter.start_event_processor("hello", HelloProcessor.new("E"))
adapter.start_event_processor("hello", HelloProcessor.new("F"))

adapter.start_event_processor_with_queue("hello", "event_queue", HelloProcessor.new("G"))
adapter.start_event_processor_with_queue("hello", "event_queue", HelloProcessor.new("H"))
adapter.start_event_processor_with_queue("hello", "event_queue", HelloProcessor.new("I"))

result = adapter.command("hello/world", a: 123)
puts "Response: #{result}"
puts

result = adapter.query("hello/world", b: 456)
puts "Response: #{result}"
puts

adapter.event("hello/world", c: 789)
puts

adapter.stop
