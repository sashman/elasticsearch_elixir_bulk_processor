defmodule ElasticsearchElixirBulkProcessor.Bulk.Retry do
  use Retry

  @doc ~S"""

  Reads the application variable `retry_function` and uses as the result as the retyr policy.

  [ElixirRetry](https://github.com/safwank/ElixirRetry) is used for retrying. The default policy is:

  ```
  constant_backoff(100) |> Stream.take(5)
  ```

  ## Examples

    iex> use Retry
    ...> Application.put_env(:elasticsearch_elixir_bulk_processor, :retry_function, fn ->
    ...>  constant_backoff(100) |> Stream.take(2)
    ...> end)
    ...> ElasticsearchElixirBulkProcessor.Bulk.Retry.policy() |> Enum.to_list()
    'dd'

    iex> use Retry
    ...> Application.put_env(:elasticsearch_elixir_bulk_processor, :retry_function, nil)
    ...> ElasticsearchElixirBulkProcessor.Bulk.Retry.policy() |> Enum.to_list()
    'ddddd'

  """
  def policy do
    Application.get_env(:elasticsearch_elixir_bulk_processor, :retry_function)
    |> case do
      nil -> default()
      function -> function.()
    end
  end

  def default do
    constant_backoff(100) |> Stream.take(5)
  end
end
