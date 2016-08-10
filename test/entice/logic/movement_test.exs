defmodule Entice.Logic.MovementTest do
  use ExUnit.Case, async: true
  alias Entice.Entity
  alias Entice.Entity.Coordination
  alias Entice.Utils.Geom.Coord
  alias Entice.Logic.{Movement, MapInstance}
  alias Entice.Logic.Player.Position
  use Entice.Logic.Map

  defmap TestMap1

  setup do
    {:ok, _id, pid} = Entity.start
    Movement.register(pid)
    {:ok, [entity: pid]}
  end


  test "register plain", %{entity: pid} do
    m = %Movement{}
    assert {:ok, ^m} = Entity.fetch_attribute(pid, Movement)
  end


  test "register with position", %{entity: pid} do
    Movement.unregister(pid) # remove again, so we can add a new one
    Entity.put_attribute(pid, %Position{pos: %Coord{x: 42, y: 1337}, plane: 7})
    Movement.register(pid)
    m = %Movement{goal: %Coord{x: 42, y: 1337}, plane: 7}
    assert {:ok, ^m} = Entity.fetch_attribute(pid, Movement)
  end


  test "register with movement", %{entity: pid} do
    Movement.unregister(pid) # remove again, so we can add a new one
    Entity.put_attribute(pid, %Movement{goal: %Coord{x: 42, y: 1337}})
    Movement.register(pid)
    m = %Movement{goal: %Coord{x: 42, y: 1337}}
    assert {:ok, ^m} = Entity.fetch_attribute(pid, Movement)
  end


  test "update", %{entity: pid} do
    Entity.put_attribute(pid, %MapInstance{map: TestMap1})
    Coordination.register_observer(self, TestMap1)

    new_pos = %Position{pos: %Coord{x: 42, y: 1337}, plane: 7}
    Movement.update(pid,
      new_pos,
      %Movement{goal: %Coord{x: 1337, y: 42}, plane: 13, move_type: 5, velocity: 0.5})
    assert {:ok, %Position{plane: 7}} = Entity.fetch_attribute(pid, Position)
    assert {:ok, %Movement{move_type: 5}} = Entity.fetch_attribute(pid, Movement)    
    assert_receive {:movement_agent_updated, ^new_pos, ^pid} #TODO: update to use eid
  end


  test "terminate", %{entity: pid} do
    Movement.unregister(pid)
    assert :error = Entity.fetch_attribute(pid, Movement)
  end
end
