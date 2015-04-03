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
    [{:entice_entity, github: "entice/entity", ref: "02765f83b5de23bb93e6b8aa75da7fd93d6e8611"},
     {:entice_skill, github: "entice/skill", ref: "fb2977285588bae2fb5559a641e9cf027cffef2e"},
     {:uuid, "~> 1.0"},
     {:inflex, "~> 1.0"}]
  end
end
