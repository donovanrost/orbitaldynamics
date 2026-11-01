defmodule OrbitalDynamics.MixProject do
  use Mix.Project

  def project do
    [
      app: :orbital_dynamics,
      version: "0.1.0",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_ignore_filters: [~r"/support/", ~r"/(?:local_search_)?support\.exs$"],
      aliases: ["test.fast": ["test --exclude exhaustive --exclude integration"]],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {OrbitalDynamics.Application, []},
      extra_applications: [:logger]
    ]
  end

  def cli do
    [
      preferred_envs: ["orbital_dynamics.test.shard": :test, "test.fast": :test]
    ]
  end

  defp deps do
    [
      {:nx, "~> 0.11"},
      {:exla, "~> 0.11", optional: true}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]
end
