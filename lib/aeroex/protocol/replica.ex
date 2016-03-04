defmodule Aeroex.Protocol.Replica do
  def parse(replica) do
    [_, replica] = String.split(replica, "\t")
    [replica|_] = String.split(replica, ";")
    [_, replica] = String.split(replica, ":")
    bitmap = Base.decode64!(replica)
    #decode_partition(bitmap, 0, [])
  end
end
