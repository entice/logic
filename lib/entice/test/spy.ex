defmodule Entice.Test.Spy do
  @moduledoc """
  Can be injected into any entity for testing purposes.
  You can pass in your own process id and you will receive any
  event that occurs to the entity.
  """
  alias Entice.Entity
  alias Entice.Test.Spy


  defstruct reporter: nil


  def register(entity, report_to) when is_pid(report_to),
  do: Entity.put_behaviour(entity, Spy.Behaviour, report_to)


  def unregister(entity),
  do: Entity.remove_behaviour(entity, Spy.Behaviour)


  defmodule Behaviour do
    use Entice.Entity.Behaviour

    def init(entity, pid),
    do: {:ok, entity |> put_attribute(%Spy{reporter: pid})}

    def handle_event(event, %Entity{id: id, attributes: %{Spy => %Spy{reporter: pid}}} = entity) do
      send(pid, %{sender: id, event: event})
      {:ok, entity}
    end

    def terminate(_reason, entity),
    do: {:ok, entity |> remove_attribute(Spy)}
  end
end
