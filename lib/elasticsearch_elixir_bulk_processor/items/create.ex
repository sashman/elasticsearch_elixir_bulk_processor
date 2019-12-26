defmodule ElasticsearchElixirBulkProcessor.Items.Create do
  @behaviour ElasticsearchElixirBulkProcessor.Items.Item
  @enforce_keys [:index, :source]
  defstruct [
    :index,
    :id,
    :source
  ]

  @doc ~S"""

  ## Examples

    iex> %ElasticsearchElixirBulkProcessor.Items.Create{index: "test", source: %{"test" => "test"}}
    ...> |> ElasticsearchElixirBulkProcessor.Items.Create.to_payload()
    "{\"create\":{\"_index\":\"test\"}}\n{\"test\":\"test\"}"

    iex> %ElasticsearchElixirBulkProcessor.Items.Create{index: "test", id: "1", source: %{"test" => "test"}}
    ...> |> ElasticsearchElixirBulkProcessor.Items.Create.to_payload()
    "{\"create\":{\"_index\":\"test\",\"_id\":\"1\"}}\n{\"test\":\"test\"}"

  """
  def to_payload(
        %ElasticsearchElixirBulkProcessor.Items.Create{
          source: source
        } = item
      )
      when is_map(source) do
    action = %{"create" => meta(item)} |> Poison.encode!()
    body = source |> Poison.encode!()

    "#{action}\n#{body}"
  end

  defp meta(%{index: index, id: id}) when not is_nil(id), do: %{"_index" => index, "_id" => id}
  defp meta(%{index: index}), do: %{"_index" => index}
end
