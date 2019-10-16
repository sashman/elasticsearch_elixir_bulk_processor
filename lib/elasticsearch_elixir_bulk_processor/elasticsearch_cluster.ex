defmodule ElasticsearchElixirBulkProcessor.ElasticsearchCluster do
  use Elasticsearch.Cluster, otp_app: :elasticsearch_elixir_bulk_processor
end
