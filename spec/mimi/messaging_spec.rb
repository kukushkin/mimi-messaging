# frozen_string_literal: true

require "spec_helper"

describe Mimi::Messaging do
  it "has a version number" do
    expect(Mimi::Messaging::VERSION).not_to be nil
  end

  it { is_expected.to respond_to(:use) }
  it { is_expected.to respond_to(:configure) }
  it { is_expected.to respond_to(:start) }
  it { is_expected.to respond_to(:stop) }
  it { is_expected.to respond_to(:command) }
  it { is_expected.to respond_to(:query) }
  it { is_expected.to respond_to(:event) }
  it { is_expected.to respond_to(:register_request_processor) }
  it { is_expected.to respond_to(:register_event_processor) }
end
