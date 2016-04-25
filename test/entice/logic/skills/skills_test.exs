defmodule Entice.Logic.SkillsTest do
  use Entice.Logic.Skill
  use Entice.Logic.Attributes
  use ExUnit.Case, async: true
  alias Entice.Entity
  alias Entice.Entity.Attribute
  alias Entice.Logic.Vitals


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

    def apply_effect(pid, pid) do
      send pid, :gotcha
      :ok
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
    SomeOtherSkill.apply_effect(self, self)
    assert_receive :gotcha
  end

  # prerequisites

  test "target is dead prerequisite" do
    {:ok, eid, _pid} = Entity.start_plain()
    Attribute.register(eid)
    Vitals.register(eid)

    assert {:error, :target_not_dead} == target_dead?(eid)

    Vitals.kill(eid)
    :timer.sleep(100)
    assert Entity.has_behaviour?(eid, Vitals.DeadBehaviour)
    
    assert :ok == target_dead?(eid)
  end


  # effects


  test "damage effect" do
    {:ok, eid, _pid} = Entity.start_plain()
    Attribute.register(eid)
    Vitals.register(eid)

    %Health{health: health} = Entity.get_attribute(eid, Health)

    damage(eid, 10)

    %Health{health: health_after_damage} = Entity.get_attribute(eid, Health)
    assert health_after_damage == (health - 10)
  end


  test "healing effect" do
    {:ok, eid, _pid} = Entity.start_plain()
    Attribute.register(eid)
    Vitals.register(eid)

    %Health{health: health} = Entity.get_and_update_attribute(eid, Health, fn health -> %Health{health | health: health.health - 20} end)

    heal(eid, 10)

    %Health{health: health_after_heal} = Entity.get_attribute(eid, Health)
    assert health_after_heal == (health + 10)
  end


  test "resurrection effect" do
    {:ok, eid, _pid} = Entity.start_plain()
    Attribute.register(eid)
    Vitals.register(eid)

    Vitals.kill(eid)
    :timer.sleep(100)
    assert Entity.has_behaviour?(eid, Vitals.DeadBehaviour)

    resurrect(eid, 50, 50)
    :timer.sleep(100)
    assert Entity.has_behaviour?(eid, Vitals.AliveBehaviour)
  end
end
