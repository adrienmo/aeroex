defmodule Aeroex.Protocol do
  alias Aeroex.Protocol.{Field, Operation, Header, Info, Flag}

  @delimiter "\n"
  @header_sz 22
  @unused 0

  def get(:info, names, _) do
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
    <<header::bytes-size(22), payload::binary>> = data
    <<
      _::bytes-size(5),
      result_code::unsigned-integer-size(8),
      _::bytes-size(12),
      _n_fields::unsigned-integer-size(16),
      _n_ops::unsigned-integer-size(16)
    >> = header

    case result_code do
      0 ->
        response = Field.parse(payload)
        {:ok, response}
      error_code ->
        {:error, error_code}
    end
  end

  def parse(_, _) do
    {:error, "unknown format"}
  end
end
