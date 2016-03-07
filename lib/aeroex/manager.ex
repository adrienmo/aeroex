defmodule Aeroex.Manager do
  use GenServer
  use Bitwise

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    :ets.new(__MODULE__, [:public, :set, :named_table, {:read_concurrency, true}])
    {:ok, nil}
  end

  def connect(node) do
    GenServer.call(__MODULE__, {:connect, node})
  end

  def handle_call({:connect, node}, _, state) do
    {:ok, pid} = Aeroex.Connection.Connection.start_link(node)
    {:ok, nodes} = Aeroex.info(pid, ["service", "services"])

    nodes = List.flatten(nodes)

    pools = Enum.map(nodes, &Aeroex.Connection.Pool.create/1)
    ns_distributions = Enum.map(pools, &(Aeroex.info!(&1, ["replicas-master"])))
      |> List.flatten()
      |> Aeroex.Tools.zip_by_keys()
      |> Enum.map(fn({k,v}) ->
        {k, Enum.map(v, &(Aeroex.Tools.get_index(&1, true))) |> List.to_tuple()}
      end)
      |> Map.new()

    :ets.insert(__MODULE__, {:pools, List.to_tuple(pools)})
    for {namespace, distribution} <- ns_distributions do
      :ets.insert(__MODULE__, {namespace, distribution})
    end
    {:reply, :ok, state}
  end

  def get_pool_name(nil) do
    [{_, pools}] = :ets.lookup(__MODULE__, :pools)
    pools |> elem(0)
  end
  def get_pool_name(fields) do
    index = compute_partition_index(fields[:set], fields[:key])
    [{_, distribution}] = :ets.lookup(__MODULE__, fields[:namespace])
    [{_, pools}] = :ets.lookup(__MODULE__, :pools)
    elem(pools, elem(distribution, index))
  end

  def compute_partition_index(set, key) do
    <<a,b,c,d,_::binary>> = :crypto.hash(:ripemd160, set <> key)
    <<x::unsigned-integer-size(32)>> = <<d,c,b,a>>
    rem(band(x, 0xFFFF), 4096)
  end
end
