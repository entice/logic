defmodule Entice.Logic.Movement do
  alias Entice.Entity
  alias Entice.Logic.{Movement, Player.Position, Seek}
  alias Geom.Shape.{Vector, Vector2D}

  @update_interval 50
  @speed 288 #TODO: Figure out the velocity/speed naming business
  @epsilon 10

  @doc """
  Note that velocity is actually a coefficient for the real velocity thats used inside
  the client, but for simplicities sake we used velocity as a name.
  """
  defstruct goal: %Vector2D{x: 0, y: 0}, plane: 1, move_type: 9, velocity: 1.0, auto_updating?: false


  def register(entity),
  do: Entity.put_behaviour(entity, Movement.Behaviour, [])

  def register(entity, auto_updating?: auto_updating?),
  do: Entity.put_behaviour(entity, Movement.Behaviour, auto_updating?: auto_updating?)

  def unregister(entity),
  do: Entity.remove_behaviour(entity, Movement.Behaviour)


  def update(entity,
      %Position{} = new_pos,
      %Movement{} = new_movement) do
    entity |> Entity.attribute_transaction(
      fn attrs ->
        attrs
        |> Map.put(Position, new_pos)
        |> Map.put(Movement, new_movement)
      end)
  end

  def update_interval, do: @update_interval
  def speed, do: @speed
  def epsilon, do: @epsilon


  defmodule Behaviour do
    use Entice.Entity.Behaviour

    def init(%Entity{attributes: %{Movement => _}} = entity, _args),
    do: {:ok, entity}

    def init(%Entity{attributes: %{Position => %Position{coord: coord, plane: plane}}} = entity, auto_updating?: true) do
      self |> Process.send_after(:movement_calculate_next, 1)
      {:ok, entity |> put_attribute(%Movement{goal: coord, plane: plane, auto_updating?: true})}
    end

    def init(%Entity{attributes: %{Position => %Position{coord: coord, plane: plane}}} = entity, _args),
    do: {:ok, entity |> put_attribute(%Movement{goal: coord, plane: plane})}

    def init(entity, _args),
    do: {:ok, entity |> put_attribute(%Movement{})}

    #TODO: Move all this logic to seek
    def handle_event(:movement_calculate_next,
      %Entity{attributes: %{Movement => %Movement{velocity: velocity, auto_updating?: auto_updating?, goal: goal},
                            Seek => %Seek{path: path},
                            Position => %Position{coord: current_pos}}} = entity) do
      #Determine next goal
      {entity, goal} = case Enum.count(path) do
        0 ->
          {entity, goal} #Empty path

        1 ->
          {entity, goal} #Path only has starting pos left

        _ ->
          cond do
            Vector.equal(goal, current_pos, Movement.epsilon) -> #Reached goal
              new_goal = Enum.at(path, 1) #len path >= 2 so we know next is not nil
              entity = entity
                       |> update_attribute(Movement, fn(m) -> %Movement{m | goal: new_goal} end)
                       |> update_attribute(Seek, fn(s) -> %Seek{s | path: Enum.drop(path, 1)} end)
              {entity, new_goal}

            true ->
              {entity, goal}
          end
      end

      #Advance pos if not at new (or unchanged) goal
      next_pos = cond do
        Vector.equal(goal, current_pos, Movement.epsilon) ->
          current_pos

        true ->
          {:ok, next_pos} = calc_next_pos(current_pos, goal, velocity)
          next_pos
      end

      entity = entity |> update_attribute(Position, fn(p) -> %Position{p | coord: next_pos} end)
      if auto_updating?, do: self |> Process.send_after(:movement_calculate_next, Movement.update_interval)
      {:ok, entity}
    end

    defp calc_next_pos(%Vector2D{} = current_pos, %Vector2D{} = goal, velocity) do
      direction = Vector.sub(goal, current_pos)
      cond do
        #Convoluted cond because somehow %Vector2D{x: 0, y: 0} != %Vector2D{x: 0.0, y: 0.0} in case
        Vector.equal(direction, %Vector2D{x: 0, y: 0}, 0) ->
          {:ok, current_pos}

        true ->
          unit = Vector.unit(direction)
          offset = Vector.mul(unit, velocity * Movement.speed * Movement.update_interval / 1000)
          {:ok, Vector.add(current_pos, offset)}
      end
    end

    defp calc_next_pos(_,_,_), do: {:error, :wrong_arguments}

    def terminate(_reason, entity),
    do: {:ok, entity |> remove_attribute(Movement)}
  end
end
