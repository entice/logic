defmodule Entice.Logic.Mixfile do
  use Mix.Project

  def project do
    [app: :entice_logic,
     version: "0.0.1",
     elixir: "~> 1.2",
     deps: deps]
  end

  def application do
    [applications: [:logger, :entice_entity]]
  end

  defp deps do
    [{:entice_entity, github: "entice/entity", ref: "c26f6f77ae650e25e6cd2ffea8aae46b7d83966a"},
     {:uuid, "~> 1.1"},
     {:inflex, "~> 1.5"},
     {:pipe, "~> 0.0.2"}]
  end
end
