defmodule ElasticsearchElixirBulkProcessor.Bulk.BulkStage do
  use GenStage
  alias ElasticsearchElixirBulkProcessor.Bulk.{QueueStage, Client}
  alias ElasticsearchElixirBulkProcessor.Helpers.Events

  @log false

  # 60mb
  @default_byte_threshold 62_914_560

  @init_state %{
    queue: [],
    byte_threshold: @default_byte_threshold,
    preserve_event_order: false
  }

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    preserve_event_order =
      Application.get_env(:elasticsearch_elixir_bulk_processor, :preserve_event_order)

    {:consumer, %{@init_state | preserve_event_order: preserve_event_order},
     subscribe_to: [{QueueStage, min_demand: 5, max_demand: 75}]}
  end

  def set_byte_threshold(byte_threshold) when is_integer(byte_threshold) do
    GenServer.cast(__MODULE__, {:set_byte_threshold, byte_threshold})
  end

  def set_preserve_event_order(preserve_event_order) when is_boolean(preserve_event_order) do
    GenServer.cast(__MODULE__, {:set_preserve_event_order, preserve_event_order})
  end

  def handle_cast({:set_byte_threshold, byte_threshold}, state),
    do: {:noreply, [], %{state | byte_threshold: byte_threshold}}

  def handle_cast({:set_preserve_event_order, preserve_event_order}, state),
    do: {:noreply, [], %{state | preserve_event_order: preserve_event_order}}

  def handle_events(events, _from, state) when is_list(events) and length(events) > 0 do
    events
    |> manage_payload(state, fn to_send ->
      to_send
      |> send_payload(& &1, &default_error_fun/1)
      |> log(to_send)
    end)

    {:noreply, [], state}
  end

  def handle_events(_events, _from, state), do: {:noreply, [], state}

  defp send_payload(payload_to_send, sucess_fun, error_fun) do
    {time, _} =
      :timer.tc(fn ->
        payload_to_send
        |> Enum.join("\n")
        |> Client.bulk_upload(
          sucess_fun,
          error_fun
        )
      end)

    time
  end

  defp manage_payload(events, state = %{preserve_event_order: false}, send_fun) do
    {to_send, rest} = Events.split_first_bytes(events, state.byte_threshold)
    send_fun.(to_send)
    QueueStage.add(rest)
  end

  defp manage_payload(events, state, send_fun) do
    Events.chunk_bytes(events, state.byte_threshold)
    |> Enum.map(fn chunk ->
      send_fun.(chunk)
    end)
  end

  defp default_error_fun(error) do
    IO.inspect("Error: #{inspect(error.error)}")
  end

  defp log(time, to_send) do
    if @log do
      bytes_sent = to_send |> Events.byte_sum()

      IO.inspect(
        "events: #{to_send |> length} size: #{Size.humanize!(bytes_sent)}  took: #{
          time / 1_000_000
        }s  b/s: #{(bytes_sent / (time / 1_000_000)) |> round |> Size.humanize!()}"
      )
    end
  end
end
