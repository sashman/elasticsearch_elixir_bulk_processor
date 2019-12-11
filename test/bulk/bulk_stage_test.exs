defmodule ElasticsearchElixirBulkProcessor.Bulk.BulkStageTest do
  use ExUnit.Case
  import Mock

  alias ElasticsearchElixirBulkProcessor.Bulk.{Client, QueueStage}

  describe ".set_byte_threshold" do
    @tag :me
    test "persists the threshold value" do
      payload = ~w(0 1 2 3 4 5 6 7 8 9 a b c d e f)

      assert ElasticsearchElixirBulkProcessor.set_byte_threshold(10) == :ok

      with_mock Client, bulk_upload: fn _, _, _, _ -> :ok end do
        QueueStage.add(payload)

        :timer.sleep(100)
        assert_called(Client.bulk_upload("0\n1\n2\n3\n4\n5\n6\n7\n8\n9", :_, :_, :_))
      end
    end
  end
end
