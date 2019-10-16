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
    for _i <- 1..count,
        do:
          [
            %{"index" => %{"_index" => "test"}},
            %{"test" => "test"}
          ]
          |> List.flatten()
          |> Elastic.bulk_upload(
            ElasticsearchElixirBulkProcessor.ElasticsearchCluster,
            &IO.inspect/1
          )
  end
end
