defmodule ElasticsearchElixirBulkProcessor.Bulk.Retry do
  use Retry

  def policy do
    Application.get_env(:elasticsearch_elixir_bulk_processor, :retry_function)
    |> case do
      nil -> default()
      function -> function
    end
  end

  def default do
    constant_backoff(100) |> Stream.take(5)
  end
end
