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
  do: Coordination.notify(entity, {:vitals_entity_damage, amount})

  @doc """
  Heals a entity with the given amount
  Health of Entity is recalculated
  """
  def heal(entity, amount),
  do: Coordination.notify(entity, {:vitals_entity_heal, amount})

  @doc """
  Resurrects an entity with a Percentage of Life Points and Energy
  New Health and Energy depends on Morale
  """
  def resurrect(entity, percent_health, percent_energy),
  do: Coordination.notify(entity, {:vitals_entity_resurrect, percent_health, percent_energy})

  defmodule AliveBehaviour do
    use Entice.Entity.Behaviour
    alias Entice.Logic.Vitals.Health
    alias Entice.Logic.Vitals.Energy
    alias Entice.Logic.Vitals.Morale
    alias Entice.Logic.Vitals.DeadBehaviour
    alias Entice.Logic.Player.Level

    def init(%Entity{attributes: %{Level => %Level{}, Morale => %Morale{}}} = entity, {:entity_resurrected, percent_health, percent_energy}) do
      %Health{max_health: max_health} = get_max_health(entity.attributes)
      resurrected_health = round(max_health / 100 * percent_health)

      %Energy{max_mana: max_mana} = get_max_energy(entity.attributes)
      resurrected_mana = round(max_mana / 100 * percent_energy)

      {:ok, entity |> put_attribute(%Health{health: resurrected_health, max_health: max_health})
                   |> put_attribute(%Energy{mana: resurrected_mana, max_mana: max_mana})}
    end

    def init(%Entity{attributes: %{Level => %Level{}}} = entity, _args) do
      {:ok, entity |> put_attribute(%Morale { morale: 0 })
                   |> attribute_transaction(
                      fn attrs ->
                        attrs |> Map.merge(%{
                          Health => get_max_health(attrs),
                          Energy => get_max_energy(attrs)})
                      end)}
    end


    def handle_event({:vitals_entity_damage, amount}, %Entity{attributes: %{Health => %Health{health: health}}} = entity) do
      new_health = health - amount
      cond do
        new_health <= 0 -> {:become, Vitals.DeadBehaviour, :entity_died, entity |> update_attribute(Health, fn health -> %Health{ health | health: 0 } end)}
        new_health > 0 -> {:ok, entity |> update_attribute(Health, fn health -> %Health{ health | health: new_health} end)}
      end
    end

    def handle_event({:vitals_entity_heal, amount}, %Entity{} = entity) do
      {:ok, %Health{health: health, max_health: max_health}} = fetch_attribute(entity, Health)
      new_health = health + amount
      if new_health > max_health do
        new_health = max_health
      end

      {:ok, entity |> update_attribute(Health, fn health -> %Health{ health | health: new_health} end)}
    end


    def terminate({:become_handler, DeadBehaviour, _}, entity) do
      {:ok, entity}
    end

    def terminate(_reason, entity) do
      {:ok, entity |> remove_attribute(Morale)
                   |> remove_attribute(Health)
                   |> remove_attribute(Energy)}
    end


    # Internal


    defp get_max_health(%{Level => %Level{level: level}, Morale => %Morale{morale: morale}}) do
      health = calc_life_points_for_level(level)
      max_health_with_morale = round(health / 100 * (100 + morale))
      %Health{health: max_health_with_morale, max_health: max_health_with_morale}
    end


    #TODO: Take care of Armor, Runes, Weapons...
    defp calc_life_points_for_level(level),
    do: 100 + ((level - 1) * 20) # Dont add 20 lifePoints for level1


    #TODO: Take care of Armor, Runes, Weapons...
    defp get_max_energy(%{Morale => %Morale{morale: morale}}) do
      inital_mana = 70
      mana_with_morale = round(inital_mana / 100 * (100 + morale))
      %Energy{mana: mana_with_morale, max_mana: mana_with_morale}
    end
  end

  defmodule DeadBehaviour do
    use Entice.Entity.Behaviour
    alias Entice.Logic.Vitals.Morale

    def init(%Entity{attributes: %{Morale => %Morale{morale: morale}}} = entity, :entity_died) do
      entity.id |> Coordination.notify_locally({:entity_dead, %{entity_id: entity.id, attributes: entity.attributes}})
      new_morale = morale - 15
      if(new_morale < -60) do #-60 is max negative morale
        new_morale = -60
      end
      {:ok, entity |> put_attribute(%Morale{morale: new_morale})}
    end

    def handle_event({:vitals_entity_resurrect, percent_health, percent_energy}, %Entity{attributes: %{Health => %Health{}, Energy=> %Energy{}}} = entity) do
      {:become, Vitals.AliveBehaviour, {:entity_resurrected, percent_health, percent_energy}, entity}
    end

    def terminate({:become_handler, AliveBehaviour, _}, entity) do
      {:ok, entity}
    end

    def terminate(_reason, entity) do
      {:ok, entity |> remove_attribute(Morale)
                   |> remove_attribute(Health)
                   |> remove_attribute(Energy)}
    end
  end
end
