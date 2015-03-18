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
    [{:entice_entity, github: "entice/entity", ref: "05846160142df4d8c20b19b5aca55b9ba748d973"},
     {:entice_skill, github: "entice/skill", ref: "894687cb4e5d08494084621745841243296caaf6"},
     {:uuid, "~> 0.1.5"},
     {:inflex, "~> 0.2.5"}]
  end
end
