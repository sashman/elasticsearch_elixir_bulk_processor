defmodule ElasticsearchElixirBulkProcessor.MixProject do
  use Mix.Project

  def project do
    [
      app: :elasticsearch_elixir_bulk_processor,
      name: "Elasticsearch Elixir Bulk Processor",
      version: String.trim(File.read!("VERSION")),
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      description: description(),
      deps: deps(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ElasticsearchElixirBulkProcessor.Application, []}
    ]
  end

  defp description do
    "Elasticsearch Elixir Bulk Processor is a configurable manager for efficiently inserting data into Elasticsearch. This processor uses genstages for handling backpressure, and various settings to control the bulk payloads being uploaded to Elasticsearch."
  end

  defp package() do
    [
      # These are the default files included in the package
      files: ~w(lib priv .formatter.exs mix.exs README* readme* LICENSE*
                license* CHANGELOG* changelog* src),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/sashman/elasticsearch_elixir_bulk_processor"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elasticsearch, "~> 1.0.0"},
      {:poison, "~> 3.1"},
      {:gen_stage, "~> 0.14"},
      {:excoveralls, "~> 0.10", only: :test},
      {:eliver, "~> 2.0", only: :dev},
      {:size, "~> 0.1.0"},
      {:mock, "~> 0.3.0", only: :test},
      {:retry, "~> 0.13"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end
end
