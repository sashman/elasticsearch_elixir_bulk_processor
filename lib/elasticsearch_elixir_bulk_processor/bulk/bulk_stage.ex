defmodule ElasticsearchElixirBulkProcessor.Bulk.BulkStage do
  use GenStage
  alias ElasticsearchElixirBulkProcessor.Bulk.{QueueStage, Client}

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    {:consumer, %{}, subscribe_to: [{QueueStage, min_demand: 10, max_demand: 50}]}
  end

  def handle_events(events, _from, state) when is_list(events) and length(events) > 0 do
    # Process.sleep(500)
    # IO.inspect(events, label: "consumer events")
    events
    |> Enum.join("\n")
    |> Client.bulk_upload(
      ElasticsearchElixirBulkProcessor.ElasticsearchCluster,
      & &1,
      &IO.inspect/1
    )

    {:noreply, [], state}
  end

  def handle_events(_events, _from, state), do: {:noreply, [], state}
end
