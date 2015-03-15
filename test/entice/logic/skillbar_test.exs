defmodule Entice.Logic.SkillBarTest do
  use ExUnit.Case
  alias Entice.Entity
  alias Entice.Skills
  alias Entice.Logic.SkillBar


  setup do
    {:ok, _id, pid} = Entity.start
    SkillBar.register(pid)
    {:ok, [entity: pid]}
  end


  test "change skill", %{entity: pid} do
    empty_skills = %SkillBar{}

    assert [0,0,0,0,0,0,0,0] = SkillBar.get_skills(pid)
    assert {:ok, ^empty_skills} = Entity.fetch_attribute(pid, SkillBar)

    new_skill = Skills.get_skill(1)
    new_skills = %SkillBar{slots: [new_skill | empty_skills.slots |> tl]}

    assert [1,0,0,0,0,0,0,0] = SkillBar.change_skill(pid, 0, new_skill.id)
    assert {:ok, ^new_skills} = Entity.fetch_attribute(pid, SkillBar)
  end
end
