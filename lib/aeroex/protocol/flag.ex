defmodule Aeroex.Protocol.Flag do
  import Aeroex.Tools
  @info %{
    ##### info1 byte #####################
    read:                  bit_value(1,3),
    get_all:               bit_value(2,3),
    #unused:               bit_value(3,3),
    batch:                 bit_value(4,3),
    xdr:                   bit_value(5,3),
    nobindata:             bit_value(6,3),
    consistency_level_b0:  bit_value(7,3),
    consistency_level_b1:  bit_value(8,3),

    ##### info2 byte #####################
    write:                 bit_value(1,2),
    delete:                bit_value(2,2),
    generation:            bit_value(3,2),
    generation_gt:         bit_value(4,2),
    #unused:               bit_value(5,2),
    create_only:           bit_value(6,2),
    bin_create_only:       bit_value(7,2),
    respond_all_ops:       bit_value(8,2),

    ##### info3 byte #####################
    last:                  bit_value(1,1),
    commit_level_b0:       bit_value(2,1),
    commit_level_b1:       bit_value(3,1),
    update_only:           bit_value(4,1),
    create_or_replace:     bit_value(5,1),
    replace_only:          bit_value(6,1),
    bin_replace_only:      bit_value(7,1)
    #unused:               bit_value(8,1)
  }

  def get(flags) do
    <<get(flags, 0)::unsigned-integer-size(24)>>
  end

  def get([], acc), do: acc
  def get([flag|flags], acc) do
    get(flags, acc + @info[flag])
  end
end
