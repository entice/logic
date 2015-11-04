defmodule Entice.Logic.MapInstanceTest do
  use ExUnit.Case, async: true
  use Entice.Logic.Attributes
  use Entice.Logic.Maps
  alias Entice.Entity
  alias Entice.Entity.Coordination
  alias Entice.Entity.Suicide
  alias Entice.Entity.Test.Spy
  alias Entice.Logic.MapInstance
  alias Entice.Logic.Player
  @moduletag :map_instance


  setup do
    {:ok, entity_id, entity_pid} = Entity.start
    MapInstance.register(entity_id, HeroesAscent)
    {:ok, %{entity_id: entity_id, entity_pid: entity_pid}}
  end

  test "register", %{entity_id: entity_id} do
    m = %MapInstance{map: HeroesAscent, players: 0}
    assert {:ok, ^m} = Entity.fetch_attribute(entity_id, MapInstance)
  end

  test "player joins", %{entity_id: entity_id} do
    {:ok, player_id, _pid} = Entity.start
    Player.register(player_id, HeroesAscent)

    {:ok, e1, _pid} = Entity.start
    Coordination.register(e1, HeroesAscent)
    Spy.register(e1, self)

    MapInstance.add_player(entity_id, player_id)

    assert 1 = Entity.get_attribute(entity_id, MapInstance).players
    assert_receive %{sender: ^e1, event: {:entity_join, %{entity_id: ^player_id, attributes: _}}}
  end

  test "npc joins", %{entity_id: entity_id} do
    {:ok, e1, _pid} = Entity.start
    Coordination.register(e1, HeroesAscent)
    Spy.register(e1, self)

    MapInstance.add_npc(entity_id, "Gwen", :gwen, %Position{})

    assert_receive %{sender: ^e1, event: {:entity_join, %{entity_id: _, attributes: %{Npc => %Npc{npc_model_id: :gwen}}}}}
  end

  test "player leaves", %{entity_id: entity_id, entity_pid: entity_pid} do
    {:ok, player_id_1, player_pid_1} = Entity.start
    Player.register(player_id_1, HeroesAscent)
    {:ok, player_id_2, player_pid_2} = Entity.start
    Player.register(player_id_2, HeroesAscent)

    Coordination.register_observer(entity_pid, HeroesAscent)
    Spy.register(entity_pid, self)

    MapInstance.add_player(entity_id, player_id_1)
    MapInstance.add_player(entity_id, player_id_2)

    assert 2 = Entity.get_attribute(entity_id, MapInstance).players

    Entity.stop(player_id_2)

    assert_receive %{sender: _, event: {:entity_leave, %{entity_id: ^player_id_2}}}
    assert 1 = Entity.get_attribute(entity_id, MapInstance).players
  end

  test "last player leaves", %{entity_id: entity_id, entity_pid: entity_pid} do
    {:ok, player_id, _pid} = Entity.start
    Player.register(player_id, HeroesAscent)

    Coordination.register_observer(entity_pid, HeroesAscent)
    Coordination.register_observer(self, HeroesAscent)

    MapInstance.add_player(entity_id, player_id)

    m = %MapInstance{map: HeroesAscent, players: 1}
    assert {:ok, ^m} = Entity.fetch_attribute(entity_id, MapInstance)

    Entity.stop(player_id)

    poison_pill = Suicide.poison_pill_message

    assert_receive ^poison_pill
    assert not Entity.exists?(entity_id)
  end

  test "unregister", %{entity_id: entity_id} do
    MapInstance.unregister(entity_id)
    assert :error = Entity.fetch_attribute(entity_id, MapInstance)
  end
end
