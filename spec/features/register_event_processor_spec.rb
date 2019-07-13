# frozen_string_literal: true

require "spec_helper"

describe "Mimi::Messaging.register_event_processor()" do
  include_context "configured test adapter"

  let(:topic_name) { "test" }
  let(:valid_event_processor) do
    Class.new do
      def self.call_event(_method_name, _message, _opts)
      end
    end
  end
  let(:event_processor_no_event) do
    Class.new do
    end
  end
  let(:event_processor_invalid_args) do
    Class.new do
      def self.call_event(_method_name, _message)
      end
    end
  end
  let(:event_processor) { valid_event_processor }
  let(:opts) do
    { a: 1 }
  end
  let(:register_event_processor) do
    Mimi::Messaging.register_event_processor(topic_name, event_processor, opts)
  end

  subject { register_event_processor }

  it "runs without errors" do
    expect { subject }.to_not raise_error
  end

  context "when register_event_processor() is run before adapter is started" do
    subject do
      register_event_processor
      Mimi::Messaging.start
    end

    it "runs without errors" do
      expect { subject }.to_not raise_error
    end

    it "starts event processor with the adapter" do
      expect(adapter).to receive(:start_event_processor).with(topic_name, event_processor, opts)
      expect { subject }.to_not raise_error
    end
  end # when register_event_processor() is run before adapter is started

  context "when register_event_processor() is run after adapter is started" do
    subject do
      Mimi::Messaging.start
      register_event_processor
    end

    it "runs without errors" do
      expect { subject }.to_not raise_error
    end

    it "starts event processor with the adapter" do
      expect(adapter).to receive(:start_event_processor).with(topic_name, event_processor, opts)
      expect { subject }.to_not raise_error
    end
  end # when register_event_processor() is run after adapter is started

  context "when event processor has no #call_event()" do
    let(:event_processor) { event_processor_no_event }

    it "raises an error" do
      expect { subject }.to raise_error(ArgumentError)
    end
  end # when event processor has no #call_event()

  context "when event processor #call_() method has invalid arguments" do
    let(:event_processor) { event_processor_invalid_args }

    it "raises an error" do
      expect { subject }.to raise_error(ArgumentError)
    end
  end # when event processor #call_() method has invalid arguments
end # Mimi::Messaging.register_event_processor()
