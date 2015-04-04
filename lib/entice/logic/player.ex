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

  defmodule Health, do: defstruct(
    health: 500)

  defmodule Energy, do: defstruct(
    mana: 50)


  @doc "Prepares a single, simple player"
  def register(entity, map, name \\ "Unkown Entity", appearance \\ %Appearance{}) do
    entity |> Entity.attribute_transaction(fn (attrs) ->
      attrs
      |> Map.put(Name, %Name{name: name})
      |> Map.put(Position, %Position{pos: map.spawn})
      |> Map.put(MapInstance, %MapInstance{map: map})
      |> Map.put(Appearance, appearance)
      |> Map.put(Health, %Health{})
      |> Map.put(Energy, %Energy{})
    end)
  end


  @doc "Removes all player attributes from the entity"
  def unregister(entity) do
    entity |> Entity.attribute_transaction(fn (attrs) ->
      attrs
      |> Map.delete(Name)
      |> Map.delete(Position)
      |> Map.delete(MapInstance)
      |> Map.delete(Appearance)
      |> Map.delete(Health)
      |> Map.delete(Energy)
    end)
  end


  @doc "Returns all player related attributes as an attribute map"
  def attributes(entity) do
    %{Name        => entity |> Entity.get_attribute(Name),
      Position    => entity |> Entity.get_attribute(Position),
      MapInstance => entity |> Entity.get_attribute(MapInstance),
      Appearance  => entity |> Entity.get_attribute(Appearance),
      Health      => entity |> Entity.get_attribute(Health),
      Energy      => entity |> Entity.get_attribute(Energy)}
  end


  def set_appearance(entity, %Appearance{} = new_appear),
  do: entity |> Entity.set_attribute(new_appear)
end