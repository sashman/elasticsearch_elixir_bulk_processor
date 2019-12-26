defmodule ElasticsearchElixirBulkProcessor.Bulk.Payload do
  alias ElasticsearchElixirBulkProcessor.Bulk.{QueueStage, Client}
  alias ElasticsearchElixirBulkProcessor.Helpers.Events

  def send(events, state) do
    events
    |> manage_payload(state, fn to_send ->
      to_send
      |> send_payload(& &1, &default_error_fun/1)
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

  defp default_error_fun(error) do
    IO.inspect("Error: #{inspect(error.error)}")
    error
  end
end
