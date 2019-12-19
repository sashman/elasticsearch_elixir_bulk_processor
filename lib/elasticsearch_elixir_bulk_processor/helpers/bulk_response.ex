defmodule ElasticsearchElixirBulkProcessor.Helpers.BulkResponse do
  @doc ~S"""

  Given a list of items from a bulk response and the data sent as a list of requests return the items that match the error.

  ## Examples

    iex> items = [%{"index" => %{}}, %{"update" => %{"error" => %{}}}, %{"create" => %{}}, %{"delete" => %{}}]
    ...> data = ["item", "item_with_errors", "item", "item"]
    ...> ElasticsearchElixirBulkProcessor.Helpers.BulkResponse.gather_error_items(items, data)
    ["item_with_errors"]

    iex> items = [%{"index" => %{"error" => %{}}}, %{"update" => %{"error" => %{}}}, %{"create" => %{"error" => %{}}}, %{"delete" => %{"error" => %{}}}]
    ...> data = ["item1", "item2", "item3", "item4"]
    ...> ElasticsearchElixirBulkProcessor.Helpers.BulkResponse.gather_error_items(items, data)
    ["item1", "item2", "item3", "item4"]

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

  @doc ~S"""

  Given a list of items from a bulk response and the data sent as a string payload return the items that match the error.

  ## Examples

    iex> items = [%{"index" => %{}}, %{"update" => %{"error" => %{}}}, %{"create" => %{}}, %{"delete" => %{}}]
    ...> data = "item\nitem_with_errors\nitem\nitem"
    ...> ElasticsearchElixirBulkProcessor.Helpers.BulkResponse.gather_error_items(items, data)
    ["item_with_errors"]

  """
  def gather_error_items(items, data) when is_binary(data) do
    data_list =
      data
      |> String.split("\n")

    gather_error_items(items, data_list)
  end
end
