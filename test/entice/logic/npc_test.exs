defmodule Entice.Logic.NpcTest do
  use ExUnit.Case, async: true
  use Entice.Logic.Maps
  use Entice.Logic.Attributes
  alias Entice.Entity
  alias Entice.Logic.Npc
  alias Entice.Logic.Player.{Name, Position, Level}


  setup do
    #IO.inspect HeroesAscent.nav_mesh
    {:ok, _id, pid} = Npc.spawn(HeroesAscent, "Dhuum", :dhuum, %Position{coord: %Vector2D{x: 1, y: 2}, plane: 3})
    {:ok, [entity: pid]}
  end

  test "correct spawn", %{entity: pid} do
    assert {:ok, %Name{name: "Dhuum"}} = Entity.fetch_attribute(pid, Name)
    assert {:ok, %Npc{npc_model_id: :dhuum}} = Entity.fetch_attribute(pid, Npc)
    assert {:ok, %Level{level: 20}} = Entity.fetch_attribute(pid, Level)
    assert {:ok, %Position{coord: %Vector2D{x: 1, y: 2}, plane: 3}} = Entity.fetch_attribute(pid, Position)
  end

  test "correct unregister", %{entity: pid} do
    Npc.unregister(pid)
    assert Entity.has_attribute?(pid, Name) == false
    assert Entity.has_attribute?(pid, Position) == false
    assert Entity.has_attribute?(pid, Npc) == false
    assert Entity.has_attribute?(pid, Level) == false
  end
end
