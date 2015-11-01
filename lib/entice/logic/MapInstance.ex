defmodule Entice.Logic.MapInstance do
  alias Entice.Entity
  alias Entice.Logic.MapInstance

  defstruct(
    players: [],
    npcs: [],
    map: nil)

  def register(entity, map),
  do: Entity.put_behaviour(entity, MapInstance.Behaviour, map)

  def unregister(entity),
  do: Entity.remove_behaviour(entity, MapInstance.Behaviour)

  defmodule Behaviour do
    use Entice.Entity.Behaviour

    def init(entity, map),
    do: {:ok, entity |> put_attribute(%MapInstance{map: map})}

    def handle_call({:map_instance_player_join, player}, entity) when is_pid(player) do
      add_creature_to_map_instance(entity, player, :players)
    end

    def handle_call({:map_instance_npc_join, npc}, entity) when is_pid(npc) do
      add_creature_to_map_instance(entity, npc, :npcs)
    end

    def handle_call({:map_instance_player_leave, player}, entity) when is_pid(player) do
      {:ok, entity, empty} = remove_creature_from_map_instance(entity, player, :players)
      case empty do
        false -> {:ok, entity}
        _ -> {:stop, :normal, entity}
      end
    end

    def handle_call({:map_instance_npc_leave, npc}, entity) when is_pid(npc) do
      {:ok, entity, _} = remove_creature_from_map_instance(entity, npc, :npcs)
      {:ok, entity}
    end

    def handle_call(event, entity), do: super(event, entity)

    def terminate(_reason, entity) do
      {:ok, entity |> remove_attribute(MapInstance)}
    end

    defp add_creature_to_map_instance(%Entity{attributes: %{MapInstance => map_instance}} = entity, creature, creature_key) do
      creatures = Map.get(map_instance, creature_key)
      case Enum.member?(creatures, creature) do
        false ->
          map_instance = map_instance |> Map.update(creature_key, [creature], fn(crtrs) -> [crtrs | creature] end)
          {:ok, entity |> update_attribute(MapInstance, fn(attrs) -> attrs |> Map.update(MapInstance, map_instance, fn(_) -> map_instance end) end)}
        _ -> {:error, entity}
      end
    end

    defp remove_creature_from_map_instance(%Entity{attributes: %{MapInstance => map_instance}} = entity, creature, creature_key) do
      creatures = Map.get(map_instance, creature_key)
      map_instance = map_instance |> Map.update(creature_key, creatures, fn(ctrs) -> ctrs |> List.delete(creature) end)
      entity = entity |> update_attribute(MapInstance, fn(attrs) -> attrs |> Map.update(MapInstance, map_instance, fn(_) -> map_instance end) end)
      empty = creatures == [creature]
      {:ok, entity, empty}
    end
  end
end
