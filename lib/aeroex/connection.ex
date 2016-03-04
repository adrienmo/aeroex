defmodule Aeroex.Connection do
  use Connection

  @initial_state %{socket: nil, node: nil}

  def start_link(node) do
    Connection.start_link(__MODULE__, %{@initial_state | node: node})
  end

  def init(state) do
    {:connect, nil, state}
  end

  def connect(_info, state) do
    opts = [:binary, active: :false]

    case :gen_tcp.connect(state.node.host, state.node.port, opts) do
      {:ok, socket} ->
        {:ok, %{state | socket: socket}}
      {:error, reason} ->
        IO.puts "TCP connection error: #{inspect reason}"
        {:backoff, 1000, state} # try again in one second
    end
  end

  def send(pid, data) do
    GenServer.call(pid, {:send, data})
  end

  def handle_call({:send, data}, _, state) do
    :ok = :gen_tcp.send(state.socket, data)
    msg = receive_data(state.socket)
    {:reply, msg, state}
  end

  def receive_data(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data_size = Aeroex.Protocol.Header.parse(data) |> elem(1)
    remaining_size = data_size - (byte_size(data) - 8)
    receive_data(socket, data, remaining_size)
  end

  def receive_data(_, acc, 0), do: acc
  def receive_data(socket, acc, remaining_size) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    receive_data(socket, acc <> data, remaining_size - byte_size(data))
  end
end
