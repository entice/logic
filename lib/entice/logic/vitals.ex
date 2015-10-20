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

  defmodule Morale, do: defstruct(
    morale: 0)


  def register(entity_id),
  do: Entity.put_behaviour(entity_id, Vitals.Behaviour, [])


  def unregister(entity_id),
  do: Entity.remove_behaviour(entity_id, Vitals.Behaviour)

  #External API
  def damage(entity, amount) do

  end

  defmodule Behaviour do
    use Entice.Entity.Behaviour
    alias Entice.Logic.Vitals.Health
    alias Entice.Logic.Vitals.Energy
    alias Entice.Logic.Vitals.Morale
    alias Entice.Logic.Player.Level


    def init(entity, _args) do
      {:ok, entity |> put_attribute(get_max_health(entity))
                   |> put_attribute(get_max_energy(entity))
                   |> put_attribute(%Morale{morale: 0})}
    end

    def init(entity, [:entity_resurrected, percent_health, percent_energy]) do
      {_, max_health: max_health} = get_max_health(entity)
      resurrected_health = max_health / 100 * percent_health

      {_, max_mana: max_mana} = get_max_energy(entity)
      resurrected_mana = max_mana / 100 * percent_energy

      {:ok, entity |> update_attribute(Health, fn _ -> %Health{health: resurrected_health, max_health: max_health} end)
                   |> update_attribute(Energy, fn _ -> %Energy{mana: resurrected_mana, max_mana: max_mana} end)}
    end

    def termiante(:remove_handler, entity) do
      {:ok, entity}
    end

    def terminate(_reason, entity) do
      {:ok, entity |> remove_attribute(Health)
                   |> remove_attribute(Energy)}
    end

    def handle_event({:vitals_entity_damage, amount}, %Entity{id: id, attributes: %{Health => %Health{health: health, max_health: max_health}}} = entity) do
      new_health = health - amount
      cond do
        new_health <= 0 -> {:become, Vitals.DeadBehaviour, [], entity |> update_attribute(Health, fn health -> %Health{health: 0, max_health: health.max_health} end)}
        new_health > 0 -> {:ok, entity |> update_attribute(Health, fn health -> %Health{health: new_health, max_health: health.max_health} end)}
      end
    end

    def handle_event({:vitals_entity_heal, ammount}, %Entity{id: id} = entity) do
      {:ok, %Health{health: health, max_health: max_health}} = fetch_attribute(entity, Health)
      #case health + ammount = new_health do
        #new_health >= max_health -> Entity.update_attribute(entity, Health, fn health -> %Health{health: health.max_health, health.max_health} end)
      #end
    end

    # internal

    defp get_max_health(entity) do
      {:ok, level} = fetch_attribute(entity, Level)
      {:ok, morale} = fetch_attribute(entity, Morale)
      health = calc_life_points_for_level(level.level)
      max_health_with_morale = health / 100 * (100 + morale.morale)
      %Health{health: health, max_health: health}
    end

    #TODO: Take care of Armor, Runes, Weapons...
    defp calc_life_points_for_level(level),
    do: 100 + ((level - 1) * 20) # Dont add 20 lifePoints for level1


    #TODO: Take care of Armor, Runes, Weapons...
    defp get_max_energy(_entity) do
      %Energy{mana: 70, max_mana: 70}
    end
  end

  defmodule DeadBehaviour do
    use Entice.Entity.Behaviour
    alias Entice.Logic.Vitals.Morale

      def handle_event({:vitals_entity_died}, %Entity{attributes: %{Morale => %Morale{morale: morale}}} = entity) do
        if(morale > -60) do
          new_morale = morale - (-15)
        end
        {:ok, entity |> update_attribute(Morale, fn morale -> %Morale{morale: new_morale} end)}
      end

      def handle_event({:vitals_entity_resurrected, health_points, energy_points}, %Entity{attributes: %{Health => %Health{health: health, max_health: max_health}, Energy=> %Energy{mana: energy, max_mana: energy}}} = entity) do
        {:become, Vitals.Behaviour, [:entity_resurrected, health_points, energy_points], entity}
      end
  end
end