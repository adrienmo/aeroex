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
    scan_options:          8,
    index_name:           21,
    index_filter:         22,
    index_range:          23,
    index_limit:          24,
    index_order_by:       25,
    udf_package_name:     30,
    udf_function:         31,
    udf_arglist:          32,
    udf_op:               33,
    query_binlist:        40,
    batch_index:          41,
    batch_index_with_set: 42
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

  def parse(payload, n), do: parse(payload, %{}, n)
  def parse(rest, acc, 0), do: {acc, rest}
  def parse(<<size::unsigned-integer-size(32), field_type::unsigned-integer-size(8), data::binary>>, acc, n) do
    new_size = size - 1
    <<value::bytes-size(new_size), next::binary>> = data
    acc = Map.put(acc, field_type, value)
    parse(next, acc, n - 1)
  end
end
