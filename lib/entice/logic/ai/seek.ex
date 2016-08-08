defmodule Entice.Logic.Seek do
  alias Entice.Logic.{Seek, Player.Position}
  alias Entice.Entity.Coordination
  alias Entice.Utils.Geom.Coord

  #TODO: Add old_target so it doesn't reaggro directly
  #TODO: define on register
  defstruct target: nil, aggro_distance: 10, escape_distance: 20

  def register(entity),
  do: Entity.put_behaviour(entity, Seek.Behaviour, [])

  def unregister(entity),
  do: Entity.remove_behaviour(entity, Seek.Behaviour)

  defmodule Behaviour do
    use Entice.Entity.Behaviour

    def init(entity, _args),
    do: {:ok, entity |> put_attribute(%Seek{})}

    def handle_event({:movement_agent_updated,  
        %{player_entity: %Entity{attributes: %{Position => %Position{pos: mover_coord, plane: _}}} = player_entity,
          channel_pid: channel_pid}},
        %Entity{attributes: %{Position => %Position{pos: my_coord, plane: _}, 
                              Seek => %Seek{aggro_distance: aggro_distance, escape_distance: escape_distance, target: target}}} = entity) do
      case target do
        nil ->
          if (calc_distance(my_coord, mover_coord) < aggro_distance) do
            channel_pid  |> send({:follow_target, player_entity})
            {:ok, entity |> update_attribute(Seek, fn(s) -> %Seek{s | target: player_entity} end)}
          end
        ^player_entity -> 
          if (calc_distance(my_coord, mover_coord) > escape_distance) do #TODO: calc distance between current pos and init pos instead
            channel_pid  |> send({:go_to, %Position{pos: %Coord{}, plane: 0}}) #TODO: Add init position for npc
            {:ok, entity |> update_attribute(Seek, fn(s) -> %Seek{s | target: nil} end)}
          end
        _ -> {:ok, entity}
      end
    end

    def terminate(_reason, entity),
    do: {:ok, entity |> remove_attribute(Seek)}

    defp calc_distance(coord1, coord2) do
      #Not sure what %Coord looks like yet
      0
    end
  end
end
