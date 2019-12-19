defmodule ElasticsearchElixirBulkProcessor.Helpers.BulkResponse do
  @doc ~S"""

  Given a list of items from a bulk response and the data sent as a string payload return the items that match the error.

  ## Examples

    iex>
    ...> items = [%{"index" => %{}}}, %{"index" => %{"error" => _}}}, %{"index" => %{}}}]
    ...> data = "item\nitem_with_errors\nitem"
    ...> ElasticsearchElixirBulkProcessor.Helpers.BulkResponse.gather_error_items(items, data)
    ["item_with_errors"]

  """
  def gather_error_items(items, data) when is_binary(data) do
    gather_error_items(
      items,
      data
      |> String.split("\n")
    )
  end

  @doc ~S"""

  Given a list of items from a bulk response and the data sent as a list of requests return the items that match the error.

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
