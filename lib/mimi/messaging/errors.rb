# frozen_string_literal: true

module Mimi
  module Messaging
    #
    # Error definitions
    #

    # Generic error in the Messaging layer
    #
    # Base class for other more specific errors raised by Messaging layer
    #
    class Error < StandardError; end

    # Configuration related errors
    #
    class ConfigurationError < Error; end

    # Connection level error
    #
    # Raised on errors related to network level, e.g. message broker host not reachable
    # or authentication/authorization at message broker failed.
    #
    class ConnectionError < Error; end

    # An error raised to indicate that the message should be NACK-ed, but
    # no additional error logging or processing should happen.
    #
    class NACK < Error; end
  end # module Messaging
end # module Mimi
