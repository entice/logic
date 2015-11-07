defmodule Entice.Logic.MapTest do
  use ExUnit.Case, async: true
  use Entice.Logic.Maps

  test "map api" do
    assert {:ok, TeamArenas} = Maps.get_map("TeamArenas")
  end

  test "outposts & non-outposts" do
    assert TeamArenas.is_outpost? == true
    assert IsleOfTheNameless.is_outpost? == false
  end

  test "default map" do
    assert HeroesAscent = Maps.default_map
  end
end
