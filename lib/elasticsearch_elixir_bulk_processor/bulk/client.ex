defmodule ElasticsearchElixirBulkProcessor.Bulk.Client do
  alias ElasticsearchElixirBulkProcessor.Helpers.BulkResponse
  use Retry
  alias ElasticsearchElixirBulkProcessor.Bulk.Retry

  def bulk_upload(data, success_fun \\ & &1, error_fun \\ & &1)
      when is_binary(data) and
             is_function(success_fun) and
             is_function(error_fun) do
    data = data <> "\n"

    retry with: Retry.policy() do
      send_data(data)
    after
      result -> handle_success(result, success_fun, error_fun, data)
    else
      error -> handle_error(error, error_fun, data)
    end
  end

  defp handle_success({:ok, %{"errors" => true, "items" => items}}, success_fun, error_fun, data)
       when is_function(error_fun) do
    BulkResponse.all_items_error?(items)
    |> handle_multiple(items, success_fun, error_fun, data)
  end

  defp handle_success({:ok, _} = res, success_fun, _, _), do: success_fun.(res)

  defp handle_error(error, error_fun, data),
    do: error_fun.(%{error: error, data: data})

  defp handle_multiple(_all_errored = false, items, success_fun, error_fun, data) do
    BulkResponse.gather_error_items(items, data)
    |> bulk_upload(success_fun, error_fun)
  end

  defp handle_multiple(_all_errored = true, items, success_fun, error_fun, data) do
    retry with: Retry.policy() do
      send_data(data)
      |> convert_multiple_to_error()
    after
      result -> handle_success(result, success_fun, error_fun, data)
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
