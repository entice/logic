defmodule Entice.Logic.Vitals do
  alias Entice.Entity
  @moduledoc """
  Responsible for the entities vital stats like (health, mana, regen, degen)
  """

  defmodule Health do: defstruct(
    health: 50)

  defmodule Mana do: defstruct(
    mana: 50)

  def register(entity_id),
  do: Entity.put_behaviour(entity_id, Vitals.Behaviour, [])

  def unregister(entity_id),
  do: Entity.remove_behaviour(entity_id, Vitals.Behaviour)

  defmodule Behaviour do
    use Entice.Entity.Behaviour

    def init(entity, _args) do
      entity |> put_attribute(%Health{health: Vitals.Health})
             |> put_attribute(%Energy{mana: Vitals.Mana})
    end

    def terminate(entity, _args) do
      entity |> remove_attribute(Energy)
             |> remove_attribute(Health)
    end
  end
end
