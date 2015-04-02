defmodule Entice.Logic.Mixfile do
  use Mix.Project

  def project do
    [app: :entice_logic,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  def application do
    [applications: [:logger, :entice_entity]]
  end

  defp deps do
    [{:entice_entity, github: "entice/entity", ref: "494ccc4453cb663a1838c00c991621ba9782f862"},
     {:entice_skill, github: "entice/skill", ref: "6c6a83936b543c52a6eebb07e1b6b47dc2a5fe1e"},
     {:uuid, "~> 0.1.5"},
     {:inflex, "~> 0.2.5"}]
  end
end
