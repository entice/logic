defmodule Entice.Logic.Casting do
  alias Entice.Logic.Casting
  alias Entice.Logic.Player.Energy
  alias Entice.Entity.Coordination


  def register(entity_id),
  do: Entity.put_behaviour(entity_id, Casting.Behaviour, [])


  def unregister(entity_id),
  do: Entity.remove_behaviour(entity_id, Casting.Behaviour)


  @doc "Will not deal with timing. Should be called by the Skillbar"
  def cast_skill(entity, target, skill),
  do: entity |> Coordination.notify({:skill_cast_start, %{target: target, skill: skill}})


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
