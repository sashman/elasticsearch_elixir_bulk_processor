defmodule ElasticsearchElixirBulkProcessor.Items.Item do
  @type item :: __MODULE__
  @callback to_payload(item) :: String.t()
end
