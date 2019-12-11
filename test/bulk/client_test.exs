defmodule ElasticsearchElixirBulkProcessor.Bulk.ClientTest do
  use ExUnit.Case
  import Mock

  alias ElasticsearchElixirBulkProcessor.Bulk.Client

  defmodule FunctionStub do
    def error_fun(_) do
    end
  end

  @tag :me
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
  end
end
