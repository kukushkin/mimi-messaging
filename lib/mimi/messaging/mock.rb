#
# Replaces real Connection and Channel with MockConnection and MockChannel
# that stubs connections to RabbitMQ.
#
# Replaces RequestProcessor with MockRequestProcessor
#

require_relative 'mock/connection'
require_relative 'mock/request_processor'

Mimi::Messaging.remove_const(:Connection)
Mimi::Messaging::Connection = Mimi::Messaging::MockConnection
Mimi::Messaging.remove_const(:RequestProcessor)
Mimi::Messaging::RequestProcessor = Mimi::Messaging::MockRequestProcessor
