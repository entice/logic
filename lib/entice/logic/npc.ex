defmodule Entice.Logic.Npc do
  use Entice.Logic.Map
  alias Entice.Entity
  alias Entice.Logic.{Npc, Vitals, Movement, Seek}
  alias Entice.Logic.Player.{Name, Position, Level}

  defstruct npc_model_id: :dhuum, init_coord: %Position{}, map: nil

  #I'd rather pass something like fn(pos1, pos2) -> Geom.Ai.Astar.findpath(map.nav_mesh, pos1, pos2) end
  #from map_instance and then override func in this module but can't figure it out
  def spawn(map, name, model, %Position{} = position, opts \\ [])
  when is_binary(name) and is_atom(model) do
    {:ok, id, pid} = Entity.start()
    Npc.register(id, map, name, model, position)
    Vitals.register(id)
    if opts[:seeks] do
      Seek.register(id)
      Movement.register(id, auto_updating?: true)
    else
      Movement.register(id)
    end
    {:ok, id, pid}
  end


  def register(entity, map, name, model, %Position{} = position)
  when is_binary(name) and is_atom(model) do
    entity |> Entity.attribute_transaction(fn (attrs) ->
      attrs
      |> Map.put(Name,     %Name{name: name})
      |> Map.put(Position, position)
      |> Map.put(Npc,      %Npc{npc_model_id: model, init_coord: position.coord, map: map})
      |> Map.put(Level,    %Level{level: 20})
    end)
  end


  def unregister(entity) do
    entity |> Entity.attribute_transaction(fn (attrs) ->
      attrs
      |> Map.delete(Name)
      |> Map.delete(Position)
      |> Map.delete(Npc)
      |> Map.delete(Level)
    end)
  end


  def attributes(entity),
  do: Entity.take_attributes(entity, [Name, Position, Level, Npc])
end
