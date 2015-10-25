defmodule Entice.Logic.Vitals do
  @moduledoc """
  Responsible for the entities vital stats like (health, mana, regen, degen)
  """
  alias Entice.Entity
  alias Entice.Logic.Vitals
  alias Entice.Entity.Coordination

  defmodule Health, do: defstruct(
    health: 500, max_health: 620)

  defmodule Energy, do: defstruct(
    mana: 50, max_mana: 70)

  defmodule Morale, do: defstruct(
    morale: 0)

  def register(entity_id),
  do: Entity.put_behaviour(entity_id, Vitals.AliveBehaviour, [])


  def unregister(entity_id) do
    Entity.remove_behaviour(entity_id, Vitals.AliveBehaviour)
    Entity.remove_behaviour(entity_id, Vitals.DeadBehaviour)
  end

  # External API

  @doc """
  Used to make damage on a Entity
  Damage is applied to the Entity
  Entity can die
  """
  def damage(entity, amount),
  do: Coordination.notify({:vitals_entity_damage, ammount}, entity)

  @doc """
  Heals a entity with the given amount
  Health of Entity is recalculated
  """
  def heal(entity, amount),
  do: Coordination.notify({:vitals_entity_heal, ammount}, entity)

  @doc """
  Resurrects an entity with a Percentage of Life Points and Energy
  New Health and Energy is dependent of Morale
  """
  def resurrect(entity, percent_health, percent_energy),
  do: Coordination.notify({:vitals_entity_resurrect, percent_health, percent_energy}, entity)

  defmodule AliveBehaviour do
    use Entice.Entity.Behaviour
    alias Entice.Logic.Vitals.Health
    alias Entice.Logic.Vitals.Energy
    alias Entice.Logic.Vitals.Morale
    alias Entice.Logic.Player.Level

    def init(%Entity{attributes: %{Level => %Level{level: _}}} = entity, {:entity_resurrected, percent_health, percent_energy}) do
      {_, max_health: max_health} = get_max_health(entity)
      resurrected_health = max_health / 100 * percent_health

      {_, max_mana: max_mana} = get_max_energy(entity)
      resurrected_mana = max_mana / 100 * percent_energy

      {:ok, entity |> update_attribute(Health, fn _ -> %Health{health: resurrected_health, max_health: max_health} end)
                   |> update_attribute(Energy, fn _ -> %Energy{mana: resurrected_mana, max_mana: max_mana} end)}
    end

    def init(%Entity{attributes: %{Level => %Level{level: _}}} = entity, _args) do
      {:ok, entity |> put_attribute(get_max_health(entity))
                   |> put_attribute(get_max_energy(entity))
                   |> put_attribute(%Morale{morale: 0})}
    end

    def terminate(:remove_handler, entity) do
      {:ok, entity}
    end

    def terminate(_reason, entity) do
      {:ok, entity |> remove_attribute(Health)
                   |> remove_attribute(Energy)
                   |> remove_attribute(Morale)}
    end

    def handle_event({:vitals_entity_damage, amount}, %Entity{attributes: %{Health => %Health{health: health, max_health: _}}} = entity) do
      new_health = health - amount
      cond do
        new_health <= 0 -> {:become, Vitals.DeadBehaviour, {entity, :vitals_entity_died}, entity |> update_attribute(Health, fn health -> %Health{health: 0, max_health: health.max_health} end)}
        new_health > 0 -> {:ok, entity |> update_attribute(Health, fn health -> %Health{health: new_health, max_health: health.max_health} end)}
      end
    end

    def handle_event({:vitals_entity_heal, amount}, %Entity{} = entity) do
      {:ok, %Health{health: health, max_health: max_health}} = fetch_attribute(entity, Health)
      new_health = health + amount
      if new_health > max_health do
        new_health = max_health
      end

      {:ok, entity |> update_attribute(Health, fn _ -> %Health{health: new_health, max_health: max_health} end)}
    end

    # internal

    defp get_max_health(entity) do
      {:ok, level} = fetch_attribute(entity, Level)
      {:ok, morale} = fetch_attribute(entity, Morale)
      health = calc_life_points_for_level(level.level)
      max_health_with_morale = health / 100 * (100 + morale.morale)
      %Health{health: max_health_with_morale, max_health: max_health_with_morale}
    end

    #TODO: Take care of Armor, Runes, Weapons...
    defp calc_life_points_for_level(level),
    do: 100 + ((level - 1) * 20) # Dont add 20 lifePoints for level1

    #TODO: Take care of Armor, Runes, Weapons...
    defp get_max_energy(entity) do
      {:ok, morale} = fetch_attribute(entity, Morale)
      inital_mana = 70
      mana_with_morale = inital_mana / 100 * (100 + morale.morale)
      %Energy{mana: mana_with_morale, max_mana: inital_mana}
    end
  end

  defmodule DeadBehaviour do
    use Entice.Entity.Behaviour
    alias Entice.Logic.Vitals.Morale

    def init(%Entity{attributes: %{Morale => %Morale{morale: morale}}} = entity, :vitals_entity_died) do
      if(morale > -60) do
        new_morale = morale - 15
      end

      {:ok, entity |> update_attribute(Morale, fn _ -> %Morale{morale: new_morale} end)}
    end

    def handle_event({:vitals_entity_resurrect, percent_health, percent_energy}, %Entity{attributes: %{Health => %Health{health: _, max_health: _}, Energy=> %Energy{mana: _, max_mana: _}}} = entity) do
      {:become, Vitals.AliveBehaviour, {:entity_resurrected, percent_health, percent_energy}, entity}
    end
  end
end