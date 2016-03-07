defmodule Aeroex.Protocol.Info do

  def parse(list) when is_list(list), do: Enum.map(list, &parse/1)
  def parse(<<"services", _, data::binary>>) do
    String.split(data, ";") |> Enum.map(&parse_service/1)
  end
  def parse(<<"service", _, data::binary>>) do
    parse_service(data)
  end
  def parse(<<"replicas-master", _, data::binary>>) do
    String.split(data, ";")
      |> Enum.map(fn(x) ->
        [namespace, b64_bitmap] = String.split(x, ":")
        {namespace, parse_b64_bitmap(b64_bitmap)}
      end)
  end

  def parse(all) do
    all
  end

  def parse_service(data) do
    [host, port] = String.split(data, ":")
    %{host: host, port: String.to_integer(port)}
  end

  def parse_b64_bitmap(b64_bitmap) do
    bitmap = Base.decode64!(b64_bitmap)
    parse_bitmap(bitmap, 0, []) |> Enum.reverse() 
  end

  def parse_bitmap(<<>>, _, acc), do: acc
  def parse_bitmap(<<0::1, rest::bitstring>>, counter, acc) do
    parse_bitmap(rest, counter + 1, [false |acc])
  end
  def parse_bitmap(<<1::1, rest::bitstring>>, counter, acc) do
    parse_bitmap(rest, counter + 1, [true |acc])
  end
end
