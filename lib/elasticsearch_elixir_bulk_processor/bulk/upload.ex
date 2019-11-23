defmodule ElasticsearchElixirBulkProcessor.Bulk.Upload do
  def add_requests(bulk_requests) do
    bulk_requests
    |> Stream.map(& &1.__struct__.to_payload(&1))
    |> Enum.join("\n")
    |> ElasticsearchElixirBulkProcessor.Bulk.QueueStage.add()
  end
end
