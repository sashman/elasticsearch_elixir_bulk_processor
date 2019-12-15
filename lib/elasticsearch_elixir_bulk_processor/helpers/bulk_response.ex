defmodule ElasticsearchElixirBulkProcessor.Helpers.BulkResponse do
  def gather_error_items(items, data) when is_binary(data) do
    gather_error_items(
      items,
      data
      |> String.split("\n")
    )
  end

  @doc ~S"""

  Split list of strings into first chunk of given byte size and rest of the list.

  ## Examples

    iex>
    ...> items = [%{"index" => %{}}}, %{"index" => %{"error" => _}}}, %{"index" => %{}}}]
    ...> data = ["item", "item_with_errors", "item"]
    ...> ElasticsearchElixirBulkProcessor.Helpers.BulkResponse.gather_error_items(items, data)
    ["item_with_errors"]

  """
  def gather_error_items(items, data) when is_list(data) do
    data
    |> Stream.zip(items)
    |> Stream.filter(fn
      {_, %{"index" => %{"error" => _}}} -> true
      {_, %{"update" => %{"error" => _}}} -> true
      {_, %{"create" => %{"error" => _}}} -> true
      {_, %{"delte" => %{"error" => _}}} -> true
      {_, _} -> false
    end)
    |> Enum.map(fn {data, _} -> data end)
  end
end
