defmodule ElasticsearchElixirBulkProcessor.Bulk.BulkStage do
  use GenStage
  alias ElasticsearchElixirBulkProcessor.Bulk.{QueueStage, Client}

  @byte_threshold 31_457_280

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    {:consumer, %{}, subscribe_to: [{QueueStage, min_demand: 10, max_demand: 50}]}
  end

  def handle_events(events, _from, state) when is_list(events) and length(events) > 0 do
    # Process.sleep(500)

    event_sum = Enum.map(events, &byte_size/1) |> Enum.sum()

    payload =
      events
      |> Enum.join("\n")

    payload
    |> Client.bulk_upload(
      ElasticsearchElixirBulkProcessor.ElasticsearchCluster,
      & &1,
      fn error ->
        IO.inspect("Error: #{inspect(error.error)}")
      end
    )

    {:noreply, [], state}
  end

  def handle_events(_events, _from, state), do: {:noreply, [], state}
end
