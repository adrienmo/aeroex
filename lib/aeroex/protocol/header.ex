defmodule Aeroex.Protocol.Header do
  @protocol_version 2
  @message_type %{
    :info     => 1,
    :message  => 3,
    1         => :info,
    3         => :message
  }

  def get(type, size) do
    <<
      @protocol_version,
      @message_type[type],
      size::unsigned-integer-size(48)
    >>
  end

  def parse(<<_, type, size::bytes-size(6), _::binary>>) do
    <<size::unsigned-integer-size(48)>> = size
    {@message_type[type], size}
  end
end
