defmodule Entice.Logic.Seek do
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

  #TODO: Add map instance to all map instance agents
  #TODO: Add team attr to determine who should be attacked by whom
  defmodule Behaviour do
    use Entice.Entity.Behaviour

    def init(entity, %{aggro_distance: aggro_distance, escape_distance: escape_distance}),
    do: {:ok, entity |> put_attribute(%Seek{aggro_distance: aggro_distance, escape_distance: escape_distance})}

    def init(entity, _args),
    do: {:ok, entity |> put_attribute(%Seek{})}

    def handle_event({:movement_agent_updated,  
        %Entity{attributes: %{Position => %Position{pos: mover_pos, plane: _}}} = other_entity},
        %Entity{attributes: %{Position => %Position{pos: my_pos, plane: _}, 
                              Movement => _,
                              Npc      => %Npc{npc_model_id: _, init_pos: init_pos},
                              Seek     => %Seek{aggro_distance: aggro_distance, escape_distance: escape_distance, target: target}}} = entity) do
      unless other_entity == entity do
        case target do
          nil ->
            if calc_distance(my_pos, mover_pos) < aggro_distance do              
              {:ok, entity |> update_attribute(Seek, fn(s) -> %Seek{s | target: other_entity} end)
                           |> update_attribute(Movement, fn(m) -> %Movement{m | goal: mover_pos} end) }
            end            
            
          ^other_entity ->
            current_distance = calc_distance(my_pos, mover_pos)
            entity = cond do
              current_distance >= escape_distance -> 
                entity 
                |> update_attribute(Seek, fn(s) -> %Seek{s | target: nil} end)
                |> update_attribute(Movement, fn(m) -> %Movement{m | goal: init_pos} end)
              true ->
                entity
                |> update_attribute(Movement, fn(m) -> %Movement{m | goal: mover_pos} end)          
            end
            {:ok, entity}

          _ -> {:ok, entity}
        end
      end      
      {:ok, entity}
    end

    def terminate(_reason, entity),
    do: {:ok, entity |> remove_attribute(Seek)}

    #TODO: Should probably move to Coord in Utils
    defp calc_distance(%Coord{x: x1, y: y1}, %Coord{x: x2, y: y2}) do
      :math.sqrt(:math.pow((x2-x1), 2) + :math.pow((y2-y1), 2))
    end
  end
end
