defmodule Aeroex.Connection.Pool do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    supervise([], strategy: :one_for_one)
  end

  def get_pool_name(%{host: host, port: port}) do
    Enum.join(["aeroex_pool", host, port], "_") |> String.to_atom()
  end

  def create(node) do
    pool_name = get_pool_name(node)
    pool_options = [
      name: {:local, pool_name},
      worker_module: Aeroex.Connection.Worker,
      size: 10,
      max_overflow: 0
    ]

    child_spec = :poolboy.child_spec(pool_name, pool_options, node)
    Supervisor.start_child(__MODULE__, child_spec)

    pool_name
  end

  def send(pool_name, data) do
    try do
      :poolboy.transaction(pool_name, fn(worker) ->
        :gen_server.call(worker, {:send, data})
      end)
    catch
      _ ->
        {:error, :no_connection}
    end
  end
end
