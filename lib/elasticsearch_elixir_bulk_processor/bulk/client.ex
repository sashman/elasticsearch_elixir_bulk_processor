defmodule ElasticsearchElixirBulkProcessor.Bulk.Client do
  @spec bulk_upload(list, Elasticsearch.Cluster.t(), fun, fun) :: Task.t()
  def bulk_upload(data, cluster, success_fun \\ & &1, error_fun \\ & &1)
      when is_list(data) and
             is_function(success_fun) and
             is_function(error_fun) do
    bulk_data =
      data
      |> Enum.map_join("\n", &Poison.encode!/1)

    Elasticsearch.post(cluster, "/_bulk", bulk_data <> "\n")
    |> handle_error(success_fun, error_fun)
  end

  defp handle_error({:error, error}, _, error_fun),
    do: error_fun.(error)

  defp handle_error({:ok, %{"errors" => true, "items" => items}}, _, error_fun)
       when is_function(error_fun),
       do: parallel_map(items, error_fun)

  defp handle_error({:ok, _} = res, success_fun, _), do: success_fun.(res)

  defp parallel_map(list, fun) do
    list
    |> Enum.map(fn item ->
      Task.async(fn -> fun.(item) end)
    end)
  end
end
