defmodule ElasticsearchElixirBulkProcessor.Bulk.Elastic do
  def bulk_upload(data, cluster, error_fun \\ & &1) when is_list(data) do
    bulk_data =
      data
      |> Enum.map_join("\n", &Poison.encode!/1)

    1..10
    |> Enum.each(fn _i ->
      Task.async(fn ->
        Elasticsearch.post(cluster, "/_bulk", bulk_data <> "\n")
        |> handle_error(error_fun)
      end)
    end)
  end

  defp handle_error({:error, error}, error_fun) when is_function(error_fun), do: error_fun.(error)
  defp handle_error({:ok, _} = res, _), do: res
end
