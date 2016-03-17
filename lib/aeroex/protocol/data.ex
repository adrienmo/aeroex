defmodule Aeroex.Protocol.Data do

  @data_type %{
    null:                  0,
    integer:               1,
    float:                 2,
    string:                3,
    blob:                  4,
    timestamp:             5,
    digest:                6,
    lua_blob:              18,
    map:                   19,
    list:                  20,
    geojson:               23
  }

  def get_type(nil), do: @data_type.null
  def get_type(integer) when is_integer(integer), do: @data_type.integer
  def get_type(string) when is_bitstring(string), do: @data_type.string

  def get(nil), do: <<0>>
  def get(integer) when is_integer(integer), do: <<integer::unsigned-integer-size(32)>>
  def get(string) when is_bitstring(string), do: string

  def parse(<<integer::unsigned-integer-size(64)>>, 1), do: integer
  def parse(string, 3), do: string
  def parse(_, 0), do: nil
  def parse(_, 19), do: %{}
end
