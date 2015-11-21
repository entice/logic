defmodule Entice.Logic.MapRegistry do
  @doc """
  Stores all the instances for each map.
  Its state is in the following format: %{map=>entity_id}
  """
  alias Entice.Logic.MapInstance
  alias Entice.Entity

  def start_link,
  do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  def start_instance(map) do
    case get_instance(map) do
      nil ->
        {:ok, entity_id, _entity_pid} = Entity.start
        MapInstance.register(entity_id, map)
        Agent.update(__MODULE__,
          fn state -> state |> Map.update(map, entity_id, fn _id -> entity_id end) end)
        {:ok, entity_id}
      _ ->
        {:error, :instance_already_running}
    end
  end

  def get_instance(map),
  do: Agent.get(__MODULE__, fn state -> state |> Map.get(map) end)

  def instance_stopped(map),
  do: Agent.cast(__MODULE__, fn state -> state |> Map.delete(map) end)
end
