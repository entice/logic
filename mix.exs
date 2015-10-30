defmodule Entice.Logic.Mixfile do
  use Mix.Project

  def project do
    [app: :entice_logic,
     version: "0.0.1",
     elixir: "~> 1.1",
     deps: deps]
  end

  def application do
    [applications: [:logger, :entice_entity]]
  end

  defp deps do
    [{:entice_entity, github: "entice/entity", ref: "c6c1d0a487ae3300ce0272928b9e69b15fa2c87a"},
     {:uuid, "~> 1.0"},
     {:inflex, "~> 1.5"},
     {:pipe, "~> 0.0.2"}]
  end
end
