defmodule Aeroex.Protocol.Partition do
  def parse(<<>>, _, acc), do: acc
  def parse(<<0::1, rest::bitstring>>, counter, acc) do
    parse(rest, counter + 1, acc)
  end
  def parse(<<1::1, rest::bitstring>>, counter, acc) do
    parse(rest, counter + 1, [counter |acc])
  end
end
