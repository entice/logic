defmodule Entice.Logic.Vitals do
  @moduledoc """
  Responsible for the entities vital stats like (health, mana, regen, degen)
  """
  alias Entice.Entity
  alias Entice.Logic.Vitals


  defmodule Health, do: defstruct(
    health: 500, max_health: 620)


  defmodule Energy, do: defstruct(
    mana: 50, max_mana: 70)


  def register(entity_id),
  do: Entity.put_behaviour(entity_id, Vitals.Behaviour, [])


  def unregister(entity_id),
  do: Entity.remove_behaviour(entity_id, Vitals.Behaviour)


  defmodule Behaviour do
    use Entice.Entity.Behaviour
    alias Entice.Logic.Vitals.Health
    alias Entice.Logic.Vitals.Energy
    alias Entice.Logic.Player.Level


    def init(entity, _args) do
      {:ok, entity |> put_attribute(get_max_health(entity))
                   |> put_attribute(get_max_energy(entity))}

    end


    def terminate(_reason, entity) do
      {:ok, entity |> remove_attribute(Health)
                   |> remove_attribute(Energy)}
    end


    # internal


    defp get_max_health(entity) do
      {:ok, level} = fetch_attribute(entity, Level)
      health = calc_life_points_for_level(level.level)
      %Health{health: health, max_health: health}
    end


    #TODO: Take care of Armor, Runes, Weapons...
    defp calc_life_points_for_level(level),
    do: 100 + ((level - 1) * 20) # Dont add 20 lifePoints for level1


    #TODO: Take care of Armor, Runes, Weapons...
    defp get_max_energy(_entity),
    do: %Energy{mana: 70, max_mana: 70}
  end
end
