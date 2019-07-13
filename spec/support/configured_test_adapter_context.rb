# frozen_string_literal: true

RSpec.shared_context "configured test adapter" do
  let(:serializer) { Mimi::Messaging::JsonSerializer }
  let(:mimi_use) do
    Mimi::Messaging.use serializer: serializer
  end
  let(:mq_options) do
    { mq_adapter: adapter_name, mq_blah: true }
  end
  let(:adapter_class) { Mimi::Messaging::Adapters::Test }
  let(:adapter_name) { "test" }
  let(:adapter) { adapter_class.new(mq_options) }
  let(:mimi_configure) do
    expect(adapter_class).to receive(:new).with(mq_options).and_return(adapter)
    Mimi::Messaging.configure(mq_options)
  end

  before do
    mimi_use
    mimi_configure
  end
end
