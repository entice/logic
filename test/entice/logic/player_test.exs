defmodule Entice.Logic.PlayerTest do
  use ExUnit.Case, async: true
  use Entice.Logic.Maps
  use Entice.Logic.Attributes
  alias Entice.Entity
  alias Entice.Logic.Player


  setup do
    {:ok, _id, pid} = Entity.start
    Player.register(pid, HeroesAscent)
    {:ok, [entity: pid]}
  end


  test "correct register", %{entity: pid} do
    assert Entity.has_attribute?(pid, Name) == true
    assert Entity.has_attribute?(pid, Position) == true
    assert Entity.has_attribute?(pid, MapInstance) == true
    assert Entity.has_attribute?(pid, Appearance) == true
    assert Entity.has_attribute?(pid, Level) == true
  end


  test "correct unregister", %{entity: pid} do
    Player.unregister(pid)
    assert Entity.has_attribute?(pid, Name) == false
    assert Entity.has_attribute?(pid, Position) == false
    assert Entity.has_attribute?(pid, MapInstance) == false
    assert Entity.has_attribute?(pid, Appearance) == false
    assert Entity.has_attribute?(pid, Level) == false
  end
end
