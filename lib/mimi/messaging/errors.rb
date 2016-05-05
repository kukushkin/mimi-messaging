module Mimi
  module Messaging
    class ConnectionError < StandardError
    end # class ConnectionError

    class RequestError < StandardError
      attr_accessor :params

      def initialize(message = 'failed to process request', params = {})
        @message = message
        @params = params.dup
      end

      def to_s
        @message
      end
    end # class RequestError
  end # module Messaging
end # module Mimi
