defmodule Entice.Logic.Npc do
  use Entice.Logic.Map
  alias Entice.Entity
  alias Entice.Logic.{Npc, Vitals}
  alias Entice.Logic.Player.{Name, Position, Level}

  defstruct npc_model_id: :dhuum, init_pos: %Position{}


  def spawn(name, model, %Position{} = position, %{seeks: seeks} \\ %{seeks: false})
  when is_binary(name) and is_atom(model) do
    {:ok, id, pid} = Entity.start()
    Npc.register(id, name, model, position)
    Vitals.register(id)
    Movement.register(id)
    #if seeks, do: Seek.register(id)
    {:ok, id, pid}
  end


  def register(entity, name, model, %Position{} = position)
  when is_binary(name) and is_atom(model) do
    entity |> Entity.attribute_transaction(fn (attrs) ->
      attrs
      |> Map.put(Name,     %Name{name: name})
      |> Map.put(Position, position)
      |> Map.put(Npc,      %Npc{npc_model_id: model, init_pos: position})
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
