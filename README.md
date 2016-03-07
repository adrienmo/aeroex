# Aeroex

Native Elixir client for Aerospike.
Work in progress.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add aeroex to your list of dependencies in `mix.exs`:

        def deps do
          [{:aeroex, "~> 0.0.1"}]
        end

  2. Ensure aeroex is started before your application:

        def application do
          [applications: [:aeroex]]
        end

## Usage

```elixir
:ok = Aeroex.connect(%{host: '127.0.0.1', port: 3000})
record = %{"bin1" => "value1", "bin2" => "value2"}
{:ok, _} = Aeroex.write("test", "set", "key", record)
{:ok, result} = Aeroex.read("test", "set", "key")
```
