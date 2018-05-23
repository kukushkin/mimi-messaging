#
# Replaces real Connection and Channel with MockConnection and MockChannel
# that stubs connections to RabbitMQ.
#
# Replaces RequestProcessor with MockRequestProcessor
#

require_relative 'mock/connection'
require_relative 'mock/request_processor'
require_relative 'mock/request'

Mimi::Messaging.send :remove_const, :Connection
Mimi::Messaging::Connection = Mimi::Messaging::MockConnection
