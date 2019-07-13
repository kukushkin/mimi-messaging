# frozen_string_literal: true

require "spec_helper"

describe "Mimi::Messaging.stop()" do
  include_context "configured test adapter"

  subject { Mimi::Messaging.stop }

  it "runs without errors" do
    expect { subject }.to_not raise_error
  end

  context "when adapter is not configured" do
    let(:mimi_configure) { nil }

    it "fails to stop" do
      expect { subject }.to raise_error(Mimi::Messaging::Error)
    end
  end # when adapter is not configured
end # Mimi::Messaging.stop()
