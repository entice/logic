defmodule Entice.Logic.Mixfile do
  use Mix.Project

  def project do
    [app: :entice_logic,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  defp deps do
    [{:entice_entity, github: "entice/entity", ref: "0e6e7848a3fe094193e72de9a06158af6a81dc3d"},
     {:inflex, "~> 0.2.5"}]
  end
end
