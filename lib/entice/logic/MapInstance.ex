defmodule Entice.Logic.MapInstance do
  alias Entice.Entity
  alias Entice.Entity.Coordination
  alias Entice.Logic.MapInstance
  alias Entice.Logic.Npc

  defstruct(
    players: 0,
    map: nil)

  def register(entity, map),
  do: Entity.put_behaviour(entity, MapInstance.Behaviour, map)

  def unregister(entity),
  do: Entity.remove_behaviour(entity, MapInstance.Behaviour)

  def add_npc(entity, %{name: name}),
  do: Entity.call_behaviour(entity, MapInstance.Behaviour, {:map_instance_npc_add, %{name: name}})

  def add_player(entity, player_pid),
  do: Entity.call_behaviour(entity, MapInstance.Behaviour, {:map_instance_player_join, player_pid})

  defmodule Behaviour do
    use Entice.Entity.Behaviour

    def init(entity, map) do
      {:ok, entity |> put_attribute(%MapInstance{map: map})}
    end

    def handle_call({:map_instance_player_join, player_entity_id}, %Entity{attributes: %{MapInstance => %MapInstance{map: map, players: players}}} = entity) do
      Coordination.register(player_entity_id, map)
      {:ok, "Player added", entity |> update_attribute(MapInstance, fn(m) -> %MapInstance{m | players: players+1} end)}
    end

    def handle_call({:map_instance_npc_add, %{name: name}}, %Entity{attributes: %{MapInstance => %MapInstance{map: map}}} = entity) do
      {:ok, id, pid} = Npc.spawn(map, name)
      Coordination.register(pid, map)
      {:ok, {"Npc added", id, pid}, entity}
    end

    def handle_call(event, entity), do: super(event, entity)

    def handle_event({:entity_leave, %{entity_id: _, attributes: %{Appearance => _}}},
      %Entity{attributes: %MapInstance{map: map, players: players}} = entity) do
      IO.ps "sadafe"
      entity = entity |> update_attribute(MapInstance, fn(m) -> %MapInstance{m | players: players-1} end)
      case players-1 do
        0 ->
          stop_all_entities(map) #Should I stop coordination as well?
          {:stop, :normal, entity}
        number when number < 0 ->
          stop_all_entities(map)
          {:stop, :error, entity}
        _ -> {:ok, entity}
      end
    end

    def terminate(_reason, entity) do
      {:ok, entity |> remove_attribute(MapInstance)}
    end

    defp stop_all_entities(map) do
      entity_ids = Coordination.get_entity_ids(map)
      for eid <- entity_ids do
        Entity.stop(eid)
      end
    end
  end
end
