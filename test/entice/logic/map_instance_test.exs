defmodule Entice.Logic.MapInstanceTest do
  use ExUnit.Case, async: true
  use Entice.Logic.Attributes
  use Entice.Logic.Map
  alias Entice.Entity
  alias Entice.Entity.Coordination
  alias Entice.Entity.Suicide
  alias Entice.Entity.Test.Spy
  alias Entice.Logic.MapInstance
  alias Entice.Logic.MapRegistry
  alias Entice.Logic.Player
  @moduletag :map_instance


  defmap TestMap1
  defmap TestMap2
  defmap TestMap3
  defmap TestMap4
  defmap TestMap5
  defmap TestMap6


  setup do
    MapRegistry.start_link()
    {:ok, entity_id, entity_pid} = Entity.start
    {:ok, %{entity_id: entity_id, entity_pid: entity_pid}}
  end


  test "register", %{entity_id: entity_id} do
    MapInstance.register(entity_id, TestMap1)
    m = %MapInstance{map: TestMap1, players: 0}
    assert {:ok, ^m} = Entity.fetch_attribute(entity_id, MapInstance)
  end


  test "player joins", %{entity_id: entity_id} do
    MapInstance.register(entity_id, TestMap2)
    {:ok, player_id, _pid} = Entity.start
    Player.register(player_id, TestMap2)

    {:ok, e1, _pid} = Entity.start
    Coordination.register(e1, TestMap2)
    Spy.register(e1, self)

    MapInstance.add_player(entity_id, player_id)

    assert 1 = Entity.get_attribute(entity_id, MapInstance).players
    assert_receive %{sender: ^e1, event: {:entity_join, %{entity_id: ^player_id, attributes: _}}}
  end


  test "npc joins", %{entity_id: entity_id} do
    MapInstance.register(entity_id, TestMap3)
    {:ok, e1, _pid} = Entity.start
    Coordination.register(e1, TestMap3)
    Spy.register(e1, self)

    MapInstance.add_npc(entity_id, "Gwen", :gwen, %Position{})

    assert_receive %{sender: ^e1, event: {:entity_join, %{entity_id: _, attributes: %{Npc => %Npc{npc_model_id: :gwen}}}}}, 300
  end


  test "player leaves", %{entity_id: entity_id} do
    MapInstance.register(entity_id, TestMap4)
    {:ok, player_id_1, _pid} = Entity.start
    Player.register(player_id_1, TestMap4)
    {:ok, player_id_2, _pid} = Entity.start
    Player.register(player_id_2, TestMap4)

    Spy.register(entity_id, self)

    MapInstance.add_player(entity_id, player_id_1)
    MapInstance.add_player(entity_id, player_id_2)

    assert 2 = Entity.get_attribute(entity_id, MapInstance).players

    Entity.stop(player_id_2)

    assert_receive %{sender: _, event: {:entity_leave, %{entity_id: ^player_id_2}}}
    assert 1 = Entity.get_attribute(entity_id, MapInstance).players
  end


  test "last player leaves", %{entity_id: entity_id, entity_pid: entity_pid} do
    MapInstance.register(entity_id, TestMap5)
    {:ok, player_id, _pid} = Entity.start
    Player.register(player_id, TestMap5)

    Process.monitor(entity_pid)
    Coordination.register_observer(self, TestMap5)

    MapInstance.add_player(entity_id, player_id)

    m = %MapInstance{map: TestMap5, players: 1}
    assert {:ok, ^m} = Entity.fetch_attribute(entity_id, MapInstance)

    Entity.stop(player_id)

    poison_pill = Suicide.poison_pill_message
    assert_receive ^poison_pill

    assert_receive {:coordination_stop_channel, TestMap5}
    assert_receive {:DOWN, _, _, _, :normal}
  end


  test "unregister", %{entity_id: entity_id} do
    MapInstance.register(entity_id, TestMap6)
    MapInstance.unregister(entity_id)
    assert :error = Entity.fetch_attribute(entity_id, MapInstance)
  end
end
