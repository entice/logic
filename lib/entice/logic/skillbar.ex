defmodule Entice.Logic.SkillBar do
  alias Entice.Entity
  alias Entice.Skills
  alias Entice.Logic.SkillBar
  alias Entice.Logic.Player.Energy


  defstruct(
    slots: List.duplicate(Skills.NoSkill, 8),
    casting_timer: nil,
    recharge_timers: List.duplicate(nil, 8))



  def register(entity), do: register(entity, %SkillBar{})

  def register(entity, skill_ids) when is_list(skill_ids),
  do: register(entity, from_skill_ids(skill_ids))

  def register(entity, %SkillBar{} = skillbar),
  do: Entity.put_behaviour(entity, SkillBar.Behaviour, skillbar)


  def unregister(entity),
  do: Entity.remove_behaviour(entity, SkillBar)


  # External API


  def get_skills(entity) do
    case Entity.fetch_attribute(entity, SkillBar) do
      {:ok, %SkillBar{} = skillbar} -> to_skill_ids(skillbar)
      _                             -> []
    end
  end


  def change_skill(entity, slot, skill_id) do
    new_skillbar =
      Entity.get_and_update_attribute(entity, SkillBar, fn skillbar ->
        %SkillBar{slots: skillbar.slots |> List.replace_at(slot, Skills.get_skill(skill_id))}
      end)
    to_skill_ids(new_skillbar)
  end


  def cast_skill(entity, slot, cast_callback, recharge_callback),
  do: Entity.call_behaviour(entity, SkillBar.Behaviour, {:skillbar_cast_start, slot, cast_callback, recharge_callback})


  # Internal


  defp from_skill_ids(skill_ids) when is_list(skill_ids) do
    %SkillBar{slots:
      skill_ids |> Enum.map(fn skill_id ->
        Skills.get_skill(skill_id)
      end)}
  end


  defp to_skill_ids(%SkillBar{slots: skills}),
  do: skills |> Enum.map(fn skill -> skill.id end)


  defmodule Behaviour do
    use Entice.Entity.Behaviour


    def init(entity, %SkillBar{} = skillbar),
    do: {:ok, entity |> put_attribute(skillbar)}


    def handle_call(
        {:skillbar_cast_start, slot, cast_callback, recharge_callback},
        %Entity{attributes: %{
          SkillBar => %SkillBar{slots: slots, casting_timer: casting_timer, recharge_timers: recharge_timers},
          Energy => %Energy{mana: mana}}} = entity) do
      {:ok, skill}          = slots |> Enum.fetch(slot)
      {:ok, recharge_timer} = recharge_timers |> Enum.fetch(slot)

      case mana - skill.energy_cost do
        new_mana when new_mana < 0 -> {:ok, {:error, :not_enough_energy}, entity}
        new_mana ->
          {response, new_entity} =
            case skillbar_cast_start(slot, skill, skill.cast_time, casting_timer, recharge_timer, cast_callback, recharge_callback) do
              {:ok, :normal, skill, timer}  -> {{:ok, :normal, skill}, update_entity_on_cast(entity, new_mana, timer, nil, slot)}
              {:ok, :instant, skill, timer} -> {{:ok, :instant, skill}, update_entity_on_cast(entity, new_mana, nil, timer, slot)}
              response                      -> {response, entity}
            end
          {:ok, response, new_entity}
      end
    end

    defp update_entity_on_cast(entity, new_mana, new_cast_timer, new_recharge_timer, slot) do
      entity |> put_attribute(%Energy{mana: new_mana})
                          |> update_attribute(SkillBar, fn s ->
            %SkillBar{s | casting_timer: new_cast_timer, recharge_timers: s.recharge_timers |> List.replace_at(slot, new_recharge_timer)}
          end)
    end

    def handle_call(event, entity), do: super(event, entity)

    def handle_event(
        {:skillbar_cast_end, slot, cast_callback, recharge_callback},
        %Entity{attributes: %{SkillBar => %SkillBar{slots: slots, recharge_timers: recharge_timers}}} = entity) do
      {:ok, skill}          = slots |> Enum.fetch(slot)
      {:ok, recharge_timer} = recharge_timers |> Enum.fetch(slot)

      new_timer = skillbar_recharge_start(slot, skill.recharge_time, recharge_timer, recharge_callback)
      cast_callback.(skill)
      {:ok, entity |> update_attribute(SkillBar, fn s ->
        %SkillBar{s | casting_timer: nil, recharge_timers: s.recharge_timers |> List.replace_at(slot, new_timer)}
      end)}
    end


    def handle_event(
        {:skillbar_recharge_end, slot, recharge_callback},
        %Entity{attributes: %{SkillBar => %SkillBar{slots: slots}}} = entity) do
      {:ok, skill} = slots |> Enum.fetch(slot)
      recharge_callback.(skill)
      {:ok, entity |> update_attribute(SkillBar, fn s ->
        %SkillBar{s | recharge_timers: s.recharge_timers |> List.replace_at(slot, nil)}
      end)}
    end


    def terminate(_reason, entity),
    do: {:ok, entity |> remove_attribute(SkillBar)}


    # internal


    def skillbar_cast_start(slot, skill, 0, nil, nil, _cast_callback, recharge_callback) do
      timer = skillbar_recharge_start(slot, skill.recharge_time, nil, recharge_callback)
      {:ok, :instant, skill, timer}
    end

    def skillbar_cast_start(slot, skill, cast_time, nil, nil, cast_callback, recharge_callback) do
      timer = self |> Process.send_after({:skillbar_cast_end, slot, cast_callback, recharge_callback}, cast_time)
      {:ok, :normal, skill, timer}
    end

    def skillbar_cast_start(_slot, _skill, _cast_time, _casting_timer, nil, _cast_callback, _recharge_callback),
    do: {:error, :still_casting}

    def skillbar_cast_start(_slot, _skill, _cast_time, _casting_timer, _recharge_timer, _cast_callback, _recharge_callback),
    do: {:error, :still_recharging}


    def skillbar_recharge_start(_slot, 0, nil, _recharge_callback), do: nil

    def skillbar_recharge_start(slot, recharge_time, nil, recharge_callback),
    do: self |> Process.send_after({:skillbar_recharge_end, slot, recharge_callback}, recharge_time)

    def skillbar_recharge_start(_slot, _recharge_time, _recharge_timer, _recharge_callback), do: nil
  end
end
