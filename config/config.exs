# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# third-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :elasticsearch_elixir_bulk_processor, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:elasticsearch_elixir_bulk_processor, :key)
#
# You can also configure a third-party app:
#
#     config :logger, level: :info
#

config :elasticsearch_elixir_bulk_processor,
  preserve_event_order: false,
  retry_function: &ElasticsearchElixirBulkProcessor.Bulk.Retry.default/0,
  success_function: &ElasticsearchElixirBulkProcessor.Bulk.Handlers.default_success/1,
  error_function: &ElasticsearchElixirBulkProcessor.Bulk.Handlers.default_error/1

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).

config :elasticsearch_elixir_bulk_processor,
       ElasticsearchElixirBulkProcessor.ElasticsearchCluster,
       # The URL where Elasticsearch is hosted on your system
       url: "http://localhost:9200",

       # If you want to mock the responses of the Elasticsearch JSON API
       # for testing or other purposes, you can inject a different module
       # here. It must implement the Elasticsearch.API behaviour.
       api: Elasticsearch.API.HTTP,

       # Customize the library used for JSON encoding/decoding.
       # or Jason
       json_library: Poison,
       default_options: [
         timeout: 15_000,
         recv_timeout: 15_000
       ]

#     import_config "#{Mix.env()}.exs"
