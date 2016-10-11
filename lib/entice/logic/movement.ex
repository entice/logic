defmodule Entice.Logic.Movement do
  alias Entice.Entity
  alias Entice.Utils.Geom.Coord
  alias Entice.Logic.{Movement, Player.Position}


  @update_interval 50


  @doc """
  Note that velocity is actually a coefficient for the real velocity thats used inside
  the client, but for simplicities sake we used velocity as a name.
  """
  defstruct goal: %Coord{}, plane: 1, move_type: 9, velocity: 1.0, auto_updating?: false


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

    def handle_event(:movement_calculate_next,
      %Entity{attributes: %{Movement => %Movement{auto_updating?: auto_updating?}}} = entity) do
      #TODO: implement once the whole collision business is handled
      if auto_updating?, do: self |> Process.send_after(:movement_calculate_next, Movement.update_interval)
      {:ok, entity}
    end

    def terminate(_reason, entity),
    do: {:ok, entity |> remove_attribute(Movement)}
  end
end
