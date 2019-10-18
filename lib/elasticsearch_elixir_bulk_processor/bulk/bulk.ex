defmodule ElasticsearchElixirBulkProcessor.Bulk.Bulk do
  use GenStage
  alias ElasticsearchElixirBulkProcessor.Bulk.Queue

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    {:consumer, %{}, subscribe_to: [{Queue, min_demand: 10, max_demand: 20}]}
  end

  def handle_events(events, _from, state) do
    # Inspect the events.
    Process.sleep(1000)
    IO.inspect(events, label: "consumer events")

    # We are a consumer, so we would never emit items.
    {:noreply, [], state}
  end
end
