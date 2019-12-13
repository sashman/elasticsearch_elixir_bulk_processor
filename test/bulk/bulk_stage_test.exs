defmodule ElasticsearchElixirBulkProcessor.Bulk.BulkStageTest do
  use ExUnit.Case, async: false
  import Mock

  alias ElasticsearchElixirBulkProcessor.Bulk.{Client, QueueStage, BulkStage}

  describe ".set_byte_threshold" do
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

  describe ".set_byte_threshold when preserve_event_order is true" do
    setup do
      BulkStage.set_preserve_event_order(true)

      on_exit(fn ->
        BulkStage.set_preserve_event_order(false)
      end)
    end

    @tag :me
    test "events are sent in order" do
      payload = ~w(00 11 22 33 44 5 6 7 8 9 a b c d e f)

      assert ElasticsearchElixirBulkProcessor.set_byte_threshold(3) == :ok

      with_mock Client,
        bulk_upload: fn _, _, _, _ -> nil end do
        QueueStage.add(payload)

        :timer.sleep(100)

        assert Client
               |> :meck.history()
               |> Enum.map(fn {_, {Client, :bulk_upload, [payload, _, _, _]}, _} -> payload end) ==
                 ["00\n11", "22\n33", "44\n5", "6\n7\n8", "9\na\nb", "c\nd\ne", "f"]
      end
    end
  end
end
