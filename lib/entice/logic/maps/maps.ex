defmodule Entice.Logic.Maps do
  use Entice.Logic.Map
  alias Geom.Shape.NavigationMesh, as: NavMesh
  alias Geom.Utils.Serializer


  # Lobby is for special client entities that represent a logged in client.
  defmap Lobby

  # Outposts...
  defmap HeroesAscent, spawn: %Vector2D{x: 2017, y: -3241}, nav_mesh: Serializer.deserialize(%NavMesh{}, "data/heroes_ascent.map"), outpost: true
  defmap RandomArenas, spawn: %Vector2D{x: 3854, y: 3874}
  defmap TeamArenas,   spawn: %Vector2D{x: -1873, y: 352}

  # Explorables...
  defmap GreatTempleOfBalthazar, spawn: %Vector2D{x: -6558, y: -6010}, outpost: false # faked for testing purpose
  defmap IsleOfTheNameless,      spawn: %Vector2D{x: -6036, y: -2519}, outpost: false


  def default_map, do: HeroesAscent


  @doc """
  Adds an alias for all defined maps when 'used'.
  """
  defmacro __using__(_) do
    quote do
      alias Entice.Logic.Maps
      unquote(for map <- get_maps do
        quote do: alias unquote(map)
      end)
    end
  end

end
