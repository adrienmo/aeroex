defmodule Aeroex.Protocol.Field do
  @field_type %{
    namespace:             0,
    set:                   1,
    key:                   2,
    bin:                   3,
    digest_ripe:           4,
    gu_tid:                5,
    digest_ripe_array:     6,
    trid:                  7,
    scan_options:          8
  }

  def get({type, data}) do
    size = byte_size(data) + 1
    field_type = @field_type[type]
    <<
      size::unsigned-integer-size(32),
      field_type::unsigned-integer-size(8),
      data::binary
    >>
  end

  def get(list), do: get(list, <<>>)
  def get([], acc), do: acc
  def get([field|rest], acc) do
    get(rest, acc <> get(field))
  end

  def parse(payload), do: parse(payload, %{})
  def parse(<<>>, acc), do: acc
  def parse(<<size::unsigned-integer-size(32), _field_type::unsigned-integer-size(8), data::binary>>, acc) do
    new_size = size - 1
    <<field::bytes-size(new_size), next::binary>> = data
    <<_type::unsigned-integer-size(8), size::unsigned-integer-size(16), data::binary>> = field
    <<key::bytes-size(size), value::binary>> = data
    acc = Map.put(acc, key, value)
    parse(next, acc)
  end
end
