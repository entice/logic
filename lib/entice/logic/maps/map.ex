defmodule Entice.Logic.Map do
  @moduledoc """
  Top-level map macros for convenient access to all defined maps.
  Is mainly used in area.ex where all the maps are defined.
  """
  import Inflex
  alias Entice.Utils.Geom.Coord

  defmacro __using__(_) do
    quote do
      import Entice.Logic.Map

      @maps []
      @before_compile Entice.Logic.Map
    end
  end


  defmacro defmap(mapname, opts \\ []) do
    spawn   = Keyword.get(opts, :spawn, quote do %Coord{} end)
    outpost = Keyword.get(opts, :outpost, quote do true end)

    map_content = content(Macro.to_string(mapname))
    quote do
      defmodule unquote(mapname) do
        alias Entice.Utils.Geom.Coord
        unquote(map_content)
        def spawn, do: unquote(spawn)
        def is_outpost?, do: unquote(outpost)
      end
      @maps [ unquote(mapname) | @maps ]
    end
  end


  defmacro __before_compile__(_) do
    quote do

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


  defp content(name) do
    uname = underscore(name)
    quote do
      def name, do: unquote(name)
      def underscore_name, do: unquote(uname)

      def spawn, do: %Coord{}
      def is_outpost?, do: true

      defoverridable [spawn: 0, is_outpost?: 0]
    end
  end
end
