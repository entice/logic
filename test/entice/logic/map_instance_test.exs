defmodule Entice.Logic.MapInstanceTest do
  use ExUnit.Case, async: true
  alias Entice.Entity
  alias Entice.Logic.MapInstance
  use Entice.Logic.Maps
  @moduletag :map_instance


  setup _context do
    {:ok, _id, pid} = Entity.start
    MapInstance.register(pid, HeroesAscent)
    {:ok, [entity: pid]}
  end

  @tag id: 1
  test "register", %{entity: pid} do
    MapInstance.register(pid, HeroesAscent)
    m = %MapInstance{map: HeroesAscent, npcs: [], players: []}
    assert {:ok, ^m} = Entity.fetch_attribute(pid, MapInstance)
  end

  @tag id: 2
  test "player joins", %{entity: _pid} do
    #Player.register(pid, HeroesAscent)
    #Entity.call_behaviour(entity, MapInstance.Behaviour, {:map_instance_player_join, player}, pid)
  end

  @tag id: 3
  test "player joins but already joined", %{entity: _pid} do
  end

  @tag id: 4
  test "player leaves", %{entity: _pid} do
  end

  @tag id: 5
  test "player leaves but already left", %{entity: _pid} do
  end

  @tag id: 6
  test "npc joins", %{entity: _pid} do
  end

  @tag id: 7
  test "npc joins but already joined", %{entity: _pid} do
  end

  @tag id: 8
  test "npc leaves", %{entity: _pid} do
  end

  @tag id: 9
  test "npc leaves but already left", %{entity: _pid} do
  end

  @tag id: 10
  test "unregister", %{entity: pid} do
    MapInstance.unregister(pid)
    assert :error = Entity.fetch_attribute(pid, MapInstance)
  end
end
