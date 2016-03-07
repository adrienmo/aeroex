defmodule Aeroex.Connection.Worker do
  use GenServer

  def start_link(node) do
    GenServer.start_link(__MODULE__, node, [])
  end

  def init(node) do
    {:ok, socket} = Aeroex.Connection.Connection.start_link(node)
    state = %{socket: socket}
    {:ok, state}
  end

  def handle_call({:send, data}, _from, state) do
    {:reply, Aeroex.Connection.Connection.send(state.socket, data), state}
  end
end
