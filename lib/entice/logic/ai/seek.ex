defmodule Entice.Logic.Seek do
  alias Entice.Entity
  alias Entice.Logic.{Seek, Player.Position, Npc, Movement}
  alias Entice.Utils.Geom.Coord

  defstruct target: nil, aggro_distance: 10, escape_distance: 20

  def register(entity),
  do: Entity.put_behaviour(entity, Seek.Behaviour, [])

  def register(entity, aggro_distance, escape_distance)
  when is_integer(aggro_distance) and is_integer(escape_distance),
  do: Entity.put_behaviour(entity, Seek.Behaviour, %{aggro_distance: aggro_distance, escape_distance: escape_distance})

  def unregister(entity),
  do: Entity.remove_behaviour(entity, Seek.Behaviour)

  #TODO: Add team attr to determine who should be attacked by whom
  defmodule Behaviour do
    use Entice.Entity.Behaviour

    def init(entity, %{aggro_distance: aggro_distance, escape_distance: escape_distance}),
    do: {:ok, entity |> put_attribute(%Seek{aggro_distance: aggro_distance, escape_distance: escape_distance})}

    def init(entity, _args),
    do: {:ok, entity |> put_attribute(%Seek{})}

    #No introspection for npcs ;)
    def handle_event({:entity_change, %{entity_id: eid}}, %Entity{id: eid} = entity),
    do: {:ok, entity}

    def handle_event({:entity_change, %{changed: %{Position => %Position{coord: mover_coord}}, entity_id: moving_entity_id}},
      %Entity{attributes: %{Position => %Position{coord: my_coord},
                            Movement => _,
                            Npc      => %Npc{init_coord: init_coord},
                            Seek     => %Seek{aggro_distance: aggro_distance, escape_distance: escape_distance, target: target}}} = entity) do
      case target do
        nil ->
          if in_aggro_range?(my_coord, mover_coord, aggro_distance) do
            {:ok, entity |> seek_target_current_coord(moving_entity_id, mover_coord)}
          else
            {:ok, entity}
          end

        ^moving_entity_id ->
          if past_escape_range?(init_coord, mover_coord, escape_distance) do
            {:ok, entity |> return_to_spawn(init_coord)}
          else
            {:ok, entity |> seek_target_current_coord(moving_entity_id, mover_coord)}
          end

        _ -> {:ok, entity}
      end
    end

    def terminate(_reason, entity),
    do: {:ok, entity |> remove_attribute(Seek)}

    defp in_aggro_range?(my_coord, mover_coord, aggro_distance),
    do: calc_distance(my_coord, mover_coord) < aggro_distance

    defp past_escape_range?(init_coord, mover_coord, escape_distance),
    do: calc_distance(init_coord, mover_coord) >= escape_distance

    defp seek_target_current_coord(entity, target_id, target_coord) do
      entity
      |> update_attribute(Seek, fn(s) -> %Seek{s | target: target_id} end)
      |> update_attribute(Movement, fn(m) -> %Movement{m | goal: target_coord} end)
    end

    defp return_to_spawn(entity, spawn_coord) do
      entity
      |> update_attribute(Seek, fn(s) -> %Seek{s | target: nil} end)
      |> update_attribute(Movement, fn(m) -> %Movement{m | goal: spawn_coord} end)
    end

    #TODO: Should probably move to Coord in Utils
    defp calc_distance(%Coord{x: x1, y: y1}, %Coord{x: x2, y: y2}) do
      :math.sqrt(:math.pow((x2-x1), 2) + :math.pow((y2-y1), 2))
    end
  end
end
