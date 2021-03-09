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
      {_, %{"delete" => %{"error" => _}}} -> true
      {_, _} -> false
    end)
    |> Enum.map(fn {data, _} -> data end)
  end

  @doc ~S"""

  Given a list of items from a bulk response and the data sent as a string payload return the items that match the error. Incoming data is split every second new line.

  ## Examples

    iex> items = [%{"index" => %{}}, %{"update" => %{"error" => %{}}}, %{"create" => %{}}, %{"delete" => %{}}]
    ...> data = "meta\nitem\nmeta_with_errors\nitem_with_errors\nmeta\nitem\nmeta\nitem"
    ...> ElasticsearchElixirBulkProcessor.Helpers.BulkResponse.gather_error_items(items, data)
    "meta_with_errors\nitem_with_errors"

    iex> items = [%{"index" => %{"error" => %{}}}, %{"update" => %{"error" => %{}}}, %{"create" => %{"error" => %{}}}, %{"delete" => %{"error" => %{}}}]
    ...> data = "meta\nitem1\nmeta\nitem2\nmeta\nitem3\nmeta\nitem4"
    ...> ElasticsearchElixirBulkProcessor.Helpers.BulkResponse.gather_error_items(items, data)
    "meta\nitem1\nmeta\nitem2\nmeta\nitem3\nmeta\nitem4"

  """
  def gather_error_items(items, data) when is_binary(data) do
    data_list =
      data
      |> String.split("\n")
      |> Stream.chunk_every(2)
      |> Enum.map(&Enum.join(&1, "\n"))

    gather_error_items(items, data_list)
    |> Enum.join("\n")
  end

  @doc ~S"""

  Given a list of items return true if all have an error.

  ## Examples

    iex> items = [%{"index" => %{"error" => %{}}}, %{"update" => %{"error" => %{}}}, %{"create" => %{"error" => %{}}}, %{"delete" => %{"error" => %{}}}]
    ...> ElasticsearchElixirBulkProcessor.Helpers.BulkResponse.all_items_error?(items)
    true

    iex> items = [%{"index" => %{}}, %{"update" => %{"error" => %{}}}, %{"create" => %{}}, %{"delete" => %{}}]
    ...> ElasticsearchElixirBulkProcessor.Helpers.BulkResponse.all_items_error?(items)
    false

  """
  def all_items_error?(items),
    do:
      Enum.all?(items, fn
        %{"index" => %{"error" => _}} -> true
        %{"update" => %{"error" => _}} -> true
        %{"create" => %{"error" => _}} -> true
        %{"delete" => %{"error" => _}} -> true
        _ -> false
      end)
end
