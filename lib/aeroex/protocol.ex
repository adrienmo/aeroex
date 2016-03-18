defmodule Aeroex.Protocol do
  alias Aeroex.Protocol.{Field, Operation, Header, Info, Flag}

  @delimiter "\n"
  @header_sz 22
  @unused 0

  def get(:info, _, names) do
    data = get_info(names)
    size = byte_size(data)
    header = Header.get(:info, size)
    header <> data
  end

  def get(flags, fields, operations) do
    data = get_message(flags, fields, operations)
    size = byte_size(data)
    header = Header.get(:message, size)
    header <> data
  end

  defp get_info(names) when is_list(names), do: Enum.join(names ++ [""], @delimiter)
  defp get_info(name) when is_bitstring(name), do: name <> @delimiter

  defp get_message(flags, fields, operations) do
    generation = 0
    record_ttl = 0
    transaction_ttl = 0
    n_fields = length(fields)
    n_ops = length(operations)
    flag_bin = Flag.get(flags)
    fields_bin = Field.get(fields)
    operations_bin = Operation.get(operations)

    <<
      @header_sz,
      flag_bin::binary-size(3),
      @unused,
      @unused,
      generation::unsigned-integer-size(32),
      record_ttl::unsigned-integer-size(32),
      transaction_ttl::unsigned-integer-size(32),
      n_fields::unsigned-integer-size(16),
      n_ops::unsigned-integer-size(16),
      (fields_bin <> operations_bin)::binary
    >>
  end

  def parse(multi_response) when is_list(multi_response) do
    for response <- multi_response, do: parse(response)
  end

  def parse(<<header::bytes-size(8), data::binary>>) do
    parse(Header.parse(header), data)
  end

  def parse({:info, _}, data) do
    case String.split(data, @delimiter) do
      [result, ""] ->
        {:ok, Info.parse(result)}
      results ->
        {:ok, Info.parse(:lists.droplast(results))}
    end
  end

  def parse({:message, _}, data) do
    case parse_message(data, []) do
      [] ->
        {:ok, nil}
      [elem] ->
        elem
      multi_response ->
        multi_response
    end
  end

  def parse(_, _) do
    {:error, "unknown format"}
  end

  def parse_message(<<>>, acc), do: acc
  def parse_message(<<header::bytes-size(22), payload::binary>>, acc) do
    header = parse_message_head(header)

    case header.result_code do
      0 ->
        {fields, payload} = Field.parse(payload, header.n_fields)
        {operations, payload} = Operation.parse(payload, header.n_ops)
        if operations == %{} do
          parse_message(payload, acc)
        else
          parse_message(payload, [{:ok, operations}| acc])
        end
      error_code ->
        {:error, error_code}
    end
  end

  def parse_message_head(<<
      _,
      flag_bin::binary-size(3),
      _,
      result_code::unsigned-integer-size(8),
      generation::unsigned-integer-size(32),
      record_ttl::unsigned-integer-size(32),
      transaction_ttl::unsigned-integer-size(32),
      n_fields::unsigned-integer-size(16),
      n_ops::unsigned-integer-size(16),
      _::binary()
    >>) do
    %{
      flags: Flag.parse(flag_bin),
      result_code: result_code,
      generation: generation,
      record_ttl: record_ttl,
      transaction_ttl: transaction_ttl,
      n_fields: n_fields,
      n_ops: n_ops
    }
  end
end
