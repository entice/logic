defmodule Entice.Logic.MapInstanceTest do
  use ExUnit.Case, async: true
  alias Entice.Entity
  alias Entice.Entity.Coordination
  alias Entice.Logic.MapInstance
  alias Entice.Logic.Player
  alias Entice.Logic.Player.Name
  use Entice.Logic.Maps
  @moduletag :map_instance


  setup do
    {:ok, _id, pid} = Entity.start
    MapInstance.register(pid, HeroesAscent)
    {:ok, [entity: pid]}
  end

  test "register", %{entity: pid} do
    m = %MapInstance{map: HeroesAscent, players: 0}
    assert {:ok, ^m} = Entity.fetch_attribute(pid, MapInstance)
  end

  test "player joins", %{entity: pid} do
    {:ok, _id, player_pid} = Entity.start
    Player.register(player_pid, HeroesAscent)

    {:ok, id1, e1} = Entity.start
    Coordination.register(e1, HeroesAscent)
    Spy.register(e1, self)

    Entity.call_behaviour(pid, MapInstance.Behaviour, {:map_instance_player_join, player_pid})

    m = %MapInstance{map: HeroesAscent, players: 1}
    assert {:ok, ^m} = Entity.fetch_attribute(pid, MapInstance)
    assert_receive %{sender: ^id1, event: {:entity_join, %{entity_id: ^player_pid, attributes: _}}}
  end

  test "npc joins", %{entity: pid} do
    npc_info = %{name: "Gwen"}

    {:ok, id1, e1} = Entity.start
    Coordination.register(e1, HeroesAscent)
    Spy.register(e1, self)

    Entity.call_behaviour(pid, MapInstance.Behaviour, {:map_instance_npc_join, npc_info})

    assert_receive %{sender: ^id1, event: {:entity_join, %{entity_id: npc_pid, attributes: _}}}
    npc = Entity.fetch!(npc_pid)
    assert %Entity{attributes: %{Name => %Name{name: "Gwen"}}} = npc
  end

  test "player leaves", %{entity: pid} do
    {:ok, _id, player_pid_1} = Entity.start
    Player.register(player_pid_1, HeroesAscent)
    {:ok, _id, player_pid_2} = Entity.start
    Player.register(player_pid_2, HeroesAscent)

    Spy.register(pid, self)

    Entity.call_behaviour(pid, MapInstance.Behaviour, {:map_instance_player_join, player_pid_1})
    Entity.call_behaviour(pid, MapInstance.Behaviour, {:map_instance_player_join, player_pid_2})

    m = %MapInstance{map: HeroesAscent, players: 2}
    assert {:ok, ^m} = Entity.fetch_attribute(pid, MapInstance)

    Entity.stop(player_pid_2)

    assert_receive %{sender: _, event: {:entity_leave, %{entity_id: ^player_pid_2, attributes: _}}}
    m = %MapInstance{map: HeroesAscent, players: 1}
    assert {:ok, ^m} = Entity.fetch_attribute(pid, MapInstance)
  end

  test "last player leaves", %{entity: pid} do
    {:ok, _id, player_pid_1} = Entity.start
    Player.register(player_pid_1, HeroesAscent)

    Spy.register(pid, self)

    Entity.call_behaviour(pid, MapInstance.Behaviour, {:map_instance_player_join, player_pid_1})

    m = %MapInstance{map: HeroesAscent, players: 1}
    assert {:ok, ^m} = Entity.fetch_attribute(pid, MapInstance)

    Entity.stop(player_pid_1)

    assert_receive %{sender: _, event: {:entity_leave, %{entity_id: ^player_pid_1, attributes: _}}}
    m = %MapInstance{map: HeroesAscent, players: 0}
    assert {:ok, ^m} = Entity.fetch_attribute(pid, MapInstance)
  end

  test "unregister", %{entity: pid} do
    MapInstance.unregister(pid)
    assert :error = Entity.fetch_attribute(pid, MapInstance)
  end
end
