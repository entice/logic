defmodule Entice.Logic.SkillBar do
  alias Entice.Entity
  alias Entice.Skills
  alias Entice.Logic.SkillBar


  defstruct slots: List.duplicate(Skills.NoSkill, 8)


  def register(entity), do: Entity.put_attribute(entity, %SkillBar{})


  def register(entity, skill_ids) when is_list(skill_ids),
  do: Entity.put_attribute(entity, from_skill_ids(skill_ids))


  def unregister(entity),
  do: Entity.remove_attribute(entity, SkillBar)


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


  defp from_skill_ids(skill_ids) when is_list(skill_ids) do
    %SkillBar{slots:
      skill_ids |> Enum.map(fn skill_id ->
        Skills.get_skill(skill_id)
      end)}
  end


  defp to_skill_ids(%SkillBar{slots: skills}),
  do: skills |> Enum.map(fn skill -> skill.id end)
end
