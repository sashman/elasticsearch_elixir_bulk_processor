# coveralls-ignore-start
defmodule Mix.Tasks.InsertTest do
  use Mix.Task
  alias ElasticsearchElixirBulkProcessor.{Bulk, Items, Helpers}

  @shortdoc "Test insertion using Bulk module"
  def run([count, per_bulk, method]) when method in ["direct", "staged"] do
    {:ok, _started} = Application.ensure_all_started(:elasticsearch_elixir_bulk_processor)

    {count, _} =
      count
      |> Integer.parse()

    {per_bulk, _} =
      per_bulk
      |> Integer.parse()

    base_line_doc_total = Helpers.Elasticsearch.count_current_docs()

    upload_module =
      case method do
        "direct" -> Bulk.DirectUpload
        "staged" -> Bulk.Upload
      end

    Task.async(fn ->
      count
      |> insert(per_bulk, upload_module)
    end)

    :timer.tc(fn ->
      Helpers.Elasticsearch.wait_until_doc_count(count * per_bulk, base_line_doc_total)
    end)
    |> case do
      {time, {:ok}} ->
        IO.inspect("#{count} #{per_bulk} #{time / 1000}")

      _ ->
        nil
    end

    Helpers.Elasticsearch.delete_index()
  end

  defp insert(count, per_bulk, upload_module) do
    1..count
    |> Enum.each(fn _ ->
      index_item("test", index_payload())
      |> List.duplicate(per_bulk)
      |> upload_module.add_requests()
    end)
  end

  defp index_item(index_name, payload) do
    %Items.Index{index: index_name, source: payload}
  end

  defp index_payload() do
    {int, _} = Integer.parse(Randomizer.randomizer(10, :numeric))

    %{
      "my_string0" => Randomizer.randomizer(20),
      "my_string1" => int,
      "my_string2" => Randomizer.randomizer(50),
      "my string3" => random_enum(),
      "my_string4" => Randomizer.randomizer(20),
      "my_string5" => Randomizer.randomizer(20),
      "my_string6" => Randomizer.randomizer(20),
      "my_string7" => Randomizer.randomizer(20),
      "my_string8" => Randomizer.randomizer(20),
      "my_string9" => Randomizer.randomizer(20)
    }
  end

  defp random_enum do
    [
      "STRING",
      "ANOTHER STRING",
      "SOMETHING ELSE"
    ]
    |> Enum.random()
  end
end

# coveralls-ignore-stop
