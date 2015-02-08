defmodule Entice.Logic.AreaTest do
  use ExUnit.Case
  use Entice.Logic.Area
  alias Entice.Logic.Area

  test "area api" do
    assert {:ok, TeamArenas} = Area.get_map("TeamArenas")
  end
end
