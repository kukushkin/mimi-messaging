# frozen_string_literal: true

module Mimi
  module Messaging
    #
    # Common namespace for all Mimi Messaging adapters
    #
    module Adapters
      # Returns a Hash containing all registered adapters
      #
      # @return [Hash{String => Class < Mimi::Messaging::Adapters::Base}]
      #
      def self.registered_adapters
        @registered_adapters ||= {}
      end
    end # module Adapters
  end # module Messaging
end # module Mimi

require_relative "adapters/base"
require_relative "adapters/memory"
require_relative "adapters/test"
