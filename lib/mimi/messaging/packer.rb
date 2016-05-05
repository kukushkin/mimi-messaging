require 'msgpack'

class TypePacker
  APPLICATION_TYPE_EXT = 0x00

  def self.register(type, opts = {})
    raise ArgumentError, 'Invalid :from_bytes, proc expected' unless opts[:from_bytes].is_a?(Proc)
    raise ArgumentError, 'Invalid :to_bytes, proc expected' unless opts[:to_bytes].is_a?(Proc)
    type_name = type.to_s
    params = opts.dup.merge(type: type, type_name: type_name)
    type_packers[type] = params
    type.send(:define_method, :to_msgpack_ext) { TypePacker.pack(self) }
    MessagePack::DefaultFactory.register_type(
      APPLICATION_TYPE_EXT,
      type,
      packer: :to_msgpack_ext,
      # unpacker: :from_msgpack_ext
    )

    MessagePack::DefaultFactory.register_type(
      APPLICATION_TYPE_EXT,
      self,
      unpacker: :unpack,
      # unpacker: :from_msgpack_ext
    )

    # pk = MessagePack::Packer.new
    # pk.register_type(APPLICATION_TYPE_EXT, type, :to_msgpack_ext) # { |v| TypePacker.pack(v) }

    # register_type_packer!
  end

  def self.type_packers
    @type_packers ||= {}
  end

  def self.pack(value)
    type_packer = type_packers.values.find { |p| value.is_a?(p[:type]) }
    raise "No packer registered for type #{value.class}" unless type_packer
    bytes = type_packer[:to_bytes].call(value)
    "#{type_packer[:type_name]}=#{bytes}"
  end

  def self.unpack(value)
    vp = value.partition('=') # splits "Type=bytes" into ['Type', '=', 'bytes']
    type_name = vp.first
    bytes = vp.last
    type_packer = type_packers.values.find { |p| p[:type_name] == type_name }
    raise "No unpacker registered for type #{type_name}" unless type_packer
    type_packer[:from_bytes].call(bytes)
  end

  def self.register_type_packer!
    return if @type_packer_registered
    # pk = MessagePack::Packer.new
    # pk.register_type(APPLICATION_TYPE_EXT) { |v| TypePacker.pack(v) }
    uk = MessagePack::Unpacker.new
    uk.register_type(APPLICATION_TYPE_EXT) { |b| TypePacker.unpack(b) }
    @type_packer_registered = true
  end
end # class TypePacker


class A
  class B
    attr_reader :value
    def initialize(value)
      @value = value
    end
  end # class B
end # class A

TypePacker.register(
  Time,
  from_bytes: -> (b) { Time.at(b.unpack('D').first) },
  to_bytes: -> (v) { [v.to_f].pack('D') }
)

TypePacker.register(
  A::B,
  from_bytes: -> (b) { A::B.new(b.unpack('D').first) },
  to_bytes: -> (v) { [v.value.to_f].pack('D') }
)

# TypePacker.register(
#   DateTime,
#   from_bytes: -> (b) { Time.at(b.unpack('D').first).to_datetime },
#   to_bytes: -> (v) { [v.to_time.to_f].pack('D') }
# )

# m = "\x83\xA1a\xC7\r\x00Time=\x1D@\x95\xC7\x80\xCA\xD5A\xA1b\x02\xA1c\xC7\x11\x00DateTime=X@\x95\xC7\x80\xCA\xD5A"

