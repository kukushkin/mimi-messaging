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

adapter = Mimi::Messaging::MemoryAdapter.new
adapter.register_message_serializer(Mimi::Messaging::JsonSerializer)

adapter.register_command_processor("hello", HelloProcessor.new("A"))
adapter.register_command_processor("hello", HelloProcessor.new("B"))
adapter.register_command_processor("hello", HelloProcessor.new("C"))

adapter.register_query_processor("hello", HelloProcessor.new("D"))
adapter.register_query_processor("hello", HelloProcessor.new("E"))
adapter.register_query_processor("hello", HelloProcessor.new("F"))

adapter.register_event_processor("hello", HelloProcessor.new("D"))
adapter.register_event_processor("hello", HelloProcessor.new("E"))
adapter.register_event_processor("hello", HelloProcessor.new("F"))

adapter.register_event_processor_with_queue("hello", "event_queue", HelloProcessor.new("G"))
adapter.register_event_processor_with_queue("hello", "event_queue", HelloProcessor.new("H"))
adapter.register_event_processor_with_queue("hello", "event_queue", HelloProcessor.new("I"))

adapter.command("hello/world", a: 123)
puts

result = adapter.query("hello/world", b: 456)
puts "Response: #{result}"
puts

adapter.broadcast("hello/world", c: 789)
puts

