defmodule ElasticsearchElixirBulkProcessor.Bulk.ClientTest do
  use ExUnit.Case, async: false
  import Mock

  alias ElasticsearchElixirBulkProcessor.Bulk.Client

  defmodule FunctionStub do
    def error_fun(_) do
    end
  end

  defmodule FunctionStub2 do
    def error_fun(_) do
    end
  end

  describe ".bulk_upload" do
    test "calls error function when there is 1 error" do
      with_mock Elasticsearch,
        post: fn _, _, _ -> {:error, %HTTPoison.Error{id: nil, reason: :econnrefused}} end do
        with_mock FunctionStub, error_fun: fn _ -> :ok end do
          Client.bulk_upload(
            "",
            ElasticsearchElixirBulkProcessor.ElasticsearchCluster,
            & &1,
            &FunctionStub.error_fun/1
          )

          assert_called(FunctionStub.error_fun(:_))
        end
      end
    end

    test "calls error function when there is multiple errors" do
      with_mock Elasticsearch,
        post: fn _, _, _ -> {:ok, %{"errors" => true, "items" => ["one", "two", "three"]}} end do
        with_mock FunctionStub2, error_fun: fn _ -> :ok end do
          Client.bulk_upload(
            "",
            ElasticsearchElixirBulkProcessor.ElasticsearchCluster,
            & &1,
            &FunctionStub2.error_fun/1
          )

          :timer.sleep(100)
          assert_called(FunctionStub2.error_fun("one"))
          assert_called(FunctionStub2.error_fun("two"))
          assert_called(FunctionStub2.error_fun("three"))
        end
      end
    end
  end
end
