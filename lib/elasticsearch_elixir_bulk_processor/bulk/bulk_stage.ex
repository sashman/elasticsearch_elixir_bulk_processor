defmodule ElasticsearchElixirBulkProcessor.Bulk.BulkStage do
  use GenStage
  alias ElasticsearchElixirBulkProcessor.Bulk.{QueueStage, Client}
  alias ElasticsearchElixirBulkProcessor.Helpers.Events

  # @byte_threshold 15_728_640
  # @byte_threshold 31_457_280
  # @byte_threshold 47_185_920
  @byte_threshold 62_914_560
  # @byte_threshold 104_857_600

  @log false

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    {:consumer, %{queue: []}, subscribe_to: [{QueueStage, min_demand: 5, max_demand: 75}]}
  end

  def handle_events(events, _from, state) when is_list(events) and length(events) > 0 do
    {to_send, rest} = Events.split_first_bytes(state.queue ++ events, @byte_threshold)

    bytes_sent = to_send |> Events.byte_sum()

    payload = to_send |> Enum.join("\n")

    {time, _} =
      :timer.tc(fn ->
        payload
        |> Client.bulk_upload(
          ElasticsearchElixirBulkProcessor.ElasticsearchCluster,
          & &1,
          fn error ->
            IO.inspect("Error: #{inspect(error.error)}")
          end
        )
      end)

    if @log do
      IO.inspect(
        "events: #{to_send |> length} size: #{Size.humanize!(bytes_sent)}  took: #{
          time / 1_000_000
        }s  b/s: #{(bytes_sent / (time / 1_000_000)) |> round |> Size.humanize!()}"
      )
    end

    QueueStage.add(rest)
    {:noreply, [], state}
  end

  def handle_events(_events, _from, state), do: {:noreply, [], state}
end
