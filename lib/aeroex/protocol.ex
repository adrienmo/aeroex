defmodule Aeroex.Protocol do

  @delimiter "\n"
  @protocol_version 2
  @header_sz 22
  @unused 0

  @message_type_info        1
  @message_type_msg         3

  @message_type %{
    info:                  @message_type_info,
    message:               @message_type_msg
  }

  @info1 %{
    read:                  1,
    get_all:               2,
    #unused:               4,
    batch:                 8,
    xdr:                   16,
    nobindata:             32,
    consistency_level_b0:  64,
    consistency_level_b1:  128
  }

  @info2 %{
    write:                 1,
    delete:                2,
    generation:            4,
    generation_gt:         8,
    #unused:               16,
    create_only:           32,
    bin_create_only:       64,
    respond_all_ops:       128
  }

  @info3 %{
    last:                  1,
    commit_level_b0:       2,
    commit_level_b1:       4,
    update_only:           8,
    create_or_replace:     16,
    replace_only:          32,
    bin_replace_only:      64
    #unused:               128
  }

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

  @data_type %{
    null:                  0,
    integer:               1,
    float:                 2,
    string:                3,
    blob:                  4,
    timestamp:             5,
    digest:                6,
    lua_blob:              18,
    map:                   19,
    list:                  20,
    geojson:               23
  }

  def protocol_header(type, length) do
    <<
      @protocol_version,
      @message_type[type],
      length::unsigned-integer-size(48)
    >>
  end

  def parse_response(<<_, @message_type_info, _::bytes-size(6), info::binary>>) do
    case String.split(info, @delimiter) do
      [result, ""] ->
        {:ok, result}
      results ->
        {:ok, :lists.droplast(results)}
    end
  end

  def parse_response(<<_, @message_type_msg, _::bytes-size(6), message::binary>>) do
    <<header::bytes-size(22), payload::binary>> = message
    <<
      _::bytes-size(5),
      result_code::unsigned-integer-size(8),
      _::bytes-size(12),
      n_fields::unsigned-integer-size(16),
      n_ops::unsigned-integer-size(16)
    >> = header

    case result_code do
      0 ->
        response = parse_payload(payload, n_fields, n_ops)
        {:ok, response}
      error_code ->
        {:error, error_code}
    end
  end

  def parse_response(_), do: {:error, "unknown format"}

  def parse_payload(payload, _, _) do
    parse_fields(payload)
  end

  def parse_fields(payload), do: parse_fields(payload, %{})
  def parse_fields(<<>>, acc), do: acc
  def parse_fields(<<size::unsigned-integer-size(32), field_type::unsigned-integer-size(8), data::binary>>, acc) do
    new_size = size - 1
    <<field::bytes-size(new_size), next::binary>> = data
    {key, value} = parse_field(field)
    acc = Map.put(acc, key, value)
    parse_fields(next, acc)
  end

  def parse_field(<<type::unsigned-integer-size(8), size::unsigned-integer-size(16), data::binary>>) do
    <<key::bytes-size(size), value::binary>> = data
    {key, value}
  end

  def get_message({:info, names}) do
    get_message(:info, names)
  end

  def get_message({:write, namespace, set, key, record}) do
    get_message(:write, namespace, set, key, record)
  end

  def get_message({:read, namespace, set, key}) do
    get_message(:read, namespace, set, key)
  end

  def get_message(:info, names) when is_list(names) do
    get_message(:info, Enum.join(names, @delimiter))
  end

  def get_message(:info, names) when is_bitstring(names) do
    names = names <> @delimiter
    length = byte_size(names)
    protocol_header(:info, length) <> names
  end

  def get_fields(namespace, set, key) do
    [{:namespace, namespace}, {:set, set}, {:key,  <<3>> <> key}]
  end

  def get_message(action, namespace, set, key, record \\ nil) do
    info = get_info_bits(action)
    generation = get_generation
    record_ttl = 0
    transaction_ttl = 0

    fields = get_fields(namespace, set, key)
    fields_bin = get_fields_bin(fields)
    n_fields = length(fields)

    operations = get_operations(action, record)
    operations_bin = get_operations_bin(operations)
    n_ops = length(operations)

    data = fields_bin <> operations_bin

    payload = <<
      @header_sz,
      info::binary-size(3),
      @unused,
      @unused,
      generation::binary-size(4),
      record_ttl::unsigned-integer-size(32),
      transaction_ttl::unsigned-integer-size(32),
      n_fields::unsigned-integer-size(16),
      n_ops::unsigned-integer-size(16),
      data::binary
    >>

    length = byte_size(payload)
    header = protocol_header(:message, length)

    header <> payload
  end

  def get_operations(:write, record) do
    Enum.map(record, fn({bin_name, data}) ->
      {:write, bin_name, data}
    end)
  end
  def get_operations(:read, nil) do
    [{:read, <<>>, <<>>}]
  end

  def get_operations_bin(list), do: get_operations_bin(list, <<>>)
  def get_operations_bin([], acc), do: acc
  def get_operations_bin([operation|rest], acc) do
    get_operations_bin(rest, acc <> get_operation_bin(operation))
  end

  def get_operation_bin({operation, bin_name, data}) do
    bin_name_length = byte_size(bin_name)
    op = @operation[operation]
    {bin_data_type, data} = convert_data(data)
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

  defp convert_data(nil), do: {@data_type.null, <<0>>}
  defp convert_data(integer) when is_integer(integer) do
    {@data_type.integer, <<integer::unsigned-integer-size(32)>>}
  end
  defp convert_data(string) when is_bitstring(string) do
    {@data_type.string, string}
  end

  def get_fields_bin(list), do: get_fields_bin(list, <<>>)
  def get_fields_bin([], acc), do: acc
  def get_fields_bin([field|rest], acc) do
    get_fields_bin(rest, acc <> get_field_bin(field))
  end

  def get_field_bin({type, data}) do
    size = byte_size(data) + 1
    field_type = @field_type[type]
    <<
      size::unsigned-integer-size(32),
      field_type::unsigned-integer-size(8),
      data::binary
    >>
  end

  def get_generation() do
    <<0, 0, 0, 0>>
  end

  def get_info_bits(action) do
    <<
      get_info1_bits(action),
      get_info2_bits(action),
      get_info3_bits(action)
    >>
  end

  def get_info1_bits(:write), do: 0
  def get_info1_bits(:read), do: @info1.read + @info1.get_all

  def get_info2_bits(:write), do: @info2.write
  def get_info2_bits(:read), do: 0

  def get_info3_bits(:write), do: 0
  def get_info3_bits(:read), do: 0
end
