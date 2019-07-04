# frozen_string_literal: true

#
# In this example we're going to use only the adapter for communication
# between several components.
#

require "mimi/messaging"

class HelloProcessor

  def self.call(method_name, request)
    puts "#{self} received request: #{method_name}, #{request.to_h}"
  end
end # class HelloProcessor

adapter = Mimi::Messaging::MemoryAdapter.new

adapter.register_request_processor("hello", HelloProcessor)
adapter.start
adapter.command("hello/world", text: hi)

