defmodule Entice.Logic.MapInstance do
  alias Entice.Entity
  alias Entice.Logic.MapInstance


  defstruct(players: %{},
    npcs: %{},
    map: nil)

  def start_instance(map, player_entities \\ [], npc_info \\ []) do
    {:ok, id, _pid} = Entity.start()
    npc_entities = for npc = %{name: name, model: model} <- npc_info,
    do: Npc.spawn(name, model) #TODO: Implement in Npc
    MapInstance.register(id, map, player_entities, npc_entities)
  end

  def join(entity, player_entity) do #Player already in players check to be done in web?
    entity |> Entity.update_attribute(MapInstance, fn(attrs) ->
      attrs
      |> Map.update(MapInstance, :players, [player_entity], fn(players) -> [players | player_entity] end)
    end)
  end

  def leave(entity, player_entity) do
    entity |> Entity.update_attribute(MapInstance, fn(attrs) ->
      attrs
      |> Map.update(MapInstance, :players, [], fn(players) -> players |> List.delete(player_entity) end)
    end)
    #Check if players empty here or web?
  end

  def register(entity, map, players, npcs) do
    entity |> Entity.attribute_transaction(fn (attrs) ->
      attrs
      |> Map.put(MapInstance, %MapInstance{players: players, npcs: npcs, map: map})
    end)
  end

  def unregister(entity) do
    entity |> Entity.attribute_transaction(fn (attrs) ->
      attrs
      |> Map.delete(MapInstance)
    end)
  end
end
