defmodule Entice.Logic.MapRegistryTest do
  use ExUnit.Case, async: true
  use Entice.Logic.Map
  alias Entice.Entity
  alias Entice.Logic.{MapInstance, MapRegistry}
  @moduletag :map_registry

  defmap TestMap1
  defmap TestMap2
  defmap TestMap3
  defmap TestMap4


  setup do
    MapRegistry.start_link()
    :ok
  end


  test "start instance" do
    entity = MapRegistry.get_or_create_instance(TestMap1)
    assert Entity.exists?(entity)
    assert Entity.has_behaviour?(entity, MapInstance.Behaviour)
    assert Process.alive?(Entity.fetch!(entity))
  end

  test "get instance that already exists" do
    entity = MapRegistry.get_or_create_instance(TestMap2)
    assert ^entity = MapRegistry.get_or_create_instance(TestMap2)
  end

  test "stop instance" do
    entity = MapRegistry.get_or_create_instance(TestMap4)
    Process.monitor(Entity.fetch!(entity))
    MapRegistry.stop_instance(TestMap4)

    assert_receive {:DOWN, _, _, _, :normal}
  end
end
