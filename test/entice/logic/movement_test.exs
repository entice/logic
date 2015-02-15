defmodule Entice.Logic.MovementTest do
  use ExUnit.Case
  use Entice.Logic.Attributes
  alias Entice.Entity
  alias Entice.Logic.Movement, as: Move


  setup do
    {:ok, eid, _pid} = Entity.start
    {:ok, [entity_id: eid]}
  end


  test "init plain", %{entity_id: eid} do
    Move.init(eid)
    m = %Movement{}
    assert {:ok, ^m} = Entity.fetch_attribute(eid, Movement)
  end


  test "init with position", %{entity_id: eid} do
    Entity.put_attribute(eid, %Position{pos: %Coord{x: 42, y: 1337}})
    Move.init(eid)
    m = %Movement{goal: %Coord{x: 42, y: 1337}}
    assert {:ok, ^m} = Entity.fetch_attribute(eid, Movement)
  end


  test "init with movement", %{entity_id: eid} do
    Entity.put_attribute(eid, %Movement{goal: %Coord{x: 42, y: 1337}})
    Move.init(eid)
    m = %Movement{goal: %Coord{x: 42, y: 1337}}
    assert {:ok, ^m} = Entity.fetch_attribute(eid, Movement)
  end


  test "change speed", %{entity_id: eid} do
    Move.init(eid)
    Move.change_speed(eid, 0.123)
    assert {:ok, %Movement{speed: 0.123}} = Entity.fetch_attribute(eid, Movement)
  end


  test "change type", %{entity_id: eid} do
    Move.init(eid)
    Move.change_move_type(eid, 8)
    assert {:ok, %Movement{movetype: 8}} = Entity.fetch_attribute(eid, Movement)
  end


  test "change goal", %{entity_id: eid} do
    Move.init(eid)
    Move.change_goal(eid, %Coord{x: 42, y: 1337})
    assert {:ok, %Movement{goal: %Coord{x: 42, y: 1337}}} = Entity.fetch_attribute(eid, Movement)
  end


  test "terminate", %{entity_id: eid} do
    Move.init(eid)
    Move.remove(eid)
    assert :error = Entity.fetch_attribute(eid, Movement)
  end
end
