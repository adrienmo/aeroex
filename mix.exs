defmodule Aeroex.Mixfile do
  use Mix.Project

  def project do
    [app: :aeroex,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger, :poolboy], mod: {Aeroex, []}]
  end

  defp deps do
    [
      {:connection, "~> 1.0"},
      {:poolboy, "~> 1.5.1"}
    ]
  end
end
