defmodule Entice.Logic.MapRegistryTest do
  use ExUnit.Case, async: true
  use Entice.Logic.Map
  alias Entice.Logic.MapRegistry
  @moduletag :map_registry

  defmap TestMap1
  defmap TestMap2
  defmap TestMap3
  defmap TestMap4

  setup do
    MapRegistry.start_link()
    :ok
  end

  test "start instance success" do
    assert {:ok, _id} = MapRegistry.start_instance(TestMap1)
  end

  test "start instance already exists" do
    MapRegistry.start_instance(TestMap2)
    assert {:error, :instance_already_running} = MapRegistry.start_instance(TestMap2)
  end

  test "get instance" do
    {:ok, id} = MapRegistry.start_instance(TestMap3)
    assert ^id = MapRegistry.get_instance(TestMap3)
  end

  test "instance stopped success" do
    {:ok, _id} = MapRegistry.start_instance(TestMap4)
    MapRegistry.instance_stopped(TestMap4)
    refute MapRegistry.get_instance(TestMap4)
  end
end
