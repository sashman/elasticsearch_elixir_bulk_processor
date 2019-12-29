# ElasticsearchElixirBulkProcessor

[![CircleCI](https://circleci.com/gh/sashman/elasticsearch_elixir_bulk_processor.svg?style=svg)](https://circleci.com/gh/sashman/elasticsearch_elixir_bulk_processor)
[![Coverage Status](https://coveralls.io/repos/github/sashman/elasticsearch_elixir_bulk_processor/badge.svg?branch=master)](https://coveralls.io/github/sashman/elasticsearch_elixir_bulk_processor?branch=master)

Elasticsearch Elixir Bulk Processor is a configurable manager for efficiently inserting data into Elasticsearch.
This processor uses genstages for handling backpressure, and various settings to control the bulk payloads being uploaded to Elasticsearch.

Inspired by the [Java Bulk Processor](https://www.elastic.co/guide/en/elasticsearch/client/java-api/current/java-docs-bulk-processor.html)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `elasticsearch_elixir_bulk_processor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elasticsearch_elixir_bulk_processor, "~> 0.1.0"}
  ]
end
```

## Sending data

```elixir
ElasticsearchElixirBulkProcessor.send_requests(list_of_items)
```

To send a list of request items to Elasticsearch. This mechanism uses GenStages for back pressure.
NOTE: It should be completely reasonable to use this function by passing single element lists, the mechanism aggregates the items together prior to sending them.

The list elements must be structs:

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

### Action count

Number of actions/items to send per bulk (can be changed at run time)

```elixir
ElasticsearchElixirBulkProcessor.set_event_count_threshold(100)
```

### Byte size

Max number of bytes to send per bulk (can be changed at run time)

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

### Success and error handlers

The callbacks on a successful upload or in case of failed items or failed request can bet set through the config.
On success, the handler is called with the Elasticsearch bulk request. On failure, the hanlder is called with`%{data: any, error: any}`, `data` being the original payload and `error` being the response or HTTP error.
See [`ElasticsearchElixirBulkProcessor.Bulk.Handlers`](https://github.com/sashman/elasticsearch_elixir_bulk_processor/blob/master/lib/elasticsearch_elixir_bulk_processor/bulk/handlers.ex).

```elixir
config :elasticsearch_elixir_bulk_processor,
  success_function: &MyApp.success_handler/1,
  error_function: &MyApp.error_handler/1
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/elasticsearch_elixir_bulk_processor](https://hexdocs.pm/elasticsearch_elixir_bulk_processor).

## Testing script

Run Elasticsearch set up with:

```
docker-compose up
```

Run test:

```
mix insert_test <INSERT_COUNT> <BULK_SIZE> staged|direct
```

- `staged` - uses a GenStage mechanism to aggregate and insert.
- `direct` - iterates and inserts bulk sequentially as given.
