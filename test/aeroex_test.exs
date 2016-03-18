defmodule AeroexTest do
  use ExUnit.Case
  doctest Aeroex

  setup_all do
    :ok = Aeroex.connect(%{host: '127.0.0.1', port: 3000})
  end

  test "set/get" do
    record = %{"bin1" => "value1", "bin2" => "value2"}
    {:ok, _} = Aeroex.write("test", "set", "key_test", record)
    {:ok, result} = Aeroex.read("test", "set", "key_test")
    assert(record == result)
  end

  test "info" do
    {:ok, result} = Aeroex.info(["build", "replicas-all"])
    assert(length(result) == 2)
  end

  test "scan" do
    record = %{"bin1" => "value1"}
    {:ok, _} = Aeroex.write("test", "set2", "key_test1", record)
    {:ok, _} = Aeroex.write("test", "set2", "key_test2", record)
    Aeroex.scan("test", "set")
  end

  test "scan range" do
    Aeroex.scan("test", "event", "timestamp", 1232146, 1232147)
  end
end
