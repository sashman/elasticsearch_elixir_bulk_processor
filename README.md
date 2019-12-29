# ElasticsearchElixirBulkProcessor

[![CircleCI](https://circleci.com/gh/sashman/elasticsearch_elixir_bulk_processor.svg?style=svg)](https://circleci.com/gh/sashman/elasticsearch_elixir_bulk_processor)
[![Coverage Status](https://coveralls.io/repos/github/sashman/elasticsearch_elixir_bulk_processor/badge.svg?branch=master)](https://coveralls.io/github/sashman/elasticsearch_elixir_bulk_processor?branch=master)

Port of the [Java bulk processor](https://www.elastic.co/guide/en/elasticsearch/client/java-api/current/java-docs-bulk-processor.html)

**Under construction!**

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
