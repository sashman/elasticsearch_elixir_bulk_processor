defmodule ElasticsearchElixirBulkProcessor.Bulk.Payload do
  alias ElasticsearchElixirBulkProcessor.Bulk.{QueueStage, Client}
  alias ElasticsearchElixirBulkProcessor.Helpers.Events

  require Logger

  def send(events, state) do
    events
    |> manage_payload(state, fn to_send ->
      payload =
        to_send
        |> Stream.map(& &1.__struct__.to_payload(&1))
        |> Enum.join("\n")

      :telemetry.execute(
        [:elasticsearch_elixir_bulk_processor, :payload, :send],
        %{
          event_count: length(to_send),
          bytes: byte_size(payload)
        },
        %{
          event_count_threshold: state.event_count_threshold,
          byte_threshold: state.byte_threshold
        }
      )

      send_payload(payload, state.success_function, state.error_function)
    end)
  end

  def send_payload(payload_to_send, sucess_fun, error_fun) do
    payload_to_send
    |> Client.bulk_upload(
      sucess_fun,
      error_fun
    )
  end

  def manage_payload(events, state = %{preserve_event_order: false}, send_fun) do
    {to_send, rest} = Events.split_first_bytes(events, state.byte_threshold)
    {to_send, rest} = split_event_count(to_send, rest, state.event_count_threshold)
    send_fun.(to_send)
    QueueStage.add(rest)
  end

  def manage_payload(events, state, send_fun) do
    Events.chunk_bytes(events, state.byte_threshold)
    |> Enum.map(fn chunk ->
      send_fun.(chunk)
    end)
  end

  defp split_event_count(to_send, rest, nil), do: {to_send, rest}

  defp split_event_count(current_to_send, current_rest, event_count_threshold) do
    {to_send, rest} = Enum.split(current_to_send, event_count_threshold)

    {to_send, rest ++ current_rest}
  end
end
