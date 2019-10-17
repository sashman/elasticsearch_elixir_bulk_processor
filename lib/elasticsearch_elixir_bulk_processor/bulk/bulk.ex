defmodule ElasticsearchElixirBulkProcessor.Bulk.Bulk do
  use GenStage

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    {:producer_consumer, %{}, subscribe_to: [ElasticsearchElixirBulkProcessor.Bulk.Queue]}
  end

  def handle_events(events, _from, state) do
    # Inspect the events.
    IO.inspect(events)

    # We are a consumer, so we would never emit items.
    {:noreply, [], state}
  end

  def handle_subscribe(:producer, _options, from, state) do
    new_state = %{state | subscription: from}
    {:manual, new_state}
  end

  def pull() do
    GenStage.call(__MODULE__)
  end

  def handle_call(event, state) do
    # We are a consumer, so we would never emit items.
    {:noreply, [], state ++ [event]}
  end
end
