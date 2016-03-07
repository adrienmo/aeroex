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
end
