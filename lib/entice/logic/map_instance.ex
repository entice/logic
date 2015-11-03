defmodule Entice.Logic.MapInstance do
  alias Entice.Entity
  alias Entice.Entity.Coordination
  alias Entice.Entity.Suicide
  alias Entice.Logic.MapInstance
  alias Entice.Logic.Npc
  alias Entice.Logic.Player.Appearance
  alias Entice.Logic.Player.Position


  defstruct(players: 0, map: nil)


  def register(entity, map) do
    Suicide.unregister(entity) # maps will kill themselfes on their own
    Entity.put_behaviour(entity, MapInstance.Behaviour, map)
  end


  def unregister(entity) do
    Suicide.register(entity)
    Entity.remove_behaviour(entity, MapInstance.Behaviour)
  end


  def add_player(entity, player_entity),
  do: Coordination.notify(entity, {:map_instance_player_add, player_entity})


  def add_npc(entity, name, model, %Position{} = position) when is_binary(name) and is_atom(model),
  do: Coordination.notify(entity, {:map_instance_npc_add, %{name: name, model: model, position: position}})


  defmodule Behaviour do
    use Entice.Entity.Behaviour

    def init(entity, map),
    do: {:ok, entity |> put_attribute(%MapInstance{map: map})}


    def handle_event(
        {:map_instance_player_add, player_entity},
        %Entity{attributes: %{MapInstance => %MapInstance{map: map, players: players}}} = entity) do
      Coordination.register(player_entity, map) # TODO change map to something else if we have multiple instances
      {:ok, entity |> update_attribute(MapInstance, fn(m) -> %MapInstance{m | players: players+1} end)}
    end

    def handle_event(
        {:map_instance_npc_add, %{name: name, model: model, position: position}},
        %Entity{attributes: %{MapInstance => %MapInstance{map: map}}} = entity) do
      {:ok, id, pid} = Npc.spawn(map, name, model, position)
      Coordination.register(pid, map) # TODO change map to something else if we have multiple instances
      {:ok, entity}
    end

    def handle_event(
        {:entity_leave, %{attributes: %{Appearance => _}}} = event,
        %Entity{attributes: %{MapInstance => %MapInstance{map: map, players: players}}} = entity) do
      new_entity = entity |> update_attribute(MapInstance, fn instance -> %MapInstance{instance | players: players-1} end)
      case players-1 do
        count when count <= 0 ->
          Coordination.notify_all(map, Suicide.poison_pill_message) # this is why we deactivate our suicide behaviour
          Coordination.stop_channel(map)
          {:stop_process, :normal, new_entity}
        _ -> {:ok, new_entity}
      end
    end


    def terminate(_reason, entity) do
      {:ok, entity |> remove_attribute(MapInstance)}
    end


    defp stop_all_entities(map) do
      entity_ids = Coordination.notify_all(map, Suicide.poison_pill_message)
    end
  end
end
