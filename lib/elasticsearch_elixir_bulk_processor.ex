defmodule ElasticsearchElixirBulkProcessor do
  alias ElasticsearchElixirBulkProcessor.Bulk.{BulkStage, Upload}

  @moduledoc """
  Elasticsearch Elixir Bulk Processor is a configurable manager for efficiently inserting data into Elasticsearch.
  This processor uses genstages for handling backpressure, and various settings to control the bulk payloads being uploaded to Elasticsearch.

  Inspired by the [Java Bulk Processor](https://www.elastic.co/guide/en/elasticsearch/client/java-api/current/java-docs-bulk-processor.html)

  ## Configuration

  ### Elasticsearch endpoint

  Can be configurate via the `ELASTICSEARCH_URL` environment variable, defaults to: `"http://localhost:9200"`.

  ### Action count

  Number of actions/items to send per bulk (can be changed at run time)

  ```
  ElasticsearchElixirBulkProcessor.set_event_count_threshold(100)
  ```

  ### Byte size

  Max number of bytes to send per bulk (can be changed at run time)

  ```
  ElasticsearchElixirBulkProcessor.set_byte_threshold(100)
  ```

  ### Action order

  Preservation of order of actions/items

  ```
  config :elasticsearch_elixir_bulk_processor, preserve_event_order: false
  ```

  ### Retries

  Retry policy, this uses the [ElixirRetry](https://github.com/safwank/ElixirRetry) DSL. See `ElasticsearchElixirBulkProcessor.Bulk.Retry.policy`.

  ```
  config :elasticsearch_elixir_bulk_processor, retry_function: &MyApp.Retry.policy/0
  ```

  Default: `constant_backoff(100) |> Stream.take(5)`

  ### Success and error handlers

  The callbacks on a successful upload or in case of failed items or failed request can bet set through the config.
  On success, the handler is called with the Elasticsearch bulk request. On failure, the hanlder is called with`%{data: any, error: any}`, `data` being the original payload and `error` being the response or HTTP error.
  See `ElasticsearchElixirBulkProcessor.Bulk.Handlers`.

  ```
  config :elasticsearch_elixir_bulk_processor,
    success_function: &MyApp.success_handler/1,
    error_function: &MyApp.error_handler/1
  ```

  """

  @doc """
  Send a list of request items to ELasticsearch. This mechanism uses GenStages for back pressure.
  NOTE: It should be completely reasonable to use this function by passing single element lists, the mechanism aggregates the items together prior to sending them.

  The list elements must be structs:
    * `ElasticsearchElixirBulkProcessor.Items.Index`
    * `ElasticsearchElixirBulkProcessor.Items.Create`
    * `ElasticsearchElixirBulkProcessor.Items.Update`
    * `ElasticsearchElixirBulkProcessor.Items.Delete`

  ## Examples

      iex> alias ElasticsearchElixirBulkProcessor.Items.Index
      ...> [
      ...>  %Index{index: "test_index", source: %{"field" => "value1"}},
      ...>  %Index{index: "test_index", source: %{"field" => "value2"}},
      ...>  %Index{index: "test_index", source: %{"field" => "value3"}}
      ...> ]
      ...> |> ElasticsearchElixirBulkProcessor.send_requests()
      :ok

  """
  @spec send_requests(list(ElasticsearchElixirBulkProcessor.Items.Item.t())) :: :ok
  def send_requests(bulk_items) when is_list(bulk_items) do
    :telemetry.execute(
      [:elasticsearch_elixir_bulk_processor, :send_requests],
      %{bulk_items: bulk_items}
    )

    Upload.add_requests(bulk_items)
  end

  @doc """
  Set the maximum number of bytes to send to elasticsearch per bulk request.

  ## Examples

      iex> ElasticsearchElixirBulkProcessor.set_byte_threshold(10)
      :ok

  """
  @spec set_byte_threshold(integer()) :: :ok
  def set_byte_threshold(bytes) do
    BulkStage.set_byte_threshold(bytes)
  end

  @doc """
  Set the maximum count of items to send to elasticsearch per bulk request.

  ## Examples

      iex> ElasticsearchElixirBulkProcessor.set_byte_threshold(10)
      :ok

  """
  @spec set_event_count_threshold(integer()) :: :ok
  def set_event_count_threshold(count) do
    BulkStage.set_event_count_threshold(count)
  end
end
