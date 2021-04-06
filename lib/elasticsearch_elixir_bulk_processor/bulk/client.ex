defmodule ElasticsearchElixirBulkProcessor.Bulk.Client do
  require Logger
  alias ElasticsearchElixirBulkProcessor.Helpers.BulkResponse
  use Retry
  alias ElasticsearchElixirBulkProcessor.Bulk.Retry

  def bulk_upload(data, success_fun \\ & &1, error_fun \\ & &1, retry_data_count \\ 0)
      when is_binary(data) and
             is_function(success_fun) and
             is_function(error_fun) do
    data = data <> "\n"

    Logger.debug(data)

    retry with: Retry.policy() do
      send_data(data)
    after
      result -> handle_success(result, success_fun, error_fun, data, retry_data_count)
    else
      error -> handle_error(error, error_fun, data)
    end
  end

  defp handle_success(
         {:ok, %{"errors" => true, "items" => items} = response},
         success_fun,
         error_fun,
         data,
         retry_data_count
       )
       when is_function(error_fun) do
    :telemetry.execute(
      [:elasticsearch_elixir_bulk_processor, :client, :response_success],
      %{
        time: System.monotonic_time(),
        response: response
      }
    )

    BulkResponse.all_items_error?(items)
    |> handle_multiple(items, success_fun, error_fun, data, retry_data_count)
  end

  defp handle_success({:ok, response} = res, success_fun, _, _, _) do
    :telemetry.execute(
      [:elasticsearch_elixir_bulk_processor, :client, :response_success],
      %{
        time: System.monotonic_time(),
        response: response
      }
    )

    success_fun.(res)
  end

  defp handle_error(error, error_fun, data) do
    :telemetry.execute(
      [:elasticsearch_elixir_bulk_processor, :client, :response_error],
      %{
        time: System.monotonic_time(),
        error: error
      },
      %{
        data: data,
        errored_item_count: errored_item_count(error)
      }
    )

    error_fun.(%{error: error, data: data})
  end

  defp errored_item_count({_, %{"items" => items}}), do: length(items)
  defp errored_item_count(_), do: 0

  defp handle_multiple(_, _, _, error_fun, data, 3 = max_retry_count),
    do:
      error_fun.(%{
        error: "Max partial error retry count exceeded: #{max_retry_count}",
        data: data
      })

  defp handle_multiple(
         _all_errored = false,
         items,
         success_fun,
         error_fun,
         data,
         retry_data_count
       ) do
    data_to_retry = BulkResponse.gather_error_items(items, data)

    Logger.debug("Retrying #{retry_data_count}")
    Logger.debug(data_to_retry)

    data_to_retry |> bulk_upload(success_fun, error_fun, retry_data_count + 1)
  end

  defp handle_multiple(_all_errored = true, items, success_fun, error_fun, data, retry_data_count) do
    retry with: Retry.policy() do
      send_data(data)
      |> convert_multiple_to_error()
    after
      result -> handle_success(result, success_fun, error_fun, data, retry_data_count)
    else
      error ->
        handle_error(
          error,
          error_fun,
          BulkResponse.gather_error_items(items, data)
        )
    end
  end

  def convert_multiple_to_error({:ok, %{"errors" => true, "items" => items}}) do
    {:error, %{"errors" => true, "items" => items}}
  end

  def convert_multiple_to_error(response), do: response

  defp send_data(data) do
    start_time = System.monotonic_time()

    :telemetry.execute(
      [:elasticsearch_elixir_bulk_processor, :client, :elasticsearch_post, :start],
      %{time: start_time, bytes: byte_size(data)},
      %{data: data}
    )

    result =
      ElasticsearchElixirBulkProcessor.ElasticsearchCluster
      |> Elasticsearch.post("/_bulk", data)

    end_time = System.monotonic_time()

    :telemetry.execute(
      [:elasticsearch_elixir_bulk_processor, :client, :elasticsearch_post, :stop],
      %{
        time: end_time,
        duration: end_time - start_time,
        bytes: byte_size(data)
      },
      %{data: data}
    )

    result
  end
end
