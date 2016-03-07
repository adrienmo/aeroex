defmodule Aeroex.Manager do
  use GenServer
  use Bitwise

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def connect(node) do
    {:ok, pid} = Aeroex.Connection.Connection.start_link(node)
    {:ok, nodes} = Aeroex.info(pid, ["service", "services"])

    nodes = List.flatten(nodes)

    pools = Enum.map(nodes, &Aeroex.Connection.Pool.create/1)
    distribution = Enum.map(pools, &(Aeroex.info!(&1, ["replicas-master"])))
      |> List.flatten()
      |> Aeroex.Tools.zip_by_keys()
      |> Enum.map(fn({k,v}) ->
        {k, Enum.map(v, &(Aeroex.Tools.get_index(&1, true))) |> List.to_tuple()}
      end)
      |> Map.new()

    %{
      pools: List.to_tuple(pools),
      distribution: distribution
    }
  end

  def compute_partition_index(set, key) do
    <<a,b,c,d,_::binary>> = :crypto.hash(:ripemd160, set <> <<3>> <> key)
    <<x::unsigned-integer-size(32)>> = <<d,c,b,a>>
    rem(band(x, 0xFFFF), 4096)
  end
end
