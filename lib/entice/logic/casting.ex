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
  use Pipe


  defstruct(
    casting_timer: nil,  #Why not call this cast_timer if skill has a cast_time ? or vice versa
    after_cast_timer: nil,
    recharge_timers: %{})

  def register(entity_id),
  do: Entity.put_behaviour(entity_id, Casting.Behaviour, %Casting{})

  def unregister(entity_id),
  do: Entity.remove_behaviour(entity_id, Casting)

  @doc "Deals with timing and thus might fail. Should be called by the Skillbar"
  def cast_skill(entity, skill) when is_atom(skill),
  do: Entity.call_behaviour(entity, Casting.Behaviour, {:cast_start, nil, nil, %{target: nil, skill: skill}})

  def cast_skill(entity, target, skill) when is_atom(skill),
  do: Entity.call_behaviour(entity, Casting.Behaviour, {:cast_start, nil, nil, %{target: target, skill: skill}})


  defmodule Behaviour do
    use Entice.Entity.Behaviour

    def init(entity, %Casting{} = casting),
    do: {:ok, entity |> put_attribute(casting)}

    def terminate(_reason, entity),
    do: {:ok, entity |> remove_attribute(Casting)}

    def handle_call({:cast_start, cast_callback, recharge_callback, %{target: _target, skill: skill}}, %Entity{attributes: %{
      Casting => %Casting{recharge_timers: _recharge_timers},
      Energy => %Energy{mana: mana}}} = entity) do

      response = can_cast?(skill, entity)
      entity = case response do
        {:ok, _} ->
          entity
          |> reduce_mana(mana - skill.energy_cost)
          #Starts the casting_timer
          timer = cast_start(skill.cast_time, skill, cast_callback, recharge_callback)
          entity |> update_attribute(Casting, fn c -> %Casting{c | casting_timer: timer} end)
        _ -> entity
      end

      {:ok, response, entity}
    end

    def handle_call(event, entity), do: super(event, entity)

    @doc "This event triggers when the cast ends, it resets the casting timer, calls the skill's callback, and triggers recharge_end after a while."
    def handle_event({:cast_end, skill, cast_callback, recharge_callback}, entity) do
      #cast_callback.(skill)
      timer = recharge_start(skill.recharge_time, skill, recharge_callback)
      recharge_timers = Map.update(entity.Casting.recharge_timers, skill, timer)
      {:ok, entity |> update_attribute(Casting, fn c -> %Casting{c | casting_timer: nil, recharge_timers: c.recharge_timers  |> Map.put(skill, skill.recharge_time)} end)}
    end

    @doc "This event triggers when a skill's recharge period ends, it resets the recharge timer for the skill."
    def handle_event({:recharge_end, skill, _recharge_callback}, entity) do
      recharge_timers = Map.remove(entity.Casting.recharge_timers, skill)
      {:ok, entity |> update_attribute(Casting, fn c -> %Casting{c | recharge_timers: recharge_timers} end)}
    end

    def handle_event({:after_cast_end}, entity) do
      {:ok, entity |> update_attribute(Casting, fn c -> %Casting{c | after_cast_timer: nil} end)}
    end

    defp reduce_mana(entity, new_mana) do
      Entity.update_attribute(entity, Energy, fn e -> %Energy{e | mana: new_mana} end)
    end

    #EVENT TRIGGERS

    #Waits for #cast_time milliseconds then triggers the cast_end event.
    defp cast_start(cast_time, skill, cast_callback, recharge_callback)  do #We take cast_time as arg rather than use skill.cast_time in case we want to modify it before
      self |> Process.send_after({:cast_end, skill, cast_callback, recharge_callback}, cast_time)
    end

    #Waits for #recharge_time milliseconds then triggers the recharge_end event.
    defp recharge_start(recharge_time, skill, recharge_callback) do
      self |> Process.send_after({:recharge_end, skill, recharge_callback}, recharge_time)
    end

    defp after_cast_start(after_cast_time) do
      self |> Process.send_after({:after_cast_end}, after_cast_time)
    end

    #CAST CONDITIONS
    defp enough_energy?({:ok, skill}, dmana) when dmana > 0, do: {:ok, skill}
    defp enough_energy?({:ok, _skill}, _dmana), do: {:error, :not_enough_energy}

    defp not_recharging?({:ok, skill}, nil = _recharge_timer), do: {:ok, skill}
    defp not_recharging?(_skill, _recharge_timer), do: {:error, :still_recharging}

    defp not_casting?({:ok, skill}, nil = _casting_timer, nil = _after_cast_timer), do: {:ok, skill}
    defp not_casting?(_skill, _casting_timer, _after_cast_timer), do: {:error, :still_casting}

    defp can_cast?(skill,  %Entity{attributes: %{
      Casting => %Casting{casting_timer: casting_timer, after_cast_timer: after_cast_timer, recharge_timers: recharge_timers},
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
          |> not_casting?(casting_timer, after_cast_timer)
      end
    end

  end
end
