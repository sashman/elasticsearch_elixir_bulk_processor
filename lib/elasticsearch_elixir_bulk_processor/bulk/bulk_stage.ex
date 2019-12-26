defmodule ElasticsearchElixirBulkProcessor.Bulk.BulkStage do
  use GenStage
  alias ElasticsearchElixirBulkProcessor.Bulk.{QueueStage, Payload}

  # 60mb
  @default_byte_threshold 62_914_560

  @default_event_count_threshold nil

  @init_state %{
    queue: [],
    byte_threshold: @default_byte_threshold,
    preserve_event_order: false,
    event_count_threshold: @default_event_count_threshold
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

  def set_event_count_threshold(event_count_threshold)
      when (is_integer(event_count_threshold) and event_count_threshold > 0) or
             is_nil(event_count_threshold) do
    GenServer.cast(__MODULE__, {:set_event_count_threshold, event_count_threshold})
  end

  def handle_cast({:set_byte_threshold, value}, state),
    do: {:noreply, [], %{state | byte_threshold: value}}

  def handle_cast({:set_preserve_event_order, value}, state),
    do: {:noreply, [], %{state | preserve_event_order: value}}

  def handle_cast({:set_event_count_threshold, value}, state),
    do: {:noreply, [], %{state | event_count_threshold: value}}

  def handle_events(events, _from, state) when is_list(events) and length(events) > 0 do
    Payload.send(events, state)
    {:noreply, [], state}
  end

  def handle_events(_events, _from, state), do: {:noreply, [], state}
end
