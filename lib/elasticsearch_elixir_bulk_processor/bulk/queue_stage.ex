defmodule ElasticsearchElixirBulkProcessor.Bulk.QueueStage do
  use GenStage

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:producer, []}
  end

  def handle_info(_, state), do: {:noreply, [], state}

  def add(events), do: GenServer.cast(__MODULE__, {:add, events})

  def handle_cast({:add, events}, state) when is_list(events) do
    {:noreply, events, state}
  end

  def handle_cast({:add, events}, state), do: {:noreply, [events], state}

  def handle_demand(_, state), do: {:noreply, [], state}
end
