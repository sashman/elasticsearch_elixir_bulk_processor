defmodule ElasticsearchElixirBulkProcessor.Bulk.Elastic do
  def bulk_upload(data, cluster) when is_list(data) do
    bulk_data =
      data
      |> Enum.map_join("\n", &Poison.encode!/1))

    {:ok, res} = ElasticSearch.post(cluster, "/_bulk", bulk_data)
  end

  def bulk_upload(data, cluster) when is_map(data) do
    {:ok, res} = ElasticSearch.post(cluster, "/_bulk", data)
  end
end
