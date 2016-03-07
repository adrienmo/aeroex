defmodule Aeroex.Tools do
  use Bitwise
  def bit_value(bit_position, byte_position) do
    (1 <<< (bit_position - 1)) <<< ((byte_position - 1) * 8)
  end

  def get_index(tuple, value) do
    tuple |> Tuple.to_list()
      |> Enum.reduce_while(0, fn(x, acc) ->
        if x == value, do: {:halt, acc}, else: {:cont, acc + 1}
      end)
  end

  def zip_by_keys(list) do
    :proplists.get_keys(list) |> Enum.map(fn(key) ->
      {key, :proplists.get_all_values(key, list) |> List.zip()}
    end)
  end
end
