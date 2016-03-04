defmodule Aeroex do
  def start_link(node) do
    Aeroex.Connection.start_link(node)
  end

  def read(pid, namespace, set, key) do
    fields = get_fields(namespace, set, key)
    flags = [:read, :get_all]
    operations = [{:read, <<>>, <<>>}]

    execute(pid, flags, fields, operations)
  end

  def write(pid, namespace, set, key, record) do
    fields = get_fields(namespace, set, key)
    flags = [:write]
    operations = Enum.map(record, fn({bin_name, data}) ->
      {:write, bin_name, data}
    end)
    execute(pid, flags, fields, operations)
  end

  def info(pid, names) do
    execute(pid, :info, names, nil)
  end

  defp get_fields(namespace, set, key) do
    [{:namespace, namespace}, {:set, set}, {:key,  <<3>> <> key}]
  end

  defp execute(pid, flags, fields, operations) do
    data = Aeroex.Protocol.get(flags, fields, operations)
    response = Aeroex.Connection.send(pid, data)
    Aeroex.Protocol.parse(response)
  end
end
