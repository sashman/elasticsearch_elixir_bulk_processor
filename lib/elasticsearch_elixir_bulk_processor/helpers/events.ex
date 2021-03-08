defmodule ElasticsearchElixirBulkProcessor.Helpers.Events do
  alias ElasticsearchElixirBulkProcessor.Items.{Create, Index, Update, Delete}

  @doc ~S"""

  Return the size of the string in bytes

  ## Examples

    iex> ElasticsearchElixirBulkProcessor.Helpers.Events.byte_sum([%ElasticsearchElixirBulkProcessor.Items.Index{index: "test", source: %{"test" => "test"}}])
    43

    iex> ElasticsearchElixirBulkProcessor.Helpers.Events.byte_sum([
    ...> %ElasticsearchElixirBulkProcessor.Items.Index{index: "test", source: %{"test" => "test"}},
    ...> %ElasticsearchElixirBulkProcessor.Items.Index{index: "test", source: %{"test" => "test"}}
    ...> ])
    86

    iex> ElasticsearchElixirBulkProcessor.Helpers.Events.byte_sum([])
    0

  """
  def byte_sum([]),
    do: 0

  def byte_sum(item_list) when is_list(item_list),
    do:
      Stream.map(item_list, fn %struct{} = item
                               when struct in [Create, Index, Update, Delete] ->
        struct.to_payload(item) |> byte_size
      end)
      |> Enum.sum()

  @doc ~S"""

  Split list of strings into first chunk of given byte size and rest of the list.

  ## Examples

    iex> alias ElasticsearchElixirBulkProcessor.Items.Index
    ...> [
    ...> %Index{index: "test", source: %{"test" => "test"}},
    ...> %Index{index: "test", source: %{"test" => "test"}},
    ...> %Index{index: "test", source: %{"test" => "test"}}
    ...> ]
    ...> |> ElasticsearchElixirBulkProcessor.Helpers.Events.split_first_bytes(43)
    alias ElasticsearchElixirBulkProcessor.Items.Index
    {
      [%Index{index: "test", source: %{"test" => "test"}}],
      [%Index{index: "test", source: %{"test" => "test"}}, %Index{index: "test", source: %{"test" => "test"}}]
    }

    iex> alias ElasticsearchElixirBulkProcessor.Items.Index
    ...> [
    ...> %Index{index: "test", source: %{"test" => "test"}},
    ...> %Index{index: "test", source: %{"test" => "test"}},
    ...> %Index{index: "test", source: %{"test" => "test"}}
    ...> ]
    ...> |> ElasticsearchElixirBulkProcessor.Helpers.Events.split_first_bytes(43 * 2)
    alias ElasticsearchElixirBulkProcessor.Items.Index
    {
      [%Index{index: "test", source: %{"test" => "test"}}, %Index{index: "test", source: %{"test" => "test"}}],
      [%Index{index: "test", source: %{"test" => "test"}}]
    }

    iex> alias ElasticsearchElixirBulkProcessor.Items.Index
    ...> [
    ...> %Index{index: "test", source: %{"test" => "test"}},
    ...> %Index{index: "test", source: %{"test" => "test"}},
    ...> %Index{index: "test", source: %{"test" => "test"}}
    ...> ]
    ...> |> ElasticsearchElixirBulkProcessor.Helpers.Events.split_first_bytes(0)
    alias ElasticsearchElixirBulkProcessor.Items.Index
    {
      [],
      [%Index{index: "test", source: %{"test" => "test"}}, %Index{index: "test", source: %{"test" => "test"}}, %Index{index: "test", source: %{"test" => "test"}}]
    }

  """
  def split_first_bytes(list, first_byte_size) do
    list
    |> Enum.reduce(
      {[], []},
      fn element, acc -> build_up_first_chunk_elements(element, acc, first_byte_size) end
    )
  end

  defp build_up_first_chunk_elements(element = %struct{}, {first, rest}, first_byte_size)
       when struct in [Create, Index, Update, Delete] do
    if first |> byte_sum >= first_byte_size do
      {first, rest ++ [element]}
    else
      {first ++ [element], rest}
    end
  end

  @doc ~S"""

  Split list of strings into chunks of given byte size and rest of the list.

  ## Examples

    iex> alias ElasticsearchElixirBulkProcessor.Items.Index
    ...> [
    ...> %Index{index: "test", source: %{"test" => "test"}},
    ...> %Index{index: "test", source: %{"test" => "test"}}
    ...> ]
    ...> |> ElasticsearchElixirBulkProcessor.Helpers.Events.chunk_bytes(10)
    alias ElasticsearchElixirBulkProcessor.Items.Index
    [[%Index{index: "test", source: %{"test" => "test"}}], [%Index{index: "test", source: %{"test" => "test"}}]]

    iex> alias ElasticsearchElixirBulkProcessor.Items.Index
    ...> [
    ...> %Index{index: "test", source: %{"test" => "test"}},
    ...> %Index{index: "test", source: %{"test" => "test"}}
    ...> ]
    ...> |> ElasticsearchElixirBulkProcessor.Helpers.Events.chunk_bytes(10)
    alias ElasticsearchElixirBulkProcessor.Items.Index
    [[%Index{index: "test", source: %{"test" => "test"}}], [%Index{index: "test", source: %{"test" => "test"}}]]

  """
  def chunk_bytes(list, chunk_byte_size) do
    list
    |> Enum.reduce(
      [[]],
      fn element, acc -> build_up_chunk_elements(element, acc, chunk_byte_size) end
    )
    |> Enum.reverse()
  end

  defp build_up_chunk_elements(
         element = %struct{},
         [head | tail],
         chunk_byte_size
       )
       when is_list(head) and struct in [Create, Index, Update, Delete] do
    current_byte_size = byte_sum(head)

    if current_byte_size >= chunk_byte_size do
      [[element] | [head | tail]]
    else
      [head ++ [element] | tail]
    end
  end
end
