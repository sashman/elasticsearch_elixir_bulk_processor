defmodule ElasticsearchElixirBulkProcessor.Bulk.Upload do
  def add_requests(bulk_requests) do
    bulk_requests
    |> ElasticsearchElixirBulkProcessor.Bulk.QueueStage.add()
  end
end
