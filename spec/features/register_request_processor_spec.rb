# frozen_string_literal: true

require "spec_helper"

describe "Mimi::Messaging.register_request_processor()" do
  include_context "configured test adapter"

  let(:queue_name) { "test" }
  let(:valid_request_processor) do
    Class.new do
      def self.call_command(_method_name, _message, _opts)
      end

      def self.call_query(_method_name, _message, _opts)
      end
    end
  end
  let(:request_processor_no_command) do
    Class.new do
      def self.call_query(_method_name, _message, _opts)
      end
    end
  end
  let(:request_processor_no_query) do
    Class.new do
      def self.call_command(_method_name, _message, _opts)
      end
    end
  end
  let(:request_processor_invalid_args) do
    Class.new do
      def self.call_command(_method_name, _message)
      end

      def self.call_query(_method_name, _message)
      end
    end
  end
  let(:request_processor) { valid_request_processor }
  let(:opts) do
    { a: 1 }
  end
  let(:register_request_processor) do
    Mimi::Messaging.register_request_processor(queue_name, request_processor, opts)
  end

  subject { register_request_processor }

  it "runs without errors" do
    expect { subject }.to_not raise_error
  end

  context "when register_request_processor() is run before adapter is started" do
    subject do
      register_request_processor
      Mimi::Messaging.start
    end

    it "runs without errors" do
      expect { subject }.to_not raise_error
    end

    it "starts request processor with the adapter" do
      expect(adapter).to receive(:start_request_processor).with(queue_name, request_processor, opts)
      expect { subject }.to_not raise_error
    end
  end # when register_request_processor() is run before adapter is started

  context "when register_request_processor() is run after adapter is started" do
    subject do
      Mimi::Messaging.start
      register_request_processor
    end

    it "runs without errors" do
      expect { subject }.to_not raise_error
    end

    it "starts request processor with the adapter" do
      expect(adapter).to receive(:start_request_processor).with(queue_name, request_processor, opts)
      expect { subject }.to_not raise_error
    end
  end # when register_request_processor() is run after adapter is started

  context "when request processor has no #call_command()" do
    let(:request_processor) { request_processor_no_command }

    it "raises an error" do
      expect { subject }.to raise_error(ArgumentError)
    end
  end # when request processor has no #call_command()

  context "when request processor has no #call_query()" do
    let(:request_processor) { request_processor_no_query }

    it "raises an error" do
      expect { subject }.to raise_error(ArgumentError)
    end
  end # when request processor has no #call_query()

  context "when request processor #call_() method has invalid arguments" do
    let(:request_processor) { request_processor_invalid_args }

    it "raises an error" do
      expect { subject }.to raise_error(ArgumentError)
    end
  end # when request processor #call_() method has invalid arguments
end # Mimi::Messaging.register_request_processor()
