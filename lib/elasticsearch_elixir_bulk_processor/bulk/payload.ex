defmodule ElasticsearchElixirBulkProcessor.Bulk.Payload do
  alias ElasticsearchElixirBulkProcessor.Bulk.{QueueStage, Client}
  alias ElasticsearchElixirBulkProcessor.Helpers.Events

  @log false

  def send(events, state) do
    events
    |> manage_payload(state, fn to_send ->
      to_send
      |> send_payload(& &1, &default_error_fun/1)
      |> log(to_send)
    end)
  end

  def send_payload(payload_to_send, sucess_fun, error_fun) do
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

  def manage_payload(events, state = %{preserve_event_order: false}, send_fun) do
    {to_send, rest} = Events.split_first_bytes(events, state.byte_threshold)
    send_fun.(to_send)
    QueueStage.add(rest)
  end

  def manage_payload(events, state, send_fun) do
    Events.chunk_bytes(events, state.byte_threshold)
    |> Enum.map(fn chunk ->
      send_fun.(chunk)
    end)
  end

  def default_error_fun(error) do
    IO.inspect("Error: #{inspect(error.error)}")
    error
  end

  def log(time, to_send) do
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
