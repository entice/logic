defmodule Entice.Logic.SkillBar do
  alias Entice.Entity
  alias Entice.Skills
  alias Entice.Logic.SkillBar


  defstruct(
    slots: List.duplicate(Skills.NoSkill, 8),
    casting_timer: nil)



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


  def cast_skill(entity, slot, callback),
  do: Entity.call(entity, SkillBar.Behaviour, {:skillbar_cast_start, slot, callback})


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
        {:skillbar_cast_start, slot, callback},
        %Entity{attributes: %{SkillBar => %SkillBar{slots: slots, casting_timer: nil}}} = entity) do

      {:ok, skill} = slots |> Enum.fetch(slot)
      new_timer = self |> Process.send_after({:skillbar_cast_end, slot, callback}, skill.cast_time)
      {:ok, {:ok, skill}, entity |> update_attribute(SkillBar, fn s -> %SkillBar{s | casting_timer: new_timer} end)}
    end


    def handle_call(
        {:skillbar_cast_start, _slot, _callback},
        %Entity{attributes: %{SkillBar => %SkillBar{casting_timer: timer}}} = entity)
    when not is_nil(timer) do
      {:ok, {:error, :still_casting}, entity}
    end


    def handle_call(event, entity), do: super(event, entity)


    def handle_event(
        {:skillbar_cast_end, slot, callback},
        %Entity{attributes: %{SkillBar => %SkillBar{slots: slots, casting_timer: timer}}} = entity)
    when not is_nil(timer) do
      {:ok, skill} = slots |> Enum.fetch(slot)
      callback.({:skill_cast_end, skill})
      {:ok, entity |> update_attribute(SkillBar, fn s -> %SkillBar{s | casting_timer: nil} end)}
    end


    def terminate(_reason, entity),
    do: {:ok, entity |> remove_attribute(SkillBar)}
  end
end
