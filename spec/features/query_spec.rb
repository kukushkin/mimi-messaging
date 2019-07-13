# frozen_string_literal: true

require "spec_helper"

describe "Mimi::Messaging.query()" do
  include_context "configured test adapter"

  let(:target) { "test/method" }
  let(:message) do
    { a: 1 }
  end
  let(:opts) do
    { b: 2 }
  end
  let(:response) do
    { c: 3 }
  end
  let(:mimi_start) { Mimi::Messaging.start }

  before { mimi_start }

  subject { Mimi::Messaging.query(target, message, opts) }

  it "runs without errors" do
    expect { subject }.to_not raise_error
  end

  it "passes #query() arguments to adapter" do
    expect(adapter).to receive(:query).with(target, message, opts)
    expect { subject }.to_not raise_error
  end

  it "returns the response from adapter" do
    expect(adapter).to receive(:query).with(target, message, opts).and_return(response)
    expect(subject).to eq response
  end

  context "when adapter is not started" do
    let(:mimi_start) { nil }

    it "raises an error" do
      expect { subject }.to raise_error(Mimi::Messaging::Error)
    end
  end # when adapter is not started

  context "when target is invalid" do
    let(:target) { "foobar" }

    it "raises an error" do
      expect { subject }.to raise_error(ArgumentError)
    end
  end # when target is invalid

  context "when message is invalid" do
    let(:message) { nil }

    it "raises an error" do
      expect { subject }.to raise_error(ArgumentError)
    end
  end # when message is invalid

  context "when opts is omitted" do
    subject { Mimi::Messaging.query(target, message) }

    it "runs without errors" do
      expect { subject }.to_not raise_error
    end

    it "passes #query() arguments to adapter, with opts={}" do
      expect(adapter).to receive(:query).with(target, message, {})
      expect { subject }.to_not raise_error
    end
  end # when opts is omitted

  context "when opts and message are omitted" do
    subject { Mimi::Messaging.query(target) }

    it "runs without errors" do
      expect { subject }.to_not raise_error
    end

    it "passes #query() arguments to adapter, with message={}, opts={}" do
      expect(adapter).to receive(:query).with(target, {}, {})
      expect { subject }.to_not raise_error
    end
  end # when opts and message are omitted
end # Mimi::Messaging.query()
