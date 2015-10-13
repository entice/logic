defmodule Entice.Logic.SkillsTest do
  use Entice.Logic.Skill
  use Entice.Logic.Attributes
  use ExUnit.Case, async: true
  alias Entice.Entity
  alias Entice.Entity.Attribute
  alias Entice.Entity.Test.Spy


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

    def apply_effect(id, %Entity{id: id, attributes: %{TestAttr => %TestAttr{test_pid: pid}}} = caster) do
      send pid, :gotcha
      {:ok, caster}
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

  test "skill after-cast-time effects" do
    entity = %Entity{attributes: %{TestAttr => %TestAttr{test_pid: self}}}
    SomeOtherSkill.apply_effect(entity.id, entity)
    assert_receive :gotcha
  end


  # effects


  test "damage effect" do
    {:ok, eid, _pid} = Entity.start_plain()
    Attribute.register(eid)
    Attribute.put(eid, %Health{})
    Spy.register(eid)

    %Health{health: health} = Entity.get_attribute(eid, Health)

    damage(eid, 10)
    assert_receive %{sender: ^eid, event: _}

    %Health{health: health_after_damage} = Entity.get_attribute(eid, Health)
    assert health_after_damage == (health - 10)
  end
end
