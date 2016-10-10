defmodule Entice.Logic.SeekTest do
  use ExUnit.Case, async: true
  use Entice.Logic.Maps
  use Entice.Logic.Attributes
  alias Entice.Entity
  alias Entice.Logic.{Player, Seek}
  alias Entice.Logic.Player.Position
  alias Entice.Entity.Coordination
  use Entice.Logic.Map

  defmap TestMap

  setup do
    npc_init_coord =  %Coord{x: 10, y: 10}
    {:ok, npc_eid, npc_pid} = Npc.spawn("Dhuum", :dhuum, %Position{coord: npc_init_coord})
    {:ok, player_eid, player_pid} = Entity.start
    #Sets an initial pos for the player so the Position attr appears as changed and not added in the following tests
    simulate_movement_update(player_pid, %Position{coord: %Coord{x: 1, y: 2}}, %Movement{goal: %Coord{x: 3, y: 4}})

    Player.register(player_pid, TestMap)
    Coordination.register(player_eid, TestMap)
    Coordination.register(npc_eid, TestMap)
    {:ok, [npc_entity: npc_pid, npc_eid: npc_eid, player_eid: player_eid, player_entity: player_pid, npc_init_coord: npc_init_coord]}
  end

  test "register", %{npc_entity: pid} do
    assert {:ok, %Seek{target: nil, aggro_distance: _, escape_distance: _}} = Entity.fetch_attribute(pid, Seek)
  end

  test "update same entity", %{npc_entity: pid} do
    simulate_movement_update(pid, %Position{coord: %Coord{x: 1, y: 2}}, %Movement{goal: %Coord{x: 3, y: 4}})
    assert {:ok, %Seek{target: nil}} = Entity.fetch_attribute(pid, Seek)
  end

  test "update no target, entity close enough to aggro", %{npc_entity: npc_pid, player_eid: player_eid, player_entity: player_pid} do
    #Move player within 2 units of distance of npc with aggro distance of 1000
    mover_coord = %Coord{x: 14, y: 10}
    simulate_movement_update(player_pid, %Position{coord: mover_coord}, %Movement{goal: mover_coord})


    assert {:ok, %Seek{target: ^player_eid}} = Entity.fetch_attribute(npc_pid, Seek)
    assert {:ok, %Movement{goal: ^mover_coord}} = Entity.fetch_attribute(npc_pid, Movement)
  end

  test "update no target, entity too far to aggro", %{npc_entity: npc_pid, player_entity: player_pid} do
    simulate_movement_update(player_pid, %Position{coord: %Coord{x: 460, y: 910}}, %Movement{goal: %Coord{x: 0, y: 0}})
    assert {:ok, %Seek{target: nil}} = Entity.fetch_attribute(npc_pid, Seek)
  end

  test "update has target, entity is not current target", %{npc_entity: npc_pid, player_eid: player_eid} do
    #Set player as target
    Entity.put_attribute(npc_pid, %Seek{target: player_eid, aggro_distance: 10, escape_distance: 20})

    #Create unrelated entity at a random pos and add it to map channel
    {:ok, other_player_eid, other_player_pid} = Entity.start
    simulate_movement_update(other_player_pid, %Position{coord: %Coord{x: 1, y: 2}}, %Movement{goal: %Coord{x: 3, y: 4}})
    Coordination.register(other_player_eid, TestMap)

    #Move other player inside of aggro range and check that npc keeps initial target
    simulate_movement_update(other_player_pid, %Position{coord: %Coord{x: 11, y: 11}}, %Movement{goal: %Coord{x: 0, y: 0}})
    assert {:ok, %Seek{target: ^player_eid}} = Entity.fetch_attribute(npc_pid, Seek)
  end

  test "update has target, entity is current target, entity escapes",
  %{npc_entity: npc_pid, player_eid: player_eid, player_entity: player_pid, npc_init_coord: npc_init_coord} do
    #Set player as target
    Entity.put_attribute(npc_pid, %Seek{target: player_eid, aggro_distance: 10, escape_distance: 20})

    #Move target player far enough to escape
    simulate_movement_update(player_pid, %Position{coord: %Coord{x: 30, y: 15}}, %Movement{goal: %Coord{x: 0, y: 0}})
    assert {:ok, %Seek{target: nil}} = Entity.fetch_attribute(npc_pid, Seek)
    assert {:ok, %Movement{goal: ^npc_init_coord}} = Entity.fetch_attribute(npc_pid, Movement)
  end

  test "update has target, entity is current target, entity does not escape", %{npc_entity: npc_pid, player_eid: player_eid, player_entity: player_pid} do
    #Set player as target
    Entity.put_attribute(npc_pid, %Seek{target: player_eid, aggro_distance: 10, escape_distance: 20})

    #Move target player but not far enough to escape
    new_player_coord = %Coord{x: 14, y: 15}
    simulate_movement_update(player_pid, %Position{coord: new_player_coord}, %Movement{goal: %Coord{x: 0, y: 0}})
    assert {:ok, %Seek{target: ^player_eid}} = Entity.fetch_attribute(npc_pid, Seek)
    assert {:ok, %Movement{goal: ^new_player_coord}} = Entity.fetch_attribute(npc_pid, Movement)
  end


  defp simulate_movement_update(entity_pid, new_coord, new_movement) do
    entity_pid |> Entity.attribute_transaction(
      fn attrs ->
        attrs
        |> Map.put(Position, new_coord)
        |> Map.put(Movement, new_movement)
      end)
  end
end
