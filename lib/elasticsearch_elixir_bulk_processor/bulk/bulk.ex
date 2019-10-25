defmodule ElasticsearchElixirBulkProcessor.Bulk.Bulk do
  use GenStage
  alias ElasticsearchElixirBulkProcessor.Bulk.Queue

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    {:consumer, %{}, subscribe_to: [{Queue, min_demand: 10, max_demand: 50}]}
  end

  def handle_events(events, _from, state) when is_list(events) and length(events) > 0 do
    Process.sleep(500)
    IO.inspect(events, label: "consumer events")

    {:noreply, [], state}
  end

  def handle_events(_events, _from, state), do: {:noreply, [], state}
end
