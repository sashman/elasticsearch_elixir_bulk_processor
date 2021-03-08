defmodule ElasticsearchElixirBulkProcessor.Bulk.BulkStageTest do
  use ExUnit.Case, async: false
  import Mock

  alias ElasticsearchElixirBulkProcessor.Items.Index
  alias ElasticsearchElixirBulkProcessor.Bulk.{Client, QueueStage, BulkStage}

  @index_item_byte_size 40

  describe ".set_byte_threshold" do
    setup do
      assert ElasticsearchElixirBulkProcessor.set_byte_threshold(@index_item_byte_size * 4) == :ok

      on_exit(fn ->
        assert ElasticsearchElixirBulkProcessor.set_byte_threshold(62_914_560) == :ok
      end)
    end

    test "persists the threshold value" do
      payload = [
        %Index{index: "test", source: %{"test" => "1"}},
        %Index{index: "test", source: %{"test" => "2"}},
        %Index{index: "test", source: %{"test" => "3"}},
        %Index{index: "test", source: %{"test" => "4"}}
      ]

      with_mock Client, bulk_upload: fn _, _, _ -> :ok end do
        QueueStage.add(payload)

        :timer.sleep(100)

        assert_called(
          Client.bulk_upload(
            "{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"1\"}\n{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"2\"}\n{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"3\"}\n{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"4\"}",
            :_,
            :_
          )
        )
      end
    end
  end

  describe ".set_event_count_threshold" do
    setup do
      assert ElasticsearchElixirBulkProcessor.set_event_count_threshold(2) ==
               :ok

      on_exit(fn ->
        assert ElasticsearchElixirBulkProcessor.set_event_count_threshold(nil) == :ok
      end)
    end

    @tag :me
    test "persists the threshold value" do
      payload = [
        %Index{index: "test", source: %{"test" => "1"}},
        %Index{index: "test", source: %{"test" => "2"}},
        %Index{index: "test", source: %{"test" => "3"}},
        %Index{index: "test", source: %{"test" => "4"}}
      ]

      with_mock Client, bulk_upload: fn _, _, _ -> :ok end do
        QueueStage.add(payload)

        :timer.sleep(100)

        assert_called(
          Client.bulk_upload(
            "{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"1\"}\n{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"2\"}",
            :_,
            :_
          )
        )

        assert_called(
          Client.bulk_upload(
            "{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"3\"}\n{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"4\"}",
            :_,
            :_
          )
        )
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

    test "events are sent in order" do
      payload =
        ~w(0 1 2 3 4 5 6 7 8 9 a b c d e f)
        |> Enum.map(&%Index{index: "test", source: %{"test" => &1}})

      assert ElasticsearchElixirBulkProcessor.set_byte_threshold(@index_item_byte_size * 3) == :ok

      with_mock Client,
        bulk_upload: fn _, _, _ -> nil end do
        QueueStage.add(payload)

        :timer.sleep(100)

        assert Client
               |> :meck.history()
               |> Enum.map(fn {_, {Client, :bulk_upload, [payload, _, _]}, _} -> payload end) ==
                 [
                   "{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"0\"}\n{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"1\"}\n{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"2\"}",
                   "{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"3\"}\n{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"4\"}\n{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"5\"}",
                   "{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"6\"}\n{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"7\"}\n{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"8\"}",
                   "{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"9\"}\n{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"a\"}\n{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"b\"}",
                   "{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"c\"}\n{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"d\"}\n{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"e\"}",
                   "{\"index\":{\"_index\":\"test\"}}\n{\"test\":\"f\"}"
                 ]
      end
    end
  end
end
