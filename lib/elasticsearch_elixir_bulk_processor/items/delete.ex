defmodule ElasticsearchElixirBulkProcessor.Items.Delete do
  @behaviour ElasticsearchElixirBulkProcessor.Items.Item
  @enforce_keys [:index, :id]
  defstruct [
    :index,
    :id
  ]

  def to_payload(
        %__MODULE__{
          index: _,
          id: _
        } = item
      ) do
    %{"index" => meta(item)} |> Poison.encode!()
  end

  defp meta(%{index: index, id: id}) when not is_nil(id), do: %{"_index" => index, "_id" => id}
end
