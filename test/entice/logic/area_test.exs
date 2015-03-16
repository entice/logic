defmodule Entice.Logic.AreaTest do
  use ExUnit.Case
  use Entice.Logic.Area

  test "area api" do
    assert {:ok, TeamArenas} = Area.get_map("TeamArenas")
  end

  test "outposts & non-outposts" do
    assert TeamArenas.is_outpost? == true
    assert IsleOfTheNameless.is_outpost? == false
  end

  test "default area" do
    assert HeroesAscent = Area.default_map
  end
end
