# ElasticsearchElixirBulkProcessor

[![Hex.pm](https://img.shields.io/hexpm/v/elasticsearch_elixir_bulk_processor)](https://hex.pm/packages/elasticsearch_elixir_bulk_processor)
[![CircleCI](https://circleci.com/gh/sashman/elasticsearch_elixir_bulk_processor.svg?style=svg)](https://circleci.com/gh/sashman/elasticsearch_elixir_bulk_processor)
[![Coverage Status](https://coveralls.io/repos/github/sashman/elasticsearch_elixir_bulk_processor/badge.svg?branch=master)](https://coveralls.io/github/sashman/elasticsearch_elixir_bulk_processor?branch=master)
![Hex.pm](https://img.shields.io/hexpm/l/elasticsearch_elixir_bulk_processor)

Elasticsearch Elixir Bulk Processor is a configurable manager for efficiently inserting data into Elasticsearch.
This processor uses [GenStages](https://hexdocs.pm/gen_stage/GenStage.html) for handling backpressure, and various settings to control the bulk payloads being uploaded to Elasticsearch.

Inspired by the [Java Bulk Processor](https://www.elastic.co/guide/en/elasticsearch/client/java-api/current/java-docs-bulk-processor.html). Uses [elasticsearch-elixir](https://github.com/danielberkompas/elasticsearch-elixir) as the client. Featured on the [Elastic Community Contributed Clients page](https://www.elastic.co/guide/en/elasticsearch/client/community/current/index.html#erlang).

## Installation

If [available in Hex](https://hex.pm/packages/elasticsearch_elixir_bulk_processor), the package can be installed
by adding `elasticsearch_elixir_bulk_processor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elasticsearch_elixir_bulk_processor, "~> 0.1"}
  ]
end
```

## Sending data

```elixir
ElasticsearchElixirBulkProcessor.send_requests(list_of_items)
```

To send a list of request items to Elasticsearch. This mechanism uses GenStages for back pressure.
NOTE: It should be completely reasonable to use this function by passing single element lists, the mechanism aggregates the items together prior to sending them.

If you wish to bypass the GenStage mechanism and send the data synchronously you can use:

```elixir
ElasticsearchElixirBulkProcessor.Bulk.DirectUpload.add_requests(list_of_items)
```

The list elements must be [structs](https://github.com/sashman/elasticsearch_elixir_bulk_processor/tree/master/lib/elasticsearch_elixir_bulk_processor/items):

- `ElasticsearchElixirBulkProcessor.Items.Index`
- `ElasticsearchElixirBulkProcessor.Items.Create`
- `ElasticsearchElixirBulkProcessor.Items.Update`
- `ElasticsearchElixirBulkProcessor.Items.Delete`

#### Examples

```elixir
    iex> alias ElasticsearchElixirBulkProcessor.Items.Index
    ...> [
    ...>  %Index{index: "test_index", source: %{"field" => "value1"}},
    ...>  %Index{index: "test_index", source: %{"field" => "value2"}},
    ...>  %Index{index: "test_index", source: %{"field" => "value3"}}
    ...> ]
    ...> |> ElasticsearchElixirBulkProcessor.send_requests()
    :ok
```

## Configuration

### Elasticsearch endpoint

Can be configurate via the `ELASTICSEARCH_URL` environment variable, defaults to: `"http://localhost:9200"`. 

```elixir
config :elasticsearch_elixir_bulk_processor,
       ElasticsearchElixirBulkProcessor.ElasticsearchCluster,
       url: {:system, "ELASTICSEARCH_URL"},
       api: Elasticsearch.API.HTTP
```


Alternatively:

```elixir
config :elasticsearch_elixir_bulk_processor,
       ElasticsearchElixirBulkProcessor.ElasticsearchCluster,
       url: "http://localhost:9200",
       api: Elasticsearch.API.HTTP
```

See the [client configuration](https://github.com/danielberkompas/elasticsearch-elixir#configuration) for more.

### Action count

Number of actions/items to send per bulk (can be changed at run time), deault is `nil` (unlimited):

```elixir
ElasticsearchElixirBulkProcessor.set_event_count_threshold(100)
```

### Byte size

Max number of bytes to send per bulk (can be changed at run time), default is `62_914_560` (60mb):

```elixir
ElasticsearchElixirBulkProcessor.set_byte_threshold(100)
```

### Action order

Preservation of order of actions/items

```elixir
config :elasticsearch_elixir_bulk_processor, preserve_event_order: false
```

### Retries

Retry policy, this uses the [ElixirRetry](https://github.com/safwank/ElixirRetry) DSL. See [`ElasticsearchElixirBulkProcessor.Bulk.Retry.policy`](https://github.com/sashman/elasticsearch_elixir_bulk_processor/blob/0d015282315c016db07334824c7b98c858d43658/lib/elasticsearch_elixir_bulk_processor/bulk/retry.ex#L29).

```elixir
config :elasticsearch_elixir_bulk_processor, retry_function: &MyApp.Retry.policy/0
```

Default:

```elixir
def default do
  constant_backoff(100) |> Stream.take(5)
end
```

### Success and error handlers

The callbacks on a successful upload or in case of failed items or failed request can bet set through the config.
On success, the handler is called with the Elasticsearch bulk request. On failure, the hanlder is called with`%{data: any, error: any}`, `data` being the original payload and `error` being the response or HTTP error.
See [`ElasticsearchElixirBulkProcessor.Bulk.Handlers`](https://github.com/sashman/elasticsearch_elixir_bulk_processor/blob/master/lib/elasticsearch_elixir_bulk_processor/bulk/handlers.ex).

```elixir
config :elasticsearch_elixir_bulk_processor,
  success_function: &MyApp.success_handler/1,
  error_function: &MyApp.error_handler/1
```

It's highly recommended you add an error handler to make sure your data is uploaded succesfully, for example you can use the logger:

```elixir
  require Logger
  ...

  def error_handler(%{data: _, error: {_, error}}) do
    error
    |> inspect
    |> Logger.error()
  end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/elasticsearch_elixir_bulk_processor](https://hexdocs.pm/elasticsearch_elixir_bulk_processor).

## Testing script

The testing script is used to compare insertion using direct upload vs using a GenStage based approach. Run Elasticsearch set up with:

```bash
docker-compose up
```

Run test:

```bash
mix insert_test <INSERT_COUNT> <BULK_SIZE> staged|direct
```

- `staged` - uses a GenStage mechanism to aggregate and insert.
- `direct` - iterates and inserts bulk sequentially as given.
