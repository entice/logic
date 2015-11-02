defmodule Entice.Logic.VitalsTest do
  use ExUnit.Case, async: true
  use Entice.Logic.Attributes
  alias Entice.Entity
  alias Entice.Logic.Vitals

  setup do
    {:ok, e1, _pid} = Entity.start
    {:ok, e2, _pid} = Entity.start

    Entity.put_attribute(e1, %Level{level: 20})
    Entity.put_attribute(e2, %Level{level: 3})

    Vitals.register(e1)
    Vitals.register(e2)

    {:ok, [e1: e1, e2: e2]}
  end


  test "entity has health", %{e1: e1} do
    assert Entity.has_attribute?(e1, Health)
  end


  test "entity has health level 20", %{e1: e1} do
    assert {:ok, %Health{health: 480.0, max_health: 480.0}} = Entity.fetch_attribute(e1, Health)
  end


  test "entity has health level 3", %{e2: e2} do
    assert {:ok, %Health{health: 140.0, max_health: 140.0}} = Entity.fetch_attribute(e2, Health)
  end


  test "entity has mana", %{e1: e1} do
    assert Entity.has_attribute?(e1, Energy)
  end

  test "entity has morale", %{e1: e1} do
    assert Entity.has_attribute?(e1, Morale)
  end


  test "health & energy & morale are removed on termination", %{e1: e1} do
    Vitals.unregister(e1)
    assert not Entity.has_attribute?(e1, Health)
    assert not Entity.has_attribute?(e1, Energy)
    assert not Entity.has_attribute?(e1, Morale)
  end
end
