defmodule Aeroex do
  use Connection

  @initial_state %{socket: nil, queue: :queue.new(), node: nil}

  def start_link(node) do
    Connection.start_link(__MODULE__, %{@initial_state | node: node})
  end

  def init(state) do
    {:connect, nil, state}
  end

  def connect(_info, state) do
    opts = [:binary, active: :once]

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

  def handle_call({:command, command}, from, %{queue: q} = state) do
    :inet.setopts(state.socket, active: :once)
    :ok = :gen_tcp.send(state.socket, command)
    state = %{state | queue: :queue.in(from, q)}
    {:noreply, state}
  end

  def handle_info({:tcp, socket, msg}, %{socket: socket} = state) do
    {{:value, client}, new_queue} = :queue.out(state.queue)
    GenServer.reply(client, msg)
    {:noreply, %{state | queue: new_queue}}
  end
end
