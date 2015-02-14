defmodule Entice.Logic.MovementTest do
  use ExUnit.Case
  use Entice.Logic.Attributes
  alias Entice.Entity
  alias Entice.Logic.Movement, as: Move
  alias Entice.Test.Spy


  setup do
    {:ok, eid, _pid} = Entity.start
    Spy.inject_into(eid, self)
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


  # test "change speed", %{entity_id: eid} do
  #   Move.init(eid)
  #   Move.change_speed(eid, 0.123)
  #   assert_receive %{event: {:speed, _}}
  #   assert {:ok, %Movement{speed: 0.123}} = Entity.fetch_attribute(eid, Movement)
  # end


  # test "change type", %{entity_id: eid} do
  #   Move.init(eid)
  #   Move.change_move_type(eid, 8)
  #   assert {:ok, %Movement{movetype: 8}} = Entity.fetch_attribute(eid, Movement)
  # end
end
