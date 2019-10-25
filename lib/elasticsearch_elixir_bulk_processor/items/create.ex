defmodule ElasticsearchElixirBulkProcessor.Items.Create do
  @behaviour ElasticsearchElixirBulkProcessor.Items.Item
  @enforce_keys [:index, :source]
  defstruct [
    :index,
    :id,
    :source
  ]

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
