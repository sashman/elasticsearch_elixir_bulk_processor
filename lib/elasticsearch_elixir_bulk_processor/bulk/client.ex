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
         {:ok, %{"errors" => true, "items" => items}},
         success_fun,
         error_fun,
         data,
         retry_data_count
       )
       when is_function(error_fun) do
    BulkResponse.all_items_error?(items)
    |> handle_multiple(items, success_fun, error_fun, data, retry_data_count)
  end

  defp handle_success({:ok, _} = res, success_fun, _, _, _), do: success_fun.(res)

  defp handle_error(error, error_fun, data),
    do: error_fun.(%{error: error, data: data})

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

  defp send_data(data),
    do:
      ElasticsearchElixirBulkProcessor.ElasticsearchCluster
      |> Elasticsearch.post("/_bulk", data)
end
