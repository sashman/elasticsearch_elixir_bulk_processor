defmodule Mix.Tasks.InsertTest do
  use Mix.Task
  alias ElasticsearchElixirBulkProcessor.Bulk.Elastic

  @shortdoc "Test insertion using Bulk module"
  def run([count]) do
    {:ok, _started} = Application.ensure_all_started(:elasticsearch_elixir_bulk_processor)

    {count, _} =
      count
      |> Integer.parse()

    count
    |> insert()
  end

  def run(_) do
    {:ok, _started} = Application.ensure_all_started(:elasticsearch_elixir_bulk_processor)
    insert(1)
  end

  defp insert(count) do
    data =
      for i <- 1..100,
          do: [
            %{"index" => %{"_index" => "test"}},
            %{"test#{rem(i, 999)}" => "test#{i}"}
          ]

    1..count
    |> Enum.map(fn _ ->
      Task.async(fn ->
        Elastic.bulk_upload(
          data |> List.flatten(),
          ElasticsearchElixirBulkProcessor.ElasticsearchCluster,
          &IO.inspect/1,
          &IO.inspect("***ERROR***\n#{inspect(&1)}***ERROR***\n\n")
        )
      end)
    end)
    |> Enum.map(fn task -> Task.await(task) end)
  end
end
