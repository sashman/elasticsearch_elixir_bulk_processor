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

  defmodule FunctionStub3 do
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
            & &1,
            &FunctionStub.error_fun/1
          )

          assert_called(FunctionStub.error_fun(:_))
        end
      end
    end

    @es_res %{
      "errors" => true,
      "items" => [
        %{"index" => %{"error" => %{}}},
        %{"update" => %{"error" => %{}}},
        %{"create" => %{"error" => %{}}}
      ]
    }

    test "calls error function when there is multiple errors" do
      with_mock Elasticsearch,
        post: fn _, _, _ ->
          {:ok, @es_res}
        end do
        with_mock FunctionStub2, error_fun: fn _ -> :ok end do
          Client.bulk_upload(
            "one\ntwo\nthree",
            & &1,
            &FunctionStub2.error_fun/1
          )

          :timer.sleep(100)

          assert_called(
            FunctionStub2.error_fun(%{
              data: "one\ntwo\nthree",
              error: {:error, @es_res}
            })
          )
        end
      end
    end

    @nes_res %{
      "errors" => true,
      "items" => [
        %{"index" => %{"error" => %{}}},
        %{"update" => %{"success" => %{}}},
        %{"create" => %{"error" => %{}}}
      ]
    }

    @reduced_es_res %{
      "errors" => true,
      "items" => [
        %{"index" => %{"error" => %{}}},
        %{"create" => %{"error" => %{}}}
      ]
    }

    test "calls error function with reduced data when there is multiple errors with some successes" do
      with_mock Elasticsearch,
        post: fn
          _, _, "one\nthree\n" -> {:ok, @reduced_es_res}
          _, _, _ -> {:ok, @nes_res}
        end do
        with_mock FunctionStub3, error_fun: fn _ -> :ok end do
          Client.bulk_upload(
            "one\ntwo\nthree",
            & &1,
            &FunctionStub3.error_fun/1
          )

          :timer.sleep(100)

          assert_called(
            FunctionStub3.error_fun(%{
              data: "one\nthree",
              error: {:error, @reduced_es_res}
            })
          )
        end
      end
    end
  end
end
