defmodule Entice.Logic.Movement do
  use Entice.Logic.Attributes
  alias Entice.Entity
  alias Entice.Logic.Movement.MovementBehaviour

  def init(entity_id),
  do: Entity.put_behaviour(entity_id, MovementBehaviour, [])


  def change_speed(entity_id, new_speed),
  do: Entity.notify(entity_id, {:speed, new_speed})


  def change_move_type(entity_id, new_type),
  do: Entity.notify(entity_id, {:movetype, new_type})


  def change_goal(entity_id, new_goal),
  do: Entity.notify(entity_id, {:goal, new_goal})


  def remove(entity_id),
  do: Entity.remove_behaviour(entity_id, MovementBehaviour)


  defmodule MovementBehaviour do
    use Entice.Entity.Behaviour

    def init(id, %{Movement => _} = attributes, _args),
    do: {:ok, attributes, %{entity_id: id}}

    def init(id, %{Position => %Position{pos: pos}} = attributes, _args),
    do: {:ok, Map.put(attributes, Movement, %Movement{goal: pos}), %{entity_id: id}}

    def init(id, attributes, _args),
    do: {:ok, Map.put(attributes, Movement, %Movement{}), %{entity_id: id}}


    def hande_event({:speed, new_speed}, %{Movement => move} = attributes, state),
    do: {:ok, Map.put(attributes, Movement, %Movement{move | speed: new_speed}), state}


    def hande_event({:movetype, new_type}, %{Movement => move} = attributes, state),
    do: {:ok, Map.put(attributes, Movement, %Movement{move | movetype: new_type}), state}


    def hande_event({:goal, new_goal}, %{Movement => move} = attributes, state),
    do: {:ok, Map.put(attributes, Movement, %Movement{move | goal: new_goal}), state}


    def terminate(_reason, attributes, state),
    do: {:ok, Map.delete(attributes, Movement)}
  end
end
