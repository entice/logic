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
    [{:entice_entity, github: "entice/entity", ref: "a73dccbe415acdfa960876925aa2a8168194f8ed"},
     {:entice_skill, github: "entice/skill", ref: "df66becfdfa24dad4b7f09f03954328bb4d12ccc"},
     {:uuid, "~> 1.0"},
     {:inflex, "~> 1.0"}]
  end
end
