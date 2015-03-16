defmodule Entice.Logic.SkillBarTest do
  use ExUnit.Case
  alias Entice.Entity
  alias Entice.Skills
  alias Entice.Logic.SkillBar
  alias Entice.Test.Spy


  setup do
    {:ok, entity_id, _pid} = Entity.start
    SkillBar.register(entity_id)
    Spy.register(entity_id, self)
    {:ok, [entity_id: entity_id]}
  end


  test "change skill", %{entity_id: eid} do
    empty_skills = %SkillBar{}

    assert [0,0,0,0,0,0,0,0] = SkillBar.get_skills(eid)
    assert {:ok, ^empty_skills} = Entity.fetch_attribute(eid, SkillBar)

    new_skill = Skills.get_skill(1)
    new_skills = %SkillBar{slots: [new_skill | empty_skills.slots |> tl]}

    assert [1,0,0,0,0,0,0,0] = SkillBar.change_skill(eid, 0, new_skill.id)
    assert {:ok, ^new_skills} = Entity.fetch_attribute(eid, SkillBar)
  end


  test "cast skill", %{entity_id: eid} do
    this = self
    assert :ok = SkillBar.cast_skill(eid, 0, &(send this, &1))

    assert_receive %{sender: ^eid, event: {:skillbar_cast_end,   0, _callback}}
    assert_receive {:skill_cast_end, Skills.NoSkill}
  end


  test "not cast skill when already casting", %{entity_id: eid} do
    assert [1,0,0,0,0,0,0,0] = SkillBar.change_skill(eid, 0, 1) # switch to healing signet

    this = self
    assert :ok                      = SkillBar.cast_skill(eid, 0, &(send this, &1))
    assert {:error, :still_casting} = SkillBar.cast_skill(eid, 0, &(send this, &1))

    assert_receive %{sender: ^eid, event: {:skillbar_cast_end,   0, _callback}}, 2100
    assert_receive {:skill_cast_end, Skills.HealingSignet}
  end
end
