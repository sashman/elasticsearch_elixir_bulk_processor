defmodule ElasticsearchElixirBulkProcessor.Items.Item do
  @callback to_payload(ElasticsearchElixirBulkProcessor.Items.Item.t()) :: String.t()
end
