defmodule ElasticsearchElixirBulkProcessor.Helpers.Events do
  def byte_sum(string_list), do: Enum.map(string_list, &byte_size/1) |> Enum.sum()

  @doc ~S"""

  Split list of strings into first chunk of given byte size and rest of the list.

  ## Examples

    iex> ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    ...> |> ElasticsearchElixirBulkProcessor.Helpers.Events.split_first_bytes(3)
    {["0", "1", "2"], ["3", "4", "5", "6", "7", "8", "9"]}

  """
  def split_first_bytes(list, first_byte_size) do
    list
    |> Enum.reduce(
      {[], []},
      fn element, acc -> build_up_elements(element, acc, first_byte_size) end
    )
  end

  def build_up_elements(element, {first, rest}, first_byte_size) when is_binary(element) do
    if first |> byte_sum >= first_byte_size do
      {first, rest ++ [element]}
    else
      {first ++ [element], rest}
    end
  end
end
