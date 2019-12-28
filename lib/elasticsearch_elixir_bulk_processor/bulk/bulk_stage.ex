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
    event_count_threshold: @default_event_count_threshold,
    success_function: &ElasticsearchElixirBulkProcessor.Bulk.Handlers.default_success/1,
    error_function: &ElasticsearchElixirBulkProcessor.Bulk.Handlers.default_error/1
  }

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    preserve_event_order =
      Application.get_env(:elasticsearch_elixir_bulk_processor, :preserve_event_order)

    success_fun = Application.get_env(:elasticsearch_elixir_bulk_processor, :success_function)

    error_fun = Application.get_env(:elasticsearch_elixir_bulk_processor, :error_function)

    {:consumer,
     %{
       @init_state
       | preserve_event_order: preserve_event_order,
         success_function: success_fun,
         error_function: error_fun
     }, subscribe_to: [{QueueStage, min_demand: 5, max_demand: 75}]}
  end

  def set_byte_threshold(byte_threshold) when is_integer(byte_threshold) do
    GenServer.cast(__MODULE__, {:set, :byte_threshold, byte_threshold})
  end

  def set_preserve_event_order(preserve_event_order) when is_boolean(preserve_event_order) do
    GenServer.cast(__MODULE__, {:set, :preserve_event_order, preserve_event_order})
  end

  def set_event_count_threshold(event_count_threshold)
      when (is_integer(event_count_threshold) and event_count_threshold > 0) or
             is_nil(event_count_threshold) do
    GenServer.cast(__MODULE__, {:set, :event_count_threshold, event_count_threshold})
  end

  def handle_cast({:set, setting_name, value}, state)
      when setting_name in [:byte_threshold, :preserve_event_order, :event_count_threshold],
      do: {:noreply, [], state |> Map.put(setting_name, value)}

  def handle_events(events, _from, state) when is_list(events) and length(events) > 0 do
    Payload.send(events, state)
    {:noreply, [], state}
  end
end
