defmodule Entice.Logic.MapRegistry do
  @doc """
  Stores all the instances for each map.
  Its state follows the following format: %{map=>entity_id}
  """
  use GenServer
  alias Entice.Logic.MapInstance

  def start_link,
  do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  def start_instance(map) do
    case get_instance(map) do
      nil ->
        {:ok, entity_id, entity_pid} = Entity.start
        MapInstance.register(entity_id, map)
        Agent.update(__MODULE__,
          fn state -> state |> Map.update(map, entity_id, fn id -> entity_id end) end)
        {:ok, entity_id}
      _ ->
        {:error, :instance_already_running}
    end
  end

  def get_instance(map),
  do: Agent.get(__MODULE__, fn state -> state |> Map.get(map) end)

  def handle_cast({:instance_stopped, map}, state),
  do: {:noreply, state |> Map.delete(map)}
end
