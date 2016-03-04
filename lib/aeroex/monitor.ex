defmodule Aeroex.Monitor do
  use Bitwise
  def compute_partition_index(set, key) do
    <<a,b,c,d,_::binary>> = :crypto.hash(:ripemd160, set <> <<3>> <> key)
    <<x::unsigned-integer-size(32)>> = <<d,c,b,a>>
    rem(band(x, 0xFFFF), 4096)
  end
end
