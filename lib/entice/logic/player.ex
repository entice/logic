defmodule Entice.Logic.Player do
  @moduledoc """
  Responsible for the basic player stats.
  """
  alias Entice.Entity
  alias Entice.Utils.Geom.Coord
  alias Entice.Logic.Area


  defmodule Name, do: defstruct(
    name: "Unknown Entity")

  defmodule Position, do: defstruct(
    pos: %Coord{})

  defmodule MapInstance, do: defstruct(
    map: Area.default_map)

  defmodule Appearance, do: defstruct(
    profession: 1,
    campaign: 0,
    sex: 1,
    height: 0,
    skin_color: 3,
    hair_color: 0,
    hairstyle: 7,
    face: 30)


  @doc """
  Prepares a single, simple player
  """
  def register(entity, map, name \\ "Unkown Entity", appearance \\ %Appearance{}) do
    entity |> Entity.put_attribute(%Name{name: name})
    entity |> Entity.put_attribute(%Position{pos: map.spawn})
    entity |> Entity.put_attribute(%MapInstance{map: map})
    entity |> Entity.put_attribute(appearance)
  end


  def unregister(entity) do
    entity |> Entity.remove_attribute(Name)
    entity |> Entity.remove_attribute(Position)
    entity |> Entity.remove_attribute(MapInstance)
    entity |> Entity.remove_attribute(Appearance)
  end


  def attributes(entity) do
    %{Name        => entity |> Entity.get_attribute(Name),
      Position    => entity |> Entity.get_attribute(Position),
      MapInstance => entity |> Entity.get_attribute(MapInstance),
      Appearance  => entity |> Entity.get_attribute(Appearance)}
  end


  def set_appearance(entity, %Appearance{} = new_appear),
  do: entity |> Entity.set_attribute(new_appear)
end
