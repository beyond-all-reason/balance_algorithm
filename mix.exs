defmodule BalanceAlgorithm.MixProject do
  use Mix.Project

  def project do
    [
      app: :balance_algorithm,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:con_cache, "~> 1.0"},
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false},
      {:statistics, "~> 0.6.2"},
      {:openskill, git: "git@github.com:Teifion/openskill.ex.git", branch: "master"},
      {:decimal, "~> 2.1"}
    ]
  end
end
