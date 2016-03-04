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
end
