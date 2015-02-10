defmodule Entice.Test.Spy do
  @moduledoc """
  Can be injected into any entity for testing purposes.
  You can pass in your own process id and you will receive any
  event that occurs to the entity.
  """
  use Entice.Entity.Behaviour
  alias Entice.Test.Spy


  @doc """
  Setup method, pid is your own pid and will be stored by the entity.
  """
  def inject_into(entity, pid) when is_pid(pid),
  do: Entice.Entity.put_behaviour(entity, Spy, pid)


  def init(id, attributes, pid), do: {:ok, attributes, {id, pid}}


  def handle_event(event, attributes, {id, pid}) do
    send(pid, %{sender: id, event: event})
    {:ok, attributes, {id, pid}}
  end
end
