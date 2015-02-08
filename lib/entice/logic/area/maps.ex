defmodule Entice.Logic.Area.Maps do
  @moduledoc """
  Top-level map macros for convenient access to all defined maps.
  Is mainly used in area.ex where all the maps are defined.
  """
  alias Entice.Utils.Geom.Coord

  defmacro __using__(_) do
    quote do
      alias Entice.Utils.Geom.Coord
      import Entice.Logic.Area.Maps

      @maps []
      @before_compile Entice.Logic.Area.Maps
    end
  end


  defmacro defmap(mapname, opts \\ []) do
    spawn = Keyword.get(opts, :spawn, quote do %Coord{} end)

    quote do
      defmodule unquote(mapname) do
        use Entice.Logic.Area.Maps.Map
        def spawn, do: unquote(spawn)
      end
      @maps [ unquote(mapname) | @maps ]
    end
  end


  defmacro __before_compile__(_) do
    quote do
      unquote(inject_using)

      @doc """
      Simplistic map getter, tries to convert a PascalCase map name to the module atom.
      """
      def get_map(name) do
        try do
          {:ok, ((__MODULE__ |> Atom.to_string) <> "." <> name) |> String.to_existing_atom}
        rescue
          ArgumentError -> {:error, :map_not_found}
        end
      end

      def get_maps, do: @maps
    end
  end


  def inject_using do
    quote unquote: false do
      #adds an alias for all defined maps through using
      defmacro __using__(_) do
        quote do
          unquote(for map <- @maps do
            quote do: alias unquote(map)
          end)
        end
      end
    end
  end
end


defmodule Entice.Logic.Area.Maps.Map do
  @moduledoc """
  This macro puts all common map functions inside the map/area module that uses it
  """
  import Inflex

  defmacro __using__(_) do
    quote do
      alias Entice.Utils.Geom.Coord
      unquote(content(__CALLER__.module))
    end
  end

  defp content(mod) do
    name = mod |> Module.split |> List.last |> to_string
    uname = underscore(name)
    quote do
      def spawn, do: %Coord{}
      def name, do: unquote(name)
      def underscore_name, do: unquote(uname)

      defoverridable [spawn: 0]
    end
  end
end
