defmodule Entice.Logic.MapInstanceTest do
  use ExUnit.Case, async: true
  alias Entice.Entity
  alias Entice.Entity.Coordination
  alias Entice.Entity.Test.Spy
  alias Entice.Logic.MapInstance
  alias Entice.Logic.Player
  alias Entice.Logic.Player.Name
  use Entice.Logic.Maps
  @moduletag :map_instance


  setup do
    {:ok, _entity_id, pid} = Entity.start
    MapInstance.register(pid, HeroesAscent)
    {:ok, [entity: pid]}
  end

  test "register", %{entity: pid} do
    m = %MapInstance{map: HeroesAscent, players: 0}
    assert {:ok, ^m} = Entity.fetch_attribute(pid, MapInstance)
  end

  test "player joins", %{entity: pid} do
    {:ok, player_id, player_pid} = Entity.start
    Player.register(player_pid, HeroesAscent)

    {:ok, id1, e1} = Entity.start
    Coordination.register(e1, HeroesAscent)
    Spy.register(e1, self)

    assert "Player added" = MapInstance.add_player(pid, player_id)

    assert 1 = Entity.get_attribute(pid, MapInstance).players
    assert_receive %{sender: ^id1, event: {:entity_join, %{entity_id: ^player_id, attributes: _}}}, 1000
  end

  test "npc joins", %{entity: pid} do
    npc_info = %{name: "Gwen"}

    {:ok, id1, e1} = Entity.start
    Coordination.register(e1, HeroesAscent)
    Spy.register(e1, self)

    assert {"Npc added", npc_id, npc_pid} = MapInstance.add_npc(pid, npc_info)

    assert_receive %{sender: ^id1, event: {:entity_join, %{entity_id: ^npc_id, attributes: _}}}
    name = Entity.get_attribute(npc_pid, Name)
    assert %Name{name: "Gwen"} = name
  end

  test "player leaves", %{entity: pid} do
    {:ok, _id, player_pid_1} = Entity.start
    Player.register(player_pid_1, HeroesAscent)
    {:ok, player_id_2, player_pid_2} = Entity.start
    Player.register(player_pid_2, HeroesAscent)

    Coordination.register_observer(pid, HeroesAscent)
    Spy.register(pid, self)

    MapInstance.add_player(pid, player_pid_1)
    MapInstance.add_player(pid, player_pid_2)

    m = %MapInstance{map: HeroesAscent, players: 2}
    assert {:ok, ^m} = Entity.fetch_attribute(pid, MapInstance)

    Entity.stop(player_id_2)

    assert_receive %{sender: _, event: {:entity_leave, %{entity_id: ^player_id_2}}}
    assert 1 = Entity.get_attribute(pid, MapInstance).players
  end

  test "last player leaves", %{entity: pid} do
    {:ok, player_id_1, player_pid_1} = Entity.start
    Player.register(player_pid_1, HeroesAscent)

    Coordination.register_observer(pid, HeroesAscent)
    Spy.register(pid, self)

    MapInstance.add_player(pid, player_pid_1)

    m = %MapInstance{map: HeroesAscent, players: 1}
    assert {:ok, ^m} = Entity.fetch_attribute(pid, MapInstance)

    Entity.stop(player_id_1)

    assert_receive %{sender: _, event: {:entity_leave, %{entity_id: ^player_id_1}}}
    assert :error = Entity.fetch_attribute(pid, MapInstance)
  end

  test "unregister", %{entity: pid} do
    MapInstance.unregister(pid)
    assert :error = Entity.fetch_attribute(pid, MapInstance)
  end
end
