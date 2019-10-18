defmodule ElasticsearchElixirBulkProcessor.Bulk.Queue do
  use GenStage

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    {:producer, []}
  end

  def push(event) do
    GenStage.cast(__MODULE__, event)
  end

  def handle_cast(request, state) do
    {:noreply, [], state ++ [request]}
  end

  def handle_demand(demand, state) when demand > 0 do
    IO.inspect(demand, label: "handle_demand")

    events =
      for i <-
            0..(demand - 1) do
        "test#{i}"
      end ++ state

    {:noreply, events, []}
  end
end
