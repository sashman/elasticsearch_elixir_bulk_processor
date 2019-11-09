defmodule ElasticsearchElixirBulkProcessor.Bulk.DirectUpload do
  alias ElasticsearchElixirBulkProcessor.Bulk.Client

  def add_requests(bulk_requests) do
    bulk_requests
    |> Stream.map(& &1.__struct__.to_payload(&1))
    |> Enum.join("\n")
    |> Client.bulk_upload(ElasticsearchElixirBulkProcessor.ElasticsearchCluster)
  end
end
