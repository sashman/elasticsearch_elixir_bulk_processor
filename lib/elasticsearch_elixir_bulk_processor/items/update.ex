defmodule ElasticsearchElixirBulkProcessor.Items.Update do
  @behaviour ElasticsearchElixirBulkProcessor.Items.Item
  @enforce_keys [:index, :id, :source]
  defstruct [
    :index,
    :id,
    :retry_on_conflict,
    :return_source,
    :source
  ]

  @doc ~S"""

  ## Examples

    iex> %ElasticsearchElixirBulkProcessor.Items.Update{index: "test", id: "1", retry_on_conflict: 3, return_source: true, source: %{"test" => "test"}}
    ...> |> ElasticsearchElixirBulkProcessor.Items.Update.to_payload()
    "{\"update\":{\"retry_on_conflict\":3,\"_source\":true,\"_index\":\"test\",\"_id\":\"1\"}}\n{\"test\":\"test\"}"

  """
  def to_payload(
        %__MODULE__{
          id: _,
          source: source
        } = item
      )
      when is_map(source) do
    action = %{"update" => meta(item)} |> Poison.encode!()

    body = source |> Poison.encode!()

    "#{action}\n#{body}"
  end

  defp meta(%{index: index, id: id} = item) do
    %{"_index" => index, "_id" => id}
    |> add_retry_on_conflict(item)
    |> add_return_source(item)
  end

  defp add_retry_on_conflict(return, %{retry_on_conflict: count}) when is_number(count),
    do: return |> Map.put("retry_on_conflict", count)

  defp add_retry_on_conflict(return, _), do: return

  defp add_return_source(return, %{return_source: return_source}) when is_boolean(return_source),
    do: return |> Map.put("_source", return_source)

  defp add_return_source(return, _), do: return
end
