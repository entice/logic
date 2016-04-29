defmodule Entice.Logic.SkillBar do
  alias Entice.Entity
  alias Entice.Logic.{Skills, SkillBar}


  @skillbar_slots 8


  defstruct slots: List.duplicate(Skills.NoSkill, @skillbar_slots)


  def register(entity), do: register(entity, %SkillBar{})

  def register(entity, skill_ids) when is_list(skill_ids),
  do: register(entity, from_skill_ids(skill_ids))

  def register(entity, %SkillBar{} = skillbar),
  do: Entity.put_attribute(entity, skillbar)


  def unregister(entity),
  do: Entity.remove_attribute(entity, SkillBar)


  # External API


  def get_skill(entity, slot) do
    case Entity.fetch_attribute(entity, SkillBar) do
      {:ok, %SkillBar{slots: slots}} -> Enum.at(slots, slot, Skill.NoSkill)
      _                              -> Skills.NoSkill
    end
  end


  def get_skills(entity) do
    case Entity.fetch_attribute(entity, SkillBar) do
      {:ok, %SkillBar{} = skillbar} -> to_skill_ids(skillbar)
      _                             -> []
    end
  end


  def change_skill(entity, slot, skill_id) when is_number(skill_id),
  do: change_skill(entity, slot, Skills.get_skill(skill_id))

  def change_skill(entity, slot, skill) when not is_nil(skill) and is_atom(skill) do
    new_skillbar = Entity.get_and_update_attribute(entity, SkillBar,
      fn skillbar ->
        %SkillBar{slots: skillbar.slots |> List.replace_at(slot, skill)}
      end)
    to_skill_ids(new_skillbar)
  end


  # Internal


  defp to_skill_ids(%SkillBar{slots: skills}),
  do: skills |> Enum.map(fn skill -> skill.id end)


  defp from_skill_ids(skill_ids) when is_list(skill_ids) and length(skill_ids) <= @skillbar_slots do
    %SkillBar{slots:
      skill_ids
      |> skillbar_trunc_or_fill
      |> Enum.map(fn skill_id -> Skills.get_skill(skill_id) end)
      |> Enum.map(
          fn nil   -> Skills.NoSkill
             skill -> skill
          end)}
  end


  defp skillbar_trunc_or_fill(skill_ids) when is_list(skill_ids) and length(skill_ids) < @skillbar_slots,
  do: skillbar_trunc_or_fill(skill_ids ++ [0])

  defp skillbar_trunc_or_fill(skill_ids) when is_list(skill_ids) and length(skill_ids) > @skillbar_slots,
  do: skillbar_trunc_or_fill(skill_ids |> List.delete_at(-1))

  defp skillbar_trunc_or_fill(skill_ids) when is_list(skill_ids),
  do: skill_ids
end
