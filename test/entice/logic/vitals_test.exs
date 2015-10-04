defmodule Entice.Logic.VitalsTest do
  use ExUnit.Case, async: true
  use Entice.Logic.Attributes
  alias Entice.Entity

  setup do
    {:ok, e1, _pid} = Entity.start
    {:ok, e2, _pid} = Entity.start

    Entity.put_attribute(e2, %Level{level: 3})

    {:ok, [e1: e1, e2: e2]}
  end

  test "check entity has health", %{e1: e1} do
    assert Entity.has_attribute?(e1, Health) == true
  end

  test "check entity has health level 20", %{e1: e1} do
    assert {:ok, %Health{health: 480, max_health: 480}} = Entity.fetch_attribute(e1, Health)
  end

  test "check entity has health level 3", %{e2: e2} do
    assert {:ok, %Health{health: 120, max_health: 120}} = Entity.fetch_atrribute(e2, Health)
  end

  test "check entity has mana", %{e1: e1} do
    assert Entity.has_attribute?(e1, Energy)
  end
end