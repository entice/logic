defmodule Entice.Logic.Attributes do
  alias Entice.Utils.Geom.Coord

  defmacro __using__(_) do
    quote do
      alias Entice.Utils.Geom.Coord
      alias Entice.Logic.Attributes.Name
      alias Entice.Logic.Attributes.Position
      alias Entice.Logic.Attributes.Movement
      alias Entice.Logic.Attributes.Appearance
      alias Entice.Logic.Attributes.Group
      alias Entice.Logic.Attributes.Member
      alias Entice.Logic.Attributes.SkillBar
    end
  end

  defmodule Name, do: defstruct(
    name: "Hansus Wurstus")

  defmodule Area, do: defstruct(
    area: Entice.Logic.Area.default_area)

  defmodule Position, do: defstruct(
    pos: %Coord{})

  defmodule Movement, do: defstruct(
    goal: %Coord{},
    plane: 1,
    movetype: 9,
    speed: 1.0)

  defmodule Appearance, do: defstruct(
    profession: 1,
    campaign: 0,
    sex: 1,
    height: 0,
    skin_color: 3,
    hair_color: 0,
    hairstyle: 7,
    face: 30)

  defmodule Group, do: defstruct(
    members: [],
    invited: [])

  defmodule Member, do: defstruct(
    group: "")

  defmodule SkillBar, do: defstruct(
    slots: %{})
end
