# frozen_string_literal: true

# Base class for an event listener with DSL magic
#
# Usage:
#   class HelloListener < BasicEventListener
#     topic "hello", using_queue: "listener.hello"
#
#     def world
#      puts "hello/world event received: #{message}"
#     end
#   end
#
class BasicEventListener
  attr_reader :message

  def initialize(message, _opts = {})
    @message = message
  end

  def self.call_event(method_name, message, opts)
    new(message, opts).send(method_name.to_sym)
  end

  # Subclass exposes itself by declaring the event topic that it is going to listen for,
  # and an optional :using_queue parameter.
  #
  def self.topic(event_topic, params = {})
    if params[:using_queue]
      Mimi::Messaging.register_event_processor_with_queue(event_topic, params[:using_queue], self)
    else
      Mimi::Messaging.register_event_processor(event_topic, params[:using_queue], self)
    end
  end
end # class BasicEventListener
