defmodule Entice.Logic.MapInstanceTest do
  use ExUnit.Case, async: true
  alias Entice.Entity
  alias Entice.Logic.MapInstance
  use Entice.Logic.Maps
  @moduletag :map_instance


  setup context do
    {:ok, _id, pid} = Entity.start
    case context.id do
      1 -> MapInstance.register(pid, %MapInstance{map: HeroesAscent, npcs: [1, 2, 3], players: [4, 5 ,6]})
      3 -> MapInstance.register(pid, %MapInstance{map: HeroesAscent, npcs: [1, 2, 3], players: [4, 5 ,6]})
      _ ->
    end
    {:ok, [entity: pid]}
  end

  @tag id: 1
  test "register plain", %{entity: pid} do
    m = %MapInstance{map: HeroesAscent, npcs: [1,2,3], players: [4,5,6]}
    assert {:ok, ^m} = Entity.fetch_attribute(pid, MapInstance)
  end

  @tag id: 2
  test "register with map, players and npc_info", %{entity: pid} do
    map = HeroesAscent
    players = [1, 2, 3]
    npc_1_info = %{name: "test_npc_1", model: "test_npc_model_1"}
    npc_2_info = %{name: "test_npc_2", model: "test_npc_model_2"}
    npc_info = [npc_1_info, npc_2_info]
    MapInstance.register(pid, map, npc_info, players)
    assert {:ok, %MapInstance{players: ^players, npcs: _npcs, map: ^map}} = Entity.fetch_attribute(pid, MapInstance)
    #assert TODO: Finish npc asserts
  end

  @tag id: 3
  test "terminate", %{entity: pid} do
    MapInstance.unregister(pid)
    assert :error = Entity.fetch_attribute(pid, MapInstance)
  end
end
