#
# MessagePack extensions for common types
#
Mimi::Messaging::TypePacker.register(
  Time,
  from_bytes: -> (b) { Time.at(b.unpack('D').first).utc },
  to_bytes: -> (v) { [v.utc.to_f].pack('D') }
)

Mimi::Messaging::TypePacker.register(
  BigDecimal,
  from_bytes: -> (b) { BigDecimal.new(b) },
  to_bytes: -> (v) { v.to_s }
)
