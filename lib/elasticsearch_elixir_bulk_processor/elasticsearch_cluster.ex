defmodule ElasticsearchElixirBulkProcessor.ElasticsearchCluster do
  use Elasticsearch.Cluster, otp_app: :elasticsearch_elixir_bulk_processor

  @default_url "http://localhost:9200"

  def init(config) do
    url =
      config
      |> case do
        %{url: {:system, env_var_name}} -> System.get_env(env_var_name, @default_url)
        %{url: url} -> url
        _ -> @default_url
      end

    config =
      config
      |> Map.put(:url, url)

    {:ok, config}
  end
end
