defmodule ElasticsearchElixirBulkProcessor.Bulk.DirectUpload do
  alias ElasticsearchElixirBulkProcessor.Bulk.{Client, Handlers}

  def add_requests(bulk_requests) do
    success_fun =
      Application.get_env(
        :elasticsearch_elixir_bulk_processor,
        :success_function,
        &Handlers.default_success/1
      )

    error_fun =
      Application.get_env(
        :elasticsearch_elixir_bulk_processor,
        :error_function,
        &Handlers.default_error/1
      )

    bulk_requests
    |> Stream.map(& &1.__struct__.to_payload(&1))
    |> Enum.join("\n")
    |> Client.bulk_upload(success_fun, error_fun)
  end
end
