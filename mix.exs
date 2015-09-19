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
    [{:entice_entity, github: "entice/entity", ref: "f1d4a05d191e7ed8cc276a404381e900b0c0aec4"},
     {:entice_skill, github: "entice/skill", ref: "c0d52488e7a578f9dd5370e4873d99bd2c54eb15"},
     {:uuid, "~> 1.0"},
     {:inflex, "~> 1.0"}]
  end
end
