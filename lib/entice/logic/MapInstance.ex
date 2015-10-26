defmodule Entice.Logic.MapInstance do
  alias Entice.Entity
  alias Entice.Logic.MapInstance


  defstruct(
    players: [],
    npcs: [],
    map: nil)

  def join(entity, player_entity) do
    Entity.call_behaviour(entity, MapInstance.Behaviour, {:map_instance_entity_join, player_entity})
  end

  def leave(entity, player_entity) do
    Entity.call_behaviour(entity, MapInstance.Behaviour, {:map_instance_entity_leave, player_entity})
  end

  def register(entity, map, players=[], npc_info=[]),
  do: Entity.put_behaviour(entity, MapInstance.Behaviour, map, players, npc_info)

  def register(entity, map_instance),
  do: Entity.put_behaviour(entity, MapInstance.Behaviour, map_instance)

  def unregister(entity),
  do: Entity.remove_behaviour(entity, MapInstance.Behaviour)

  defmodule Behaviour do
    use Entice.Entity.Behaviour

    def init(entity, map, players, npc_info) do
      npcs = for %{name: name, model: model} <- npc_info do
        Npc.spawn(name, model) #TODO: Implement in Npc
      end
      map_instance = %MapInstance{players: players, npcs: npcs, map: map}
      init(entity, map_instance)
    end

    @doc "Inits a new MapInstance behaviour, assumes npcs have been spawned prior."
    def init(entity, %MapInstance{} = map_instance),
    do: {:ok, entity |> put_attribute(map_instance)}

    def handle_call({:map_instance_entity_join, player_entity}, entity) do
      {:ok, map_instance} = fetch_attribute(entity, MapInstance)
      players = Map.get(map_instance, :players)
      case Enum.member?(players, player_entity) do
        false ->
          {:ok, entity |> update_attribute(MapInstance, fn(attrs) ->
            attrs
            |> Map.update(MapInstance, :players, [player_entity], fn(players) -> [players | player_entity] end)
          end)}
        _ -> {:error, entity}
      end
    end

    def handle_call({:map_instance_entity_leave, player_entity}, entity) do
      {:ok, map_instance} = fetch_attribute(entity, MapInstance)
      players = Map.get(map_instance, :players)
      entity = entity |> update_attribute(MapInstance, fn(attrs) ->
          attrs
          |> Map.update(MapInstance, :players, [], fn(players) -> players |> List.delete(player_entity) end)
        end)
      case players do
        [^player_entity] -> {:stop, :normal, entity}
        _ -> {:ok, entity}
      end
    end

    def handle_call(event, entity), do: super(event, entity)

    def terminate(_reason, entity) do
      {:ok, map_instance} = fetch_attribute(entity, MapInstance)
      npcs = map_instance |> Map.get(:npcs)
      for npc <- npcs, do: Npc.unregister(npc)
      {:ok, entity |> remove_attribute(MapInstance)}
    end
  end
end
