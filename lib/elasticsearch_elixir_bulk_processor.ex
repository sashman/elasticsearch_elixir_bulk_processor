defmodule ElasticsearchElixirBulkProcessor do
  alias ElasticsearchElixirBulkProcessor.Bulk.BulkStage

  @moduledoc """
  Documentation for ElasticsearchElixirBulkProcessor.
  """

  @doc """
  Set the maximum number of bytes to send to elasticsearch per bulk request.

  ## Examples

      iex> ElasticsearchElixirBulkProcessor.set_byte_threshold(10)
      :world

  """
  def set_byte_threshold(bytes) do
    BulkStage.set_byte_threshold(bytes)
  end
end
