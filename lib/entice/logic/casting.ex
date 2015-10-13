defmodule Entice.Logic.Casting do
  @moduledoc """
  This handles the casting process of arbitrary skills.
  Does not validate if an entity has the skills unlocked or w/e.
  Keeps a timer for casting, and an association from
  skill -> recharge-timer.

  You can pass in a listener PID or nil, and you will get notified
  of the following events:

      {:skill_casted,           %{entity_id: entity, skill: skill, target_entity_id: target}}
      {:skill_cast_interrupted, %{entity_id: entity, skill: skill, target_entity_id: target, reason: reason}}
      {:skill_recharged,        %{entity_id: entity, skill: skill}}
      {:after_cast_delay_ended, %{entity_id: entity}}
  """
  use Pipe
  alias Entice.Logic.Casting
  alias Entice.Logic.Vitals.Energy
  alias Entice.Entity


  @after_cast_delay 250


  defstruct(
    cast_timer: nil,
    after_cast_timer: nil,
    recharge_timers: %{})


  def register(entity_id),
  do: Entity.put_behaviour(entity_id, Casting.Behaviour, %Casting{})


  def unregister(entity_id),
  do: Entity.remove_behaviour(entity_id, Casting)


  @doc "Deals with timing and thus might fail. Should be called by the Skillbar"
  def cast_skill(entity, skill, target, report_to_pid \\ nil) when is_atom(skill) and is_pid(report_to_pid),
  do: Entity.call_behaviour(entity, Casting.Behaviour, {:casting_cast_start, report_to_pid, %{target: target, skill: skill}})


  @doc "Is there a better way to export this value out of this module?"
  def after_cast_delay, do: @after_cast_delay


  defmodule Behaviour do
    use Entice.Entity.Behaviour


    def init(entity, %Casting{} = casting),
    do: {:ok, entity |> put_attribute(casting)}


    def handle_call(
        {:casting_cast_start, report_to_pid, %{target: target, skill: skill}},
        %Entity{attributes: %{
          Casting => %Casting{},
          Energy => %Energy{mana: mana}}} = entity) do

      response = can_cast?(skill, entity)
      entity = case response do
        {:ok, _} ->
          timer = cast_start(skill.cast_time, skill, target, report_to_pid)
          entity
          |> update_attribute(Casting, fn c -> %Casting{c | cast_timer: timer} end)
          |> reduce_mana(mana - skill.energy_cost)
        _ -> entity
      end

      {:ok, response, entity}
    end


    def handle_call(event, entity), do: super(event, entity)


    @doc "This event triggers when the cast ends, it resets the casting timer, calls the skill's callback, and triggers recharge_end after a while."
    def handle_event({:casting_cast_end, skill, target, report_to_pid}, entity) do
      recharge_timer = recharge_start(skill.recharge_time, skill, report_to_pid)
      after_cast_timer = after_cast_start(Entice.Logic.Casting.after_cast_delay, report_to_pid)

      skill.apply_effect(target, entity)
      |> handle_cast_result(entity, skill)
      |> case do
        {:error, reason} ->
          if report_to_pid, do: report_to_pid |> send {:skill_cast_interrupted, %{entity_id: entity.id, skill: skill, target_entity_id: target, reason: reason}}
          {:ok, entity}

        {:ok, new_entity} ->
          if report_to_pid, do: report_to_pid |> send {:skill_casted, %{entity_id: entity.id, skill: skill, target_entity_id: target}}
          {:ok, new_entity |> update_attribute(Casting,
            fn c ->
              %Casting{c |
                cast_timer: nil,
                after_cast_timer: after_cast_timer,
                recharge_timers: c.recharge_timers |> Map.put(skill, recharge_timer)}
            end)}
      end
    end


    @doc "This event triggers when a skill's recharge period ends, it resets the recharge timer for the skill."
    def handle_event({:casting_recharge_end, skill, report_to_pid}, entity) do
      if report_to_pid, do: report_to_pid |> send {:skill_recharged, %{entity_id: entity.id, skill: skill}}
      {:ok, entity |> update_attribute(Casting, fn c -> %Casting{c | recharge_timers: c.recharge_timers |> Map.delete(skill)} end)}
    end


    def handle_event({:casting_after_cast_end, report_to_pid}, entity) do
      if report_to_pid, do: report_to_pid |> send {:after_cast_delay_ended, %{entity_id: entity.id}}
      {:ok, entity |> update_attribute(Casting, fn c -> %Casting{c | after_cast_timer: nil} end)}
    end


    def terminate(_reason, entity),
    do: {:ok, entity |> remove_attribute(Casting)}


    # Internal


    defp reduce_mana(entity, new_mana),
    do: entity |> update_attribute(Energy, fn e -> %Energy{e | mana: new_mana} end)


    defp cast_start(cast_time, skill, target, report_to_pid),
    do: start_timer({:casting_cast_end, skill, target, report_to_pid}, cast_time)


    defp recharge_start(recharge_time, skill, report_to_pid),
    do: start_timer({:casting_recharge_end, skill, report_to_pid}, recharge_time)


    defp after_cast_start(after_cast_time, report_to_pid),
    do: start_timer({:casting_after_cast_end, report_to_pid}, after_cast_time)


    defp start_timer(message, time), do: self |> Process.send_after(message, time)


    defp can_cast?(skill,  %Entity{attributes: %{
      Casting => %Casting{cast_timer: cast_timer, after_cast_timer: after_cast_timer, recharge_timers: recharge_timers},
      Energy => %Energy{mana: mana}}} = _entity) do

      case skill.cast_time do
        cast_time when cast_time == 0 ->
          pipe_matching {:ok, _},
          {:ok, skill}
          |> enough_energy?(mana - skill.energy_cost)
          |> not_recharging?(recharge_timers[skill])
        _cast_time ->
          pipe_matching {:ok, _},
          {:ok, skill}
          |> enough_energy?(mana - skill.energy_cost)
          |> not_recharging?(recharge_timers[skill])
          |> not_casting?(cast_timer, after_cast_timer)
      end
    end


    defp enough_energy?({:ok, skill}, mana) when mana > 0, do: {:ok, skill}
    defp enough_energy?({:ok, _skill}, _mana), do: {:error, :not_enough_energy}


    defp not_recharging?({:ok, skill}, nil = _recharge_timer), do: {:ok, skill}
    defp not_recharging?(_skill, _recharge_timer), do: {:error, :still_recharging}


    defp not_casting?({:ok, skill}, nil = _cast_timer, nil = _after_cast_timer), do: {:ok, skill}
    defp not_casting?(_skill, _cast_timer, _after_cast_timer), do: {:error, :still_casting}


    defp handle_cast_result({:ok, %Entity{} = entity}, entity, _skill),                              do: {:ok, entity}
    defp handle_cast_result({:ok, %Entity{id: id} = entity}, %Entity{id: id} = _old_entity, _skill), do: {:ok, entity}
    defp handle_cast_result({:error, reason}, _old_entity, _skill),                                  do: {:error, reason}

    defp handle_cast_result(result, _old_entity, skill),
    do: raise "Corrupted result after applying effect of skill #{skill.underscore_name}. Got: #{result} - should be {:ok, new_entity_state} or {:error, reason}"
  end
end
