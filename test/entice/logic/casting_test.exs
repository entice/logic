defmodule Entice.Logic.CastingTest do
  use ExUnit.Case, async: true
  use Entice.Logic.Attributes
  alias Entice.Entity
  alias Entice.Entity.Attribute
  alias Entice.Entity.Test.Spy
  alias Entice.Logic.Skills
  alias Entice.Logic.Casting
  @moduletag :casting


  # setup all tags programmatically
  setup do
    {:ok, entity_id, _pid} = Entity.start_plain
    Attribute.register(entity_id)
    Casting.register(entity_id)
    Spy.register(entity_id, self)
    Entity.put_attribute(entity_id, %Energy{mana: 50})
    {:ok, [entity_id: entity_id]}
  end


  test "won't cast when not enough energy", %{entity_id: eid} do
    Entity.put_attribute(eid, %Energy{mana: 0})
    assert {:error, :not_enough_energy} = Casting.cast_skill(eid, Skills.MantraOfEarth, nil, self)
  end


  test "won't cast recharging skill", %{entity_id: eid} do
    Entity.put_attribute(eid, %Energy{mana: 100})

    recharge_timers = Map.put(%{}, Skills.MantraOfEarth, 10)
    Entity.update_attribute(eid, Casting, fn c -> %Casting{c | recharge_timers: recharge_timers} end)
    assert {:error, :still_recharging} = Casting.cast_skill(eid, Skills.MantraOfEarth, nil, self)
    Entity.update_attribute(eid, Casting, fn _c -> %Casting{} end)
  end


  test "won't cast with casting timer != nil", %{entity_id: eid} do
    Entity.update_attribute(eid, Casting, fn c -> %Casting{c | cast_timer: 10} end)
    assert {:error, :still_casting} = Casting.cast_skill(eid, Skills.HealingSignet, nil, self)
  end


  test "won't cast with after_cast_timer != nil", %{entity_id: eid} do
    Entity.update_attribute(eid, Casting, fn c -> %Casting{c | after_cast_timer: 10} end)
    assert {:error, :still_casting} = Casting.cast_skill(eid, Skills.HealingSignet, nil, self)
  end


  test "won't cast with both cast_timer and after_cast_timer != nil", %{entity_id: eid} do
    Entity.update_attribute(eid, Casting, fn c -> %Casting{c | cast_timer: 10, after_cast_timer: 10} end)
    assert {:error, :still_casting} = Casting.cast_skill(eid, Skills.HealingSignet, nil, self)
  end


  test "check correct cast time", %{entity_id: eid} do
    cast_time = Skills.SignetOfCapture.cast_time
    assert {:ok, Skills.SignetOfCapture, ^cast_time} = Casting.cast_skill(eid, Skills.SignetOfCapture, nil, self)
    # the timers are only set after casting is done
    assert nil == Entity.get_attribute(eid, Casting).recharge_timers[Skills.SignetOfCapture]
    assert nil == Entity.get_attribute(eid, Casting).after_cast_timer

    assert_receive %{sender: ^eid, event: {:casting_cast_end, Skills.SignetOfCapture, ^cast_time, nil, _pid}}, (Skills.SignetOfCapture.cast_time + 100)
    assert_receive {:skill_casted, %{entity_id: ^eid, skill: Skills.SignetOfCapture, target_entity_id: nil}}
    assert nil != Entity.get_attribute(eid, Casting).recharge_timers[Skills.SignetOfCapture]
    assert nil != Entity.get_attribute(eid, Casting).after_cast_timer
  end


  test "check correct after_cast time", %{entity_id: eid} do
    cast_time = Skills.SignetOfCapture.cast_time
    assert {:ok, Skills.SignetOfCapture, ^cast_time} = Casting.cast_skill(eid, Skills.SignetOfCapture, nil, self)
    assert nil == Entity.get_attribute(eid, Casting).after_cast_timer

    assert_receive %{sender: ^eid, event: {:casting_after_cast_end, _pid}}, (
      Skills.SignetOfCapture.cast_time + Entice.Logic.Casting.after_cast_delay + 100)
    assert_receive {:after_cast_delay_ended, %{entity_id: ^eid}}
    assert nil == Entity.get_attribute(eid, Casting).after_cast_timer
  end


  test "check correct recharge time", %{entity_id: eid} do
    cast_time = Skills.SignetOfCapture.cast_time
    recharge_time = Skills.SignetOfCapture.recharge_time
    assert {:ok, Skills.SignetOfCapture, ^cast_time} = Casting.cast_skill(eid, Skills.SignetOfCapture, nil, self)
    assert nil == Entity.get_attribute(eid, Casting).recharge_timers[Skills.SignetOfCapture]

    assert_receive %{sender: ^eid, event: {:casting_recharge_end, Skills.SignetOfCapture, ^recharge_time, _pid}}, (
      Skills.SignetOfCapture.cast_time + Skills.SignetOfCapture.recharge_time + 100)
    assert_receive {:skill_recharged, %{entity_id: ^eid, skill: Skills.SignetOfCapture}}
    assert nil == Entity.get_attribute(eid, Casting).recharge_timers[Skills.SignetOfCapture]
    assert nil == Entity.get_attribute(eid, Casting).cast_timer
    assert nil == Entity.get_attribute(eid, Casting).after_cast_timer
  end


  test "check correct effect application", %{entity_id: eid} do
    # prepare a target
    {:ok, e1, _p1} = Entity.start_plain
    Attribute.register(e1)
    Attribute.put(e1, %Health{})
    %Health{health: health} = Entity.get_attribute(e1, Health)

    cast_time = Skills.Bamph.cast_time
    assert {:ok, Skills.Bamph, ^cast_time} = Casting.cast_skill(eid, Skills.Bamph, e1, self)
    assert_receive %{sender: ^eid, event: {:casting_cast_end, Skills.Bamph, ^cast_time, ^e1, _pid}}, (Skills.Bamph.cast_time + 100)

    %Health{health: health_after_damage} = Entity.get_attribute(e1, Health)
    assert health_after_damage < health
  end
end
