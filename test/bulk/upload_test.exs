defmodule ElasticsearchElixirBulkProcessor.Bulk.UploadTest do
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
    end

    test "uploads data to elasticsearch" do
      Bulk.Upload.add_requests([index_item()])
      :timer.sleep(1000)
      _result = Helpers.Elasticsearch.query(item_query())

      assert _result = %{"hits" => %{"hits" => [%{"my_string" => "test"}]}}
    end
  end
end
