defmodule ElasticsearchElixirBulkProcessor.Bulk.Queue do
  use GenStage

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    {:producer_consumer, []}
  end

  def push(message) do
    GenStage.cast(__MODULE__, message)
  end

  def handle_cast(event, state) do
    # We are a consumer, so we would never emit items.
    {:noreply, [], state ++ [event]}
  end

  def handle_events(events, _from, number) do
    IO.inspect(events)
    {:noreply, events, number}
  end
end
