# frozen_string_literal: true

require "spec_helper"

describe "Mimi::Messaging.configure()" do
  let(:setup) do
    Mimi::Messaging.use serializer: Mimi::Messaging::JsonSerializer
  end
  let(:options) do
    { mq_adapter: adapter_name, mq_blah: true }
  end
  let(:adapter_class) { Mimi::Messaging::Adapters::Test }
  let(:adapter_name) { "test" }
  let(:adapter) { adapter_class.new(options) }

  before { setup }

  subject { Mimi::Messaging.configure(options) }

  it "requires Hash as an argument" do
    expect { Mimi::Messaging.configure(nil) }.to raise_error(ArgumentError)
  end

  it "requires at least :mq_adapter" do
    expect { Mimi::Messaging.configure({}) }.to raise_error(ArgumentError)
    expect { Mimi::Messaging.configure(mq_adapter: adapter_name) }.to_not raise_error
  end

  it "creates an adapter instance and passes configuration options to it" do
    expect(adapter_class).to receive(:new).with(options).and_return(adapter)
    expect { subject }.to_not raise_error
    expect { Mimi::Messaging.adapter }.to_not raise_error
    expect(Mimi::Messaging.adapter).to eq adapter
  end

  context "when adapter name is not valid" do
    let(:adapter_name) { "foobar" }

    it "fails to configure" do
      expect { subject }.to raise_error(ArgumentError)
    end
  end # when adapter name is not valid

  context "when serializer is not set" do
    let(:setup) { nil }

    it "fails to configure" do
      expect { subject }.to raise_error(Mimi::Messaging::Error)
    end
  end # when serializer is not set
end # Mimi::Messaging.configure()
