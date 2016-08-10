defmodule Entice.Logic.SeekTest do
  use ExUnit.Case, async: true
  use Entice.Logic.Maps
  use Entice.Logic.Attributes
  alias Entice.Entity
  alias Entice.Logic.{Player, Seek}
  alias Entice.Logic.Player.Position
  alias Entice.Entity.Coordination


  setup do
    {:ok, npc_eid, npc_pid} = Npc.spawn("Dhuum", :dhuum, %Position{pos: %Coord{x: 10, y: 10}})
    {:ok, player_eid, player_pid} = Entity.start
    Player.register(player_pid, HeroesAscent)
    {:ok, [npc_entity: npc_pid, npc_eid: npc_eid, player_eid: player_eid, player_entity: player_pid]}
  end

  test "correct default register", %{npc_entity: pid} do
    assert {:ok, %Seek{target: nil, aggro_distance: 10, escape_distance: 20}} = Entity.fetch_attribute(pid, Seek)
  end

  test "update same entity", %{npc_entity: pid, npc_eid: eid} do
    Coordination.notify(pid, {:movement_agent_updated, %Position{pos: %Coord{x: 1, y: 2}}, eid})
    assert {:ok, %Seek{target: nil}} = Entity.fetch_attribute(pid, Seek)
  end

  test "update no target, entity close enough to aggro", %{npc_entity: npc_pid, player_eid: player_eid} do
    #Move player within 2 units of distance of npc with aggro distance of 10 (default)
    mover_pos = %Coord{x: 14, y: 10}
    Coordination.notify(npc_pid, {:movement_agent_updated, %Position{pos: mover_pos}, player_eid})

    assert {:ok, %Seek{target: ^player_eid}} = Entity.fetch_attribute(npc_pid, Seek)
    assert {:ok, %Movement{goal: ^mover_pos}} = Entity.fetch_attribute(npc_pid, Movement)
  end

  test "update no target, entity too far to aggro", %{npc_entity: npc_pid, player_eid: player_eid} do
    Coordination.notify(npc_pid, {:movement_agent_updated, %Position{pos: %Coord{x: 19, y: 15}}, player_eid})
    assert {:ok, %Seek{target: nil}} = Entity.fetch_attribute(npc_pid, Seek)
  end

  test "update has target, entity is not current target", %{npc_entity: npc_pid, player_eid: player_eid} do
    #Set player as target
    Entity.put_attribute(npc_pid, %Seek{target: player_eid, aggro_distance: 10, escape_distance: 20})

    #Create unrelated entity
    {:ok, unknown_eid, _} = Entity.start

    Coordination.notify(npc_pid, {:movement_agent_updated, %Position{pos: %Coord{x: 11, y: 11}}, unknown_eid})
    assert {:ok, %Seek{target: ^player_eid}} = Entity.fetch_attribute(npc_pid, Seek)
  end

  test "update has target, entity is current target, entity escapes", %{npc_entity: npc_pid, player_eid: player_eid} do
    init_pos = %Coord{x: 10, y: 10}

    #Set player as target
    Entity.put_attribute(npc_pid, %Seek{target: player_eid, aggro_distance: 10, escape_distance: 20})

    #Notify of new position outside escape range (dist = 20.6 > 20)
    Coordination.notify(npc_pid, {:movement_agent_updated, %Position{pos: %Coord{x: 30, y: 15}}, player_eid})
    assert {:ok, %Seek{target: nil}} = Entity.fetch_attribute(npc_pid, Seek)
    assert {:ok, %Movement{goal: ^init_pos}} = Entity.fetch_attribute(npc_pid, Movement)
  end

  test "update has target, entity is current target, entity does not escape", %{npc_entity: npc_pid, player_eid: player_eid} do
    #Set player as target
    Entity.put_attribute(npc_pid, %Seek{target: player_eid, aggro_distance: 10, escape_distance: 20})

    #Notify of new position outside escape range (dist = 20.6 > 20)
    new_player_pos = %Coord{x: 14, y: 15}
    Coordination.notify(npc_pid, {:movement_agent_updated, %Position{pos: new_player_pos}, player_eid})
    assert {:ok, %Seek{target: ^player_eid}} = Entity.fetch_attribute(npc_pid, Seek)
    assert {:ok, %Movement{goal: ^new_player_pos}} = Entity.fetch_attribute(npc_pid, Movement)
  end
end
