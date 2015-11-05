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
    [{:entice_entity, github: "entice/entity", ref: "38193450aa007f797e01cf7779eaa332175f060c"},
     {:uuid, "~> 1.0"},
     {:inflex, "~> 1.5"},
     {:pipe, "~> 0.0.2"}]
  end
end
