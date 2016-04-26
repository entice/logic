defmodule Entice.Logic.MapRegistry do
  @doc """
  Stores all the instances for each map.
  Its state is in the following format: %{map=>entity_id}
  """
  alias Entice.Entity
  alias Entice.Entity.Suicide
  alias Entice.Logic.MapInstance


  def start_link,
  do: Agent.start_link(fn -> %{} end, name: __MODULE__)


  @doc "Get or create an instance entity for a specific map"
  def get_or_create_instance(map) when is_atom(map) do
    Agent.get_and_update(__MODULE__, fn state ->
      case fetch_active(map, state) do
        {:ok, entity_id} -> {entity_id, state}
        :error ->
          with {:ok, entity_id, _pid} <- Entity.start,
               :ok                    <- MapInstance.register(entity_id, map),
               new_state              =  Map.put(state, map, entity_id),
               do: {entity_id, new_state}
      end
    end)
  end


  @doc "Stops an instance if not already stopped, effectively killing the entity."
  def stop_instance(map) when is_atom(map) do
    Agent.cast(__MODULE__, fn state ->
      with {:ok, entity_id} <- Map.fetch(state, map),
           :ok              <- MapInstance.unregister(entity_id),
           :ok              <- Suicide.poison_pill(entity_id),
           do: :ok
      state |> Map.delete(map)
    end)
  end


  defp fetch_active(map, state) when is_atom(map) do
    case Map.fetch(state, map) do
      {:ok, entity_id} ->
        if Entity.exists?(entity_id), do: {:ok, entity_id},
                                    else: :error
      _ -> :error
    end
  end
end
