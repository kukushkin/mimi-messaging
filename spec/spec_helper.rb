# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "mimi/messaging"
require_relative "support/configured_test_adapter_context"

RSpec.configure do |config|
  config.after(:each) do
    # Reset Mimi::Messaging internal state
    Mimi::Messaging.instance_variables.each do |var_name|
      Mimi::Messaging.instance_variable_set(var_name, nil)
    end
  end
end
