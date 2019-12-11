# coveralls-ignore-start
defmodule ElasticsearchElixirBulkProcessor.Helpers.Elasticsearch do
  def wait_until_doc_count(doc_count, base_line, state \\ %{})
  def wait_until_doc_count(_, _, %{retry: 3600}), do: {:error, :timeout}

  def wait_until_doc_count(doc_count, base_line, state) do
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

  def count_current_docs do
    ElasticsearchElixirBulkProcessor.ElasticsearchCluster
    |> Elasticsearch.post("test/_search?track_total_hits=true", %{size: 0})
    |> case do
      {:ok, %{"hits" => %{"total" => %{"value" => total}}}} -> total
      _ -> 0
    end
  end

  def query(query) when is_map(query) do
    {:ok, response} =
      ElasticsearchElixirBulkProcessor.ElasticsearchCluster
      |> Elasticsearch.post("test/_search?track_total_hits=true", Map.merge(%{size: 0}, query))

    response
  end

  def delete_index do
    ElasticsearchElixirBulkProcessor.ElasticsearchCluster
    |> Elasticsearch.delete("test")
  end
end

# coveralls-ignore-stop
