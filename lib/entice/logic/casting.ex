defmodule Entice.Logic.Casting do
  @moduledoc """
  This handles the casting process of arbitrary skills.
  Does not validate if an entity has the skills unlocked or w/e.
  Keeps a timer for casting, and an association from
  skill -> recharge-timer.
  """
  alias Entice.Logic.Casting
  alias Entice.Logic.Vitals.Energy
  alias Entice.Entity
  alias Entice.Entity.Coordination


  defstruct(
    casting_timer: nil,
    after_cast_timer: nil,
    recharge_timers: %{})


  def register(entity_id),
  do: Entity.put_behaviour(entity_id, Casting.Behaviour, [])


  def unregister(entity_id),
  do: Entity.remove_behaviour(entity_id, Casting.Behaviour)


  @doc "Deals with timing and thus might fail. Should be called by the Skillbar"
  def cast_skill(entity, skill) when is_atom(skill),
  do: entity |> Entity.call_behaviour({:skill_cast_start, %{target: nil, skill: skill}})

  def cast_skill(entity, target, skill) when is_atom(skill),
  do: entity |> Entity.call_behaviour({:skill_cast_start, %{target: target, skill: skill}})


  defmodule Behaviour do
    use Entice.Entity.Behaviour

    def handle_call(
        {:skill_cast_start, %{target: target, skill: skill}},
        %Entity{attributes: %{Energy => %Energy{mana: mana}}} = entity) do

      case mana - skill.energy_cost do
        new_mana when new_mana < 0 -> {:ok, {:error, :not_enough_energy}, entity}
        new_mana ->
          case skill.effect_cast_start(entity, target) do
            {:error, reason} -> {:ok, {:error, reason}, entity}
            {:ok, %Entity{} = entity, %Entity{} = target} ->
              target.id |> Entity.attribute_transaction(&Map.merge(&1, target.attributes))
              {:ok, :ok, entity}
            result -> raise "Incorrect skill casting result:\nSkill: #{skill.id}\nResult: #{result}"
          end
      end
    end

    def handle_call(event, entity), do: super(event, entity)
  end
end
