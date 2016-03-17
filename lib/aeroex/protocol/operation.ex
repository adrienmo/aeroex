defmodule Aeroex.Protocol.Operation do
  alias Aeroex.Protocol.Data
  @operation %{
    read:                  1,
    write:                 2,
    #unused:               3,
    #unused:               4,
    incr:                  5,
    #unused:               6,
    #unused:               7,
    #unused:               8,
    append:                9,
    prepend:               10,
    touch:                 11
  }
  @unused 0

  def get({operation, bin_name, data}) do
    bin_name_length = byte_size(bin_name)
    op = @operation[operation]
    bin_data_type = Data.get_type(data)
    data = Data.get(data)
    size = byte_size(data) + bin_name_length + 4
    <<
      size::unsigned-integer-size(32),
      op::unsigned-integer-size(8),
      bin_data_type::unsigned-integer-size(8),
      @unused::unsigned-integer-size(8),
      bin_name_length::unsigned-integer-size(8),
      bin_name::binary,
      data::binary
    >>
  end

  def get(list), do: get(list, <<>>)
  def get([], acc), do: acc
  def get([operation|rest], acc) do
    get(rest, acc <> get(operation))
  end

  def parse(payload), do: parse(payload, %{})
  def parse(<<>>, acc), do: acc
  def parse(<<size::unsigned-integer-size(32), op::unsigned-integer-size(8),
    bin_data_type::unsigned-integer-size(8), _, bin_name_length::unsigned-integer-size(8),
    data::binary>>, acc) do
    new_size = size - 4 - bin_name_length
    <<bin_name::bytes-size(bin_name_length), value::bytes-size(new_size), next::binary>> = data
    acc = Map.put(acc, bin_name, Data.parse(value, bin_data_type))
    parse(next, acc)
  end
end
