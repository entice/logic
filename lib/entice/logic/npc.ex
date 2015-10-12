defmodule Entice.Logic.Npc do
  use Entice.Logic.Area
  alias Entice.Entity
  alias Entice.Logic.Player.Name
  alias Entice.Logic.Player.Position
  alias Entice.Logic.Player.MapInstance
  alias Entice.Logic.Player.Level
  alias Entice.Logic.Npc


  defstruct(npc_model_id: :dhuum)


  # TODO remove when we have maps
  @doc "Temporarily here. Should be replaced by map-based implementation... load from DB?"
  def spawn_all do
    for map <- Area.get_maps do
      {:ok, id, _pid} = Entity.start()
      Npc.register(id, map, "Me does nothing :3")
      Vitals.register(id)
    end
    :ok
  end


  def register(entity, map, name \\ "Dhuum", npc \\ %Npc{}) do
    entity |> Entity.attribute_transaction(fn (attrs) ->
      attrs
      |> Map.put(Name, %Name{name: name})
      |> Map.put(Position, %Position{pos: map.spawn})
      |> Map.put(MapInstance, %MapInstance{map: map})
      |> Map.put(Npc, npc)
      |> Map.put(Level, %Level{level: 20})
    end)
  end


  def unregister(entity) do
    entity |> Entity.attribute_transaction(fn (attrs) ->
      attrs
      |> Map.delete(Name)
      |> Map.delete(Position)
      |> Map.delete(MapInstance)
      |> Map.delete(Npc)
      |> Map.delete(Level)
    end)
  end


  def attributes(entity),
  do: Entity.take_attributes(entity, [Name, Position, MapInstance, Level, Npc])
end
