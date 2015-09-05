defmodule Entice.Logic.MovementTest do
  use ExUnit.Case, async: true
  alias Entice.Entity
  alias Entice.Utils.Geom.Coord
  alias Entice.Logic.Movement
  alias Entice.Logic.Player.Position


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
    Entity.put_attribute(pid, %Position{pos: %Coord{x: 42, y: 1337}})
    Movement.register(pid)
    m = %Movement{goal: %Coord{x: 42, y: 1337}}
    assert {:ok, ^m} = Entity.fetch_attribute(pid, Movement)
  end


  test "register with movement", %{entity: pid} do
    Movement.unregister(pid) # remove again, so we can add a new one
    Entity.put_attribute(pid, %Movement{goal: %Coord{x: 42, y: 1337}})
    Movement.register(pid)
    m = %Movement{goal: %Coord{x: 42, y: 1337}}
    assert {:ok, ^m} = Entity.fetch_attribute(pid, Movement)
  end


  test "change type / velocity", %{entity: pid} do
    Movement.change_move_type(pid, 8, 0.5)
    assert {:ok, %Movement{movetype: 8, velocity: 0.5}} = Entity.fetch_attribute(pid, Movement)
  end


  test "change goal", %{entity: pid} do
    Movement.change_goal(pid, %Coord{x: 42, y: 1337}, 13)
    assert {:ok, %Movement{goal: %Coord{x: 42, y: 1337}, plane: 13}} = Entity.fetch_attribute(pid, Movement)
  end


  test "terminate", %{entity: pid} do
    Movement.unregister(pid)
    assert :error = Entity.fetch_attribute(pid, Movement)
  end
end
