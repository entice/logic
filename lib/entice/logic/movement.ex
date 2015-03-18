defmodule Entice.Logic.Movement do
  alias Entice.Entity
  alias Entice.Utils.Geom.Coord
  alias Entice.Logic.Movement
  alias Entice.Logic.Player.Position


  @doc """
  Note that velocity is actually a coefficient for the real velocity thats used inside
  the client, but for simplicities sake we used velocity as a name.
  """
  defstruct goal: %Coord{}, plane: 1, movetype: 9, velocity: 1.0


  def register(entity),
  do: Entity.put_behaviour(entity, Movement.Behaviour, [])


  def unregister(entity),
  do: Entity.remove_behaviour(entity, Movement.Behaviour)


  def change_goal(entity, new_goal, new_plane),
  do: Entity.update_attribute(entity, Movement, fn move -> %Movement{move | goal: new_goal, plane: new_plane} end)


  def change_move_type(entity, new_type, new_velocity),
  do: Entity.update_attribute(entity, Movement, fn move -> %Movement{move | movetype: new_type, velocity: new_velocity} end)


  defmodule Behaviour do
    use Entice.Entity.Behaviour

    def init(%Entity{attributes: %{Movement => _}} = entity, _args),
    do: {:ok, entity}

    def init(%Entity{attributes: %{Position => %Position{pos: pos}}} = entity, _args),
    do: {:ok, entity |> put_attribute(%Movement{goal: pos})}

    def init(entity, _args),
    do: {:ok, entity |> put_attribute(%Movement{})}


    def terminate(_reason, entity),
    do: {:ok, entity |> remove_attribute(Movement)}
  end
end
