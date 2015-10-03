defmodule Entice.Logic.SkillsTest do
  use Entice.Logic.Skill
  use ExUnit.Case, async: true
  alias Entice.Entity


  defmodule TestAttr, do: defstruct test_pid: nil


  defskill SomeSkill, id: 1 do
    def description,   do: "Is some skill."
    def cast_time,     do: 5000
    def recharge_time, do: 10000
    def energy_cost,   do: 10
  end

  defskill SomeOtherSkill, id: 2 do
    def description,   do: "Is some other skill."
    def cast_time,     do: 5000
    def recharge_time, do: 10000
    def energy_cost,   do: 10

    def effect_cast_start(
        %Entity{id: id, attributes: %{TestAttr => %TestAttr{test_pid: pid}}},
        %Entity{id: id}) do
      send pid, :gotcha
    end

    def effect_cast_finish(
        %Entity{id: id, attributes: %{TestAttr => %TestAttr{test_pid: pid}}},
        %Entity{id: id}) do
      send pid, :gotcha
    end
  end


  test "the skill's id" do
    assert SomeSkill.id == 1
    assert SomeOtherSkill.id == 2
  end

  test "the skill's name" do
    assert SomeSkill.name == "SomeSkill"
  end

  test "the skill's underscore name" do
    assert SomeSkill.underscore_name == "some_skill"
  end

  test "retrieveing skills by id" do
    assert get_skill(1) == SomeSkill
    assert get_skill(2) == SomeOtherSkill
  end

  test "retrieveing skills by name" do
    assert get_skill("SomeSkill") == SomeSkill
    assert get_skill("SomeOtherSkill") == SomeOtherSkill
  end

  test "retrieve all skills" do
    assert SomeSkill in get_skills
  end

  test "bit-array (as int) that contains all skill-ids as set bits" do
    assert 3 == max_unlocked_skills
  end

  test "skill cast-time effects" do
    entity = %Entity{attributes: %{TestAttr => %TestAttr{test_pid: self}}}
    SomeOtherSkill.effect_cast_start(entity, entity)
    assert_receive :gotcha
  end

  test "skill after-cast-time effects" do
    entity = %Entity{attributes: %{TestAttr => %TestAttr{test_pid: self}}}
    SomeOtherSkill.effect_cast_finish(entity, entity)
    assert_receive :gotcha
  end
end
