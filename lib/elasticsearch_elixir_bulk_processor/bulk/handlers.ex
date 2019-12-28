defmodule ElasticsearchElixirBulkProcessor.Bulk.Handlers do
  @spec default_success(any) :: any
  def default_success(response), do: response

  @spec default_error(%{data: any, error: any}) :: %{data: any, error: any}
  def default_error(%{error: _, data: _} = response), do: response
end
