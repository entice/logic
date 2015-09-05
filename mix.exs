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
    [{:entice_entity, github: "entice/entity", ref: "ae1686cdfc819e18d6f7fcd741096d60bd906fe0"},
     {:entice_skill, github: "entice/skill", ref: "5b083e0f1f9c91b803aaa651a71a48a42989dace"},
     {:uuid, "~> 1.0"},
     {:inflex, "~> 1.0"}]
  end
end
