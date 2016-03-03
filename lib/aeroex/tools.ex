defmodule Aeroex.Tools do
  use Bitwise
  def bit_value(bit_position, byte_position) do
    (1 <<< (bit_position - 1)) <<< ((byte_position - 1) * 8)
  end
end
