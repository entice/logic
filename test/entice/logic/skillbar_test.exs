defmodule Entice.Logic.SkillBarTest do
  use ExUnit.Case, async: true
  alias Entice.Entity
  alias Entice.Entity.Test.Spy
  alias Entice.Skills
  alias Entice.Logic.SkillBar
  alias Entice.Logic.Player.Energy

  setup do
    {:ok, entity_id, _pid} = Entity.start
    SkillBar.register(entity_id)
    Spy.register(entity_id, self)
    Entity.put_attribute(entity_id, %Energy{mana: 50})
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


  test "cast/recharge skill w/ casttime + rechargetime", %{entity_id: eid} do
    assert [3,0,0,0,0,0,0,0] = SkillBar.change_skill(eid, 0, 3) # switch to signet of capture

    this = self
    assert {:ok, :normal, _skill} = SkillBar.cast_skill(eid, 0, &(send this, &1), &(send this, &1))

    assert_receive %{sender: ^eid, event: {:skillbar_cast_end, 0, _cast_callback, _recharge_callback}}, 2100
    assert_receive Skills.SignetOfCapture

    assert_receive %{sender: ^eid, event: {:skillbar_recharge_end, 0, _callback}}, 2100
    assert_receive Skills.SignetOfCapture
  end


  test "cast/recharge skill w/o casttime w/o rechargetime", %{entity_id: eid} do
    this = self
    assert {:ok, :instant, _skill} = SkillBar.cast_skill(eid, 0, &(send this, &1), &(send this, &1))

    refute_receive %{sender: ^eid, event: {:skillbar_cast_end, 0, _cast_callback, _recharge_callback}}
    refute_receive Skills.NoSkill

    refute_receive %{sender: ^eid, event: {:skillbar_recharge_end, 0, _recharge_callback}}
    refute_receive Skills.NoSkill
  end


  test "cast/recharge skill w casttime w/o rechargetime", %{entity_id: eid} do
    assert [2,0,0,0,0,0,0,0] = SkillBar.change_skill(eid, 0, 2) # switch to resurrection signet

    this = self
    assert {:ok, :normal, _skill} = SkillBar.cast_skill(eid, 0, &(send this, &1), &(send this, &1))

    assert_receive %{sender: ^eid, event: {:skillbar_cast_end, 0, _cast_callback, _recharge_callback}}, 3100
    assert_receive Skills.ResurrectionSignet

    refute_receive %{sender: ^eid, event: {:skillbar_recharge_end, 0, _recharge_callback}}
    refute_receive Skills.ResurrectionSignet
  end


  test "cast/recharge skill w/o casttime w rechargetime", %{entity_id: eid} do
    assert [11,0,0,0,0,0,0,0] = SkillBar.change_skill(eid, 0, 11) # switch to distortion

    this = self
    assert {:ok, :instant, _skill} = SkillBar.cast_skill(eid, 0, &(send this, &1), &(send this, &1))

    refute_receive %{sender: ^eid, event: {:skillbar_cast_end, 0, _cast_callback, _recharge_callback}}
    refute_receive Skills.Distortion

    assert_receive %{sender: ^eid, event: {:skillbar_recharge_end, 0, _recharge_callback}}, 8100
    assert_receive Skills.Distortion
  end


  test "not cast skill when already casting", %{entity_id: eid} do
    assert [3,0,0,0,0,0,0,0] = SkillBar.change_skill(eid, 0, 3) # switch to signet of capture

    this = self
    assert {:ok, :normal, _skill}   = SkillBar.cast_skill(eid, 0, &(send this, &1), &(send this, &1))
    assert {:error, :still_casting} = SkillBar.cast_skill(eid, 0, &(send this, &1), &(send this, &1)) # with casttime > 0
    assert {:error, :still_casting} = SkillBar.cast_skill(eid, 1, &(send this, &1), &(send this, &1)) # with casttime = 0

    assert_receive %{sender: ^eid, event: {:skillbar_cast_end, 0, _cast_callback, _recharge_callback}}, 2100
    assert_receive Skills.SignetOfCapture
  end


  test "not cast same skill when recharging, but others", %{entity_id: eid} do
    assert [6,0,0,0,0,0,0,0] = SkillBar.change_skill(eid, 0, 6) # switch to mantra of earth

    this = self
    assert {:ok, :instant, _skill}     = SkillBar.cast_skill(eid, 0, &(send this, &1), &(send this, &1))
    assert {:error, :still_recharging} = SkillBar.cast_skill(eid, 0, &(send this, &1), &(send this, &1))
    assert {:ok, :instant, _skill}     = SkillBar.cast_skill(eid, 1, &(send this, &1), &(send this, &1))
  end

  test "cast skill with enough energy", %{entity_id: eid} do
    assert [6,0,0,0,0,0,0,0] = SkillBar.change_skill(eid, 0, 6) # switch to mantra of earth

    this = self

    assert {:ok, :instant, _skill} = SkillBar.cast_skill(eid, 0, &(send this, &1), &(send this, &1))
    calculated_mana = 50 - Skills.MantraOfEarth.energy_cost
    assert %Energy{mana: calculated_mana} = Entity.get_attribute(eid, Energy)
  end

  test "not enough energy", %{entity_id: eid} do
    assert [6,0,0,0,0,0,0,0] = SkillBar.change_skill(eid, 0, 6) # switch to mantra of earth

    this = self

    Entity.put_attribute(eid, %Energy{mana: 0})
    assert {:error, :not_enough_energy} = SkillBar.cast_skill(eid, 0, &(send this, &1), &(send this, &1))
  end
end
