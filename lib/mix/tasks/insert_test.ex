defmodule Mix.Tasks.InsertTest do
  use Mix.Task
  alias ElasticsearchElixirBulkProcessor.{Bulk, Items}

  @shortdoc "Test insertion using Bulk module"
  def run([count, per_bulk, method]) when method in ["direct", "staged"] do
    {:ok, _started} = Application.ensure_all_started(:elasticsearch_elixir_bulk_processor)

    {count, _} =
      count
      |> Integer.parse()

    {per_bulk, _} =
      per_bulk
      |> Integer.parse()

    base_line_doc_total = count_current_docs()

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
      wait_until_doc_count(count * per_bulk, base_line_doc_total)
    end)
    |> IO.inspect()

    delete_index()
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

  defp wait_until_doc_count(doc_count, base_line, state \\ %{})
  defp wait_until_doc_count(_, _, %{retry: 360}), do: {:error, :timeout}

  defp wait_until_doc_count(doc_count, base_line, state) do
    cond do
      doc_count + base_line == count_current_docs() ->
        {:ok}

      true ->
        state[:retry]
        |> case do
          nil ->
            wait_until_doc_count(doc_count, base_line, %{retry: 0})

          retry ->
            :timer.sleep(1000)
            wait_until_doc_count(doc_count, base_line, %{retry: retry + 1})
        end
    end
  end

  defp count_current_docs do
    ElasticsearchElixirBulkProcessor.ElasticsearchCluster
    |> Elasticsearch.post("test/_search?track_total_hits=true", %{size: 0})
    |> case do
      {:ok, %{"hits" => %{"total" => %{"value" => total}}}} -> total
      _ -> 0
    end
  end

  defp delete_index do
    ElasticsearchElixirBulkProcessor.ElasticsearchCluster
    |> Elasticsearch.delete("test")
  end
end
