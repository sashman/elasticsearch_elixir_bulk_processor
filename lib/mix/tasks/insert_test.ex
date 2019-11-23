defmodule Mix.Tasks.InsertTest do
  use Mix.Task
  alias ElasticsearchElixirBulkProcessor.{Bulk, Items}

  @shortdoc "Test insertion using Bulk module"
  def run([count, per_bulk]) do
    {:ok, _started} = Application.ensure_all_started(:elasticsearch_elixir_bulk_processor)

    {count, _} =
      count
      |> Integer.parse()

    {per_bulk, _} =
      per_bulk
      |> Integer.parse()

    count
    |> insert(per_bulk)
  end

  defp insert(count, per_bulk) do
    1..count
    |> Enum.each(fn _ ->
      index_item("test", %{"a" => "test string"})
      |> List.duplicate(per_bulk)
      |> Bulk.DirectUpload.add_requests()
    end)
  end

  defp index_item(index_name, payload) do
    %Items.Index{index: index_name, source: payload}
  end
end
