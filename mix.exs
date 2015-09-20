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
    [{:entice_entity, github: "entice/entity", ref: "ce9bdc17377c4b11711a324c10f2909a68b697c8"},
     {:entice_skill, github: "entice/skill", ref: "951a82ecbfab5d2cae4fde278b06722cd2a069d7"},
     {:uuid, "~> 1.0"},
     {:inflex, "~> 1.0"}]
  end
end
