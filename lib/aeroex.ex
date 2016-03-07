defmodule Aeroex do
  use Application

  def start(_type, _args) do
    Aeroex.Supervisor.start_link()
  end

  def connect(node) do
    Aeroex.Manager.connect(node)
  end

  def read(ref \\ nil, namespace, set, key) do
    fields = get_fields(namespace, set, key)
    flags = [:read, :get_all]
    operations = [{:read, <<>>, <<>>}]

    execute(ref, flags, fields, operations)
  end

  def write(ref \\ nil, namespace, set, key, record) do
    fields = get_fields(namespace, set, key)
    flags = [:write]
    operations = Enum.map(record, fn({bin_name, data}) ->
      {:write, bin_name, data}
    end)
    execute(ref, flags, fields, operations)
  end

  def info!(ref \\ nil, names) do
    {:ok, result} = info(ref, names)
    result
  end

  def info(ref \\ nil, names) do
    execute(ref, :info, names, nil)
  end

  defp get_fields(namespace, set, key) do
    [{:namespace, namespace}, {:set, set}, {:key,  <<3>> <> key}]
  end

  defp execute(nil, flags, fields, operations) do

  end

  defp execute(pid, flags, fields, operations) when is_pid(pid) do
    data = Aeroex.Protocol.get(flags, fields, operations)
    response = Aeroex.Connection.Connection.send(pid, data)
    Aeroex.Protocol.parse(response)
  end

  defp execute(pool_name, flags, fields, operations) when is_atom(pool_name) do
    data = Aeroex.Protocol.get(flags, fields, operations)
    response = Aeroex.Connection.Pool.send(pool_name, data)
    Aeroex.Protocol.parse(response)
  end
end
