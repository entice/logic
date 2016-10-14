defmodule Entice.Logic.Seek do
  alias Entice.Entity
  alias Entice.Logic.{Seek, Player.Position, Npc, Movement}
  alias Geom.Shape.{Path, Vector}
  alias Geom.Ai.Astar

  defstruct target: nil, aggro_distance: 1000, escape_distance: 2000, path: []

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
            {:ok, entity |> return_to_spawn(my_coord, init_coord)}
          else
            {:ok, entity |> seek_target_current_coord(moving_entity_id, mover_coord)}
          end

        _ -> {:ok, entity}
      end
    end

    def terminate(_reason, entity),
    do: {:ok, entity |> remove_attribute(Seek)}

    defp in_aggro_range?(my_coord, mover_coord, aggro_distance),
    do: Vector.dist(my_coord, mover_coord) <= aggro_distance

    defp past_escape_range?(init_coord, mover_coord, escape_distance),
    do: Vector.dist(init_coord, mover_coord) >= escape_distance

    defp seek_target_current_coord(%Entity{attributes: %{Position => %Position{coord: my_coord},
      Npc => %Npc{map: map}, Seek => %Seek{path: path}}} = entity, target_id, target_coord) do
      {success, result} = Astar.get_path(map.nav_mesh, my_coord, target_coord)

      %Path{vertices: new_path} = case success do
        :ok -> result

        :error -> Path.empty
      end

      entity |> update_attribute(Seek, fn(s) -> %Seek{s | target: target_id, path: new_path} end)
    end

    defp return_to_spawn(%Entity{attributes: %{Npc => %Npc{map: map}}} = entity, my_coord, spawn_coord) do
      {success, result} = Astar.get_path(map.nav_mesh, my_coord, spawn_coord)

      %Path{vertices: new_path} = case success do
        :ok -> result

        :error -> Path.empty
      end

      entity |> update_attribute(Seek, fn(s) -> %Seek{s | target: nil, path: new_path} end)
    end
  end
end
