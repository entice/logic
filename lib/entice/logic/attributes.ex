defmodule Entice.Logic.Attributes do
  alias Entice.Utils.Geom.Coord
  alias Entice.Logic.Area

  defmacro __using__(_) do
    quote do
      alias Entice.Utils.Geom.Coord
      alias Entice.Logic.Attributes.Name
      alias Entice.Logic.Attributes.Position
      alias Entice.Logic.Attributes.Map
      alias Entice.Logic.Attributes.Appearance
      alias Entice.Logic.Movement
      alias Entice.Logic.Group.Leader
      alias Entice.Logic.Group.Member
      alias Entice.Logic.SkillBar
    end
  end

  defmodule Name, do: defstruct(
    name: "Unknown Entity")

  defmodule Position, do: defstruct(
    pos: %Coord{})

  defmodule Map, do: defstruct(
    map: Area.default_map)

  defmodule Appearance, do: defstruct(
    profession: 1,
    campaign: 0,
    sex: 1,
    height: 0,
    skin_color: 3,
    hair_color: 0,
    hairstyle: 7,
    face: 30)
end
