defmodule Entice.Logic.SkillBarTest do
  use ExUnit.Case, async: true
  alias Entice.Entity
  alias Entice.Logic.Skills
  alias Entice.Logic.SkillBar

  setup do
    {:ok, entity_id, _pid} = Entity.start
    {:ok, [entity_id: entity_id]}
  end


  test "change skill", %{entity_id: eid} do
    SkillBar.register(eid)
    empty_skills = %SkillBar{}

    assert [0,0,0,0,0,0,0,0] = SkillBar.get_skills(eid)
    assert {:ok, ^empty_skills} = Entity.fetch_attribute(eid, SkillBar)

    new_skill = Skills.get_skill(1)
    new_skills = %SkillBar{slots: [new_skill | empty_skills.slots |> tl]}

    assert [1,0,0,0,0,0,0,0] = SkillBar.change_skill(eid, 0, new_skill.id)
    assert {:ok, ^new_skills} = Entity.fetch_attribute(eid, SkillBar)
  end


  test "get skill", %{entity_id: eid} do
    SkillBar.register(eid, [1,2,3,4,0,0,0,313373])

    assert Skills.HealingSignet = SkillBar.get_skill(eid, 0)
    assert Skills.Bamph = SkillBar.get_skill(eid, 3)
    assert Skills.NoSkill = SkillBar.get_skill(eid, 4)
    assert Skills.NoSkill = SkillBar.get_skill(eid, 7)
  end
end
