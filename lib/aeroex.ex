defmodule Aeroex do
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

  def read(pid, namespace, set, key) do
    command(pid, {:read, namespace, set, key})
  end

  def write(pid, namespace, set, key, record) do
    command(pid, {:write, namespace, set, key, record})
  end

  def info(pid, info) do
    command(pid, {:info, info})
  end

  def command(pid, commands) do
    command = Aeroex.Protocol.get_message(commands)
    result = GenServer.call(pid, {:command, command})
    Aeroex.Protocol.parse_response(result)
  end

  def handle_call({:command, command}, _, state) do
    :ok = :gen_tcp.send(state.socket, command)
    msg = receive_aerospike_msg(state.socket)
    {:reply, msg, state}
  end

  def receive_aerospike_msg(socket) do
    {:ok, msg} = :gen_tcp.recv(socket, 0)
    remaining_size = Aeroex.Protocol.get_message_size(msg) - byte_size(msg) + 8
    receive_aerospike_msg(socket, msg, remaining_size)
  end

  def receive_aerospike_msg(_, acc, 0), do: acc
  def receive_aerospike_msg(socket, acc, remaining_size) do
    {:ok, msg} = :gen_tcp.recv(socket, 0)
    receive_aerospike_msg(socket, acc <> msg, remaining_size - byte_size(msg))
  end

  def parse_replica(replica) do
    [_, replica] = String.split(replica, "\t")
    [replica|_] = String.split(replica, ";")
    [_, replica] = String.split(replica, ":")
    bitmap = Base.decode64!(replica)
    decode_partition(bitmap, 0, [])
  end

  def decode_partition(<<>>, _, acc), do: acc
  def decode_partition(<<0::1, rest::bitstring>>, counter, acc) do
    decode_partition(rest, counter + 1, acc)
  end
  def decode_partition(<<1::1, rest::bitstring>>, counter, acc) do
    decode_partition(rest, counter + 1, [counter |acc])
  end
end
