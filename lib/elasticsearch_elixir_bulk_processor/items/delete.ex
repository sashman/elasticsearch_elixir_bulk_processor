defmodule ElasticsearchElixirBulkProcessor.Items.Delete do
  @behaviour ElasticsearchElixirBulkProcessor.Items.Item
  @enforce_keys [:index, :id]
  defstruct [
    :index,
    :id
  ]

  @doc ~S"""

  ## Examples

    iex> %ElasticsearchElixirBulkProcessor.Items.Delete{index: "test", id: "1"}
    ...> |> ElasticsearchElixirBulkProcessor.Items.Delete.to_payload()
    "{\"delete\":{\"_index\":\"test\",\"_id\":\"1\"}}"

  """
  def to_payload(
        %__MODULE__{
          index: _,
          id: _
        } = item
      ) do
    %{"delete" => meta(item)} |> Poison.encode!()
  end

  defp meta(%{index: index, id: id}) when not is_nil(id), do: %{"_index" => index, "_id" => id}
end
