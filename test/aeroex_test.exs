defmodule AeroexTest do
  use ExUnit.Case
  doctest Aeroex

  test "set/get" do
    {:ok, socket} = Aeroex.start_link(%{host: '127.0.0.1', port: 3000})
    record = %{"bin1" => "value1", "bin2" => "value2"}
    {:ok, _} = Aeroex.write(socket, "test", "set", "key", record)
    {:ok, result} = Aeroex.read(socket, "test", "set", "key")

    assert(record == result)
  end

  test "info" do
    {:ok, socket} = Aeroex.start_link(%{host: '127.0.0.1', port: 3000})
    {:ok, result} = Aeroex.info(socket, ["build", "replicas-all"])

    assert(length(result) == 2)
  end
end
