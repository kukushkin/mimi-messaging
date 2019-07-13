# frozen_string_literal: true

require "spec_helper"
require "logger"

describe "Mimi::Messaging.use()" do
  let(:logger) { Logger.new(STDOUT) }

  it "requires Hash as an argument" do
    expect { Mimi::Messaging.use }.to raise_error(ArgumentError)
    expect { Mimi::Messaging.use({}) }.to_not raise_error
  end

  context "when setting a logger" do
    subject { Mimi::Messaging.use(logger: logger) }

    it "runs without errors" do
      expect { subject }.to_not raise_error
    end

    it "sets the logger to a new value" do
      expect { subject }.to change { Mimi::Messaging.logger }.to(logger)
    end

    context "when setting logger to nil" do
      let(:logger) { nil }

      it "runs without errors" do
        expect { subject }.to_not raise_error
      end

      it "sets the logger to nil" do
        expect { subject }.to_not change { Mimi::Messaging.logger }.from(nil)
      end
    end # when setting logger to nil
  end # when setting a logger
end
