defmodule ElasticsearchElixirBulkProcessor.Bulk.DirectUploadTest do
  use ExUnit.Case

  alias ElasticsearchElixirBulkProcessor.{Bulk, Items, Helpers}

  describe ".add_requests" do
    defp index_item do
      %Items.Index{
        index: "test",
        source: %{
          "my_string" => "test"
        }
      }
    end

    defp item_query do
      %{query: %{bool: %{filter: %{term: %{my_string: "test"}}}}}
    end

    setup do
      Helpers.Elasticsearch.delete_index()

      :ok
    end

    test "uploads data to elasticsearch" do
      Bulk.DirectUpload.add_requests([index_item()])
      _result = Helpers.Elasticsearch.query(item_query())

      assert _result = %{"hits" => %{"hits" => [%{"my_string" => "test"}]}}
    end
  end
end
