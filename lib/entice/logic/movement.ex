defmodule Entice.Logic.Movement do
  alias Entice.Entity
  alias Entice.Utils.Geom.Coord
  alias Entice.Logic.{Movement, Player.Position}


  @doc """
  Note that velocity is actually a coefficient for the real velocity thats used inside
  the client, but for simplicities sake we used velocity as a name.
  """
  defstruct goal: %Coord{}, plane: 1, move_type: 9, velocity: 1.0, update_self: false, update_delay: 1


  def register(entity),
  do: Entity.put_behaviour(entity, Movement.Behaviour, [])


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


  defmodule Behaviour do
    use Entice.Entity.Behaviour

    def init(%Entity{attributes: %{Movement => _}} = entity, _args),
    do: {:ok, entity}

    def init(%Entity{attributes: %{Position => %Position{coord: coord, plane: plane}}} = entity, _args),
    do: {:ok, entity |> put_attribute(%Movement{goal: coord, plane: plane})}

    def init(entity, _args),
    do: {:ok, entity |> put_attribute(%Movement{})}

    def handle_event({:movement_calculate_next},
      %Entity{attributes: %{Movement => %Movement{update_self: update_self, update_delay: update_delay}}} = _entity) do
      #TODO: implement once the whole collision business is handled
      if update_self, do: start_update_trigger_timer(:movement_calculate_next, update_delay)
    end

    def terminate(_reason, entity),
    do: {:ok, entity |> remove_attribute(Movement)}

    defp start_update_trigger_timer(message, time) do
      if time == 0 do
        self |> send(message)
        nil
      else
        self |> Process.send_after(message, time)
      end
    end
  end
end
