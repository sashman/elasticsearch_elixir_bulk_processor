defmodule ElasticsearchElixirBulkProcessor.Bulk.BulkStage do
  use GenStage
  alias ElasticsearchElixirBulkProcessor.Bulk.{QueueStage, Client}
  alias ElasticsearchElixirBulkProcessor.Helpers.Events

  # 60mb
  @default_byte_threshold 62_914_560

  @init_state %{queue: [], byte_threshold: @default_byte_threshold}

  @log false

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    {:consumer, @init_state, subscribe_to: [{QueueStage, min_demand: 5, max_demand: 75}]}
  end

  def set_byte_threshold(byte_threshold) when is_integer(byte_threshold) do
    GenServer.cast(__MODULE__, {:set_byte_threshold, byte_threshold})
  end

  def handle_cast({:set_byte_threshold, byte_threshold}, state),
    do: {:noreply, [], %{state | byte_threshold: byte_threshold}}

  def handle_events(events, _from, state) when is_list(events) and length(events) > 0 do
    {to_send, rest} = Events.split_first_bytes(state.queue ++ events, state.byte_threshold)

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
