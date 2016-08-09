defmodule Entice.Logic.SeekTest do
  use ExUnit.Case, async: true
  use Entice.Logic.Maps
  use Entice.Logic.Attributes
  alias Entice.Entity
  alias Entice.Logic.{Player, Seek}
  alias Entice.Entity.Coordination


  setup do
    {:ok, _, npc_pid} = Npc.spawn("Dhuum", :dhuum, %Position{pos: %Coord{x: 10, y: 10}})
    {:ok, _, player_pid} = Entity.start
    Player.register(player_pid, HeroesAscent)
    {:ok, [npc_entity: npc_pid, player_entity: player_pid]}
  end

  test "update same entity", %{npc_entity: npc_pid, player_entity: player_pid} do
    Coordination.notify(npc_pid, {:movement_agent_updated, npc_pid})
    assert {:ok, %Seek{target: nil}} = Entity.fetch_attribute(npc_pid, Seek)
  end

  test "update no target, entity close enough to aggro", %{npc_entity: npc_pid, player_entity: player_pid} do
    #player_pid |> update_attribute(Position, fn(p) -> %Position{p | pos: %Coord{x: 10, y: 10}} end)
    assert true
  end

  test "update no target, entity too far to aggro", %{npc_entity: npc_pid, player_entity: player_pid} do

  end

  test "update has target, entity is not current target", %{npc_entity: npc_pid, player_entity: player_pid} do

  end

  test "update has target, entity is current target, entity escapes", %{npc_entity: npc_pid, player_entity: player_pid} do

  end

  test "update has target, entity is current target, entity does not escape", %{npc_entity: npc_pid, player_entity: player_pid} do

  end
end
