defmodule OrbitalDynamics.MixProject do
  use Mix.Project

  def project do
    [
      app: :orbital_dynamics,
      version: "0.1.0",
      elixir: "~> 1.19",
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
      preferred_envs: ["orbital_dynamics.test.shard": :test]
    ]
  end

  defp deps do
    [
      {:nx, "~> 0.11"},
      {:exla, "~> 0.11", optional: true}
    ]
  end
end
