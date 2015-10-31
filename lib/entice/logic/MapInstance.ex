defmodule Entice.Logic.MapInstance do
  alias Entice.Entity
  alias Entice.Logic.MapInstance
  alias Entice.Logic.Npc


  defstruct(
    players: [],
    npcs: [], #TODO: Figure out if we want the npcs ot be able to join&leave or stay there even if dead or unspawned
    map: nil)

  def register(entity, map),
  do: Entity.put_behaviour(entity, MapInstance.Behaviour, map)

  def unregister(entity),
  do: Entity.remove_behaviour(entity, MapInstance.Behaviour)

  defmodule Behaviour do
    use Entice.Entity.Behaviour

    def init(entity, map),
    do: {:ok, entity |> put_attribute(%MapInstance{map: map})}

    def handle_call({:map_instance_player_join, player_entity}, %Entity{attributes: %{MapInstance => map_instance}} = entity) do
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

    def handle_call({:map_instance_player_leave, player_entity}, %Entity{attributes: %{MapInstance => map_instance}} = entity) do
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

    def handle_call({:map_instance_npc_join, npc_entity}, %Entity{attributes: %{MapInstance => map_instance}} = entity) do
      npcs = Map.get(map_instance, :npcs)
      case Enum.member?(npcs, npc_entity) do
        false ->
          {:ok, entity |> update_attribute(MapInstance, fn(attrs) ->
            attrs
            |> Map.update(MapInstance, :npcs, [npc_entity], fn(npcs) -> [npcs | npc_entity] end)
          end)}
        _ -> {:error, entity}
      end
    end

    def handle_call({:map_instance_npc_leave, npc_entity}, %Entity{attributes: %{MapInstance => map_instance}} = entity) do
      npcs = Map.get(map_instance, :npcs)
      entity = entity |> update_attribute(MapInstance, fn(attrs) ->
          attrs
          |> Map.update(MapInstance, :npcs, [], fn(npcs) -> npcs |> List.delete(npc_entity) end)
        end)
      case npcs do
        [^npc_entity] -> {:stop, :normal, entity}
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
