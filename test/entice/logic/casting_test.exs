defmodule Entice.Logic.CastingTest do
  use ExUnit.Case, async: true
  alias Entice.Entity
  alias Entice.Entity.Test.Spy
  alias Entice.Logic.Skills
  alias Entice.Logic.Casting
  alias Entice.Logic.Vitals.Energy


  setup do
    {:ok, entity_id, _pid} = Entity.start
    Casting.register(entity_id)
    Spy.register(entity_id, self)
    Entity.put_attribute(entity_id, %Energy{mana: 50})
    {:ok, [entity_id: entity_id]}
  end

  @tag id: 0, casting: true
  test "won't cast when not enough energy", %{entity_id: eid} do
    Entity.put_attribute(eid, %Energy{mana: 0})
    assert {:error, :not_enough_energy} = Casting.cast_skill(eid, Skills.MantraOfEarth, &(send self, &1), &(send self, &1))
  end

  @tag id: 1, casting: true
  test "won't cast recharging skill", %{entity_id: eid} do
    Entity.put_attribute(eid, %Energy{mana: 100})

    recharge_timers = Map.put(%{}, Skills.MantraOfEarth, 10)
    Entity.update_attribute(eid, Casting, fn c -> %Casting{c | recharge_timers: recharge_timers} end)
    assert {:error, :still_recharging} = Casting.cast_skill(eid, Skills.MantraOfEarth, &(send self, &1), &(send self, &1))
    Entity.update_attribute(eid, Casting, fn _c -> %Casting{} end)
  end

  @tag id: 2, casting: true
  test "won't cast already casting", %{entity_id: eid} do

    #Test with casting timer != nil
    Entity.update_attribute(eid, Casting, fn c -> %Casting{c | cast_timer: 10} end)
    assert {:error, :still_casting} = Casting.cast_skill(eid, Skills.HealingSignet, &(send self, &1), &(send self, &1))
    Entity.update_attribute(eid, Casting, fn _c -> %Casting{} end)

    #Test with after_cast_timer != nil
    Entity.update_attribute(eid, Casting, fn c -> %Casting{c | after_cast_timer: 10} end)
    assert {:error, :still_casting} = Casting.cast_skill(eid, Skills.HealingSignet, &(send self, &1), &(send self, &1))
    Entity.update_attribute(eid, Casting, fn _c -> %Casting{} end)

    #Test with both != nil
    Entity.update_attribute(eid, Casting, fn c -> %Casting{c | cast_timer: 10, after_cast_timer: 10} end)
    assert {:error, :still_casting} = Casting.cast_skill(eid, Skills.HealingSignet, &(send self, &1), &(send self, &1))
    Entity.update_attribute(eid, Casting, fn _c -> %Casting{} end)
  end

  @tag id: 3, casting: true
  test "cast skill succesfully", %{entity_id: eid} do
    this = self
    assert {:ok, Skills.SignetOfCapture} = Casting.cast_skill(eid, Skills.SignetOfCapture, &(send this, &1), &(send this, &1))

    #Check appropriate events happen at appropriate times
    assert_receive %{sender: ^eid, event: {:casting_cast_end, Skills.SignetOfCapture, _cast_callback, _recharge_callback}}, 3500
    assert_receive Skills.SignetOfCapture
    assert nil != Entity.get_attribute(eid, Casting).recharge_timers[Skills.SignetOfCapture]
    assert nil != Entity.get_attribute(eid, Casting).after_cast_timer

    assert_receive %{sender: ^eid, event: {:casting_after_cast_end}}, 350
    assert_receive %{sender: ^eid, event: {:casting_recharge_end, Skills.SignetOfCapture, _recharge_callback}}, 2100
    assert_receive Skills.SignetOfCapture

    #Check Casting returned to initial state
    assert nil == Entity.get_attribute(eid, Casting).recharge_timers[Skills.SignetOfCapture]
    assert nil == Entity.get_attribute(eid, Casting).cast_timer
    assert nil == Entity.get_attribute(eid, Casting).after_cast_timer
  end
end
