defmodule ElasticsearchElixirBulkProcessor.MixProject do
  use Mix.Project

  def project do
    [
      app: :elasticsearch_elixir_bulk_processor,
      version: String.trim(File.read!("VERSION")),
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
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
      {:retry, "~> 0.13"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
