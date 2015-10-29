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
    [{:entice_entity, github: "entice/entity", ref: "d69c8bd0a73f7c1b32cbecca4824fada46f6302f"},
     {:uuid, "~> 1.0"},
     {:inflex, "~> 1.5"},
     {:pipe, "~> 0.0.2"}]
  end
end
