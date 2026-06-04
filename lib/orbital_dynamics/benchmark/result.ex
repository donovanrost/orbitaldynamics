defmodule OrbitalDynamics.Benchmark.Result do
  @moduledoc """
  Structured timing result for a benchmarked propagation mode.
  """

  @enforce_keys [
    :id,
    :mode,
    :backend,
    :node,
    :scenario_count,
    :sample_count,
    :failure_count,
    :elapsed_us,
    :options,
    :metadata
  ]
  defstruct [
    :id,
    :mode,
    :backend,
    :node,
    :scenario_count,
    :sample_count,
    :failure_count,
    :elapsed_us,
    :memory_delta_bytes,
    :options,
    :metadata
  ]

  @type t :: %__MODULE__{
          id: atom() | String.t(),
          mode: atom(),
          backend: module() | atom(),
          node: node(),
          scenario_count: non_neg_integer(),
          sample_count: non_neg_integer(),
          failure_count: non_neg_integer(),
          elapsed_us: non_neg_integer(),
          memory_delta_bytes: integer() | nil,
          options: keyword(),
          metadata: map()
        }

  @doc """
  Builds a benchmark result and derives throughput metrics in metadata.
  """
  def new!(attrs) when is_map(attrs) do
    elapsed_us = fetch_non_negative_integer!(attrs, :elapsed_us)
    scenario_count = fetch_non_negative_integer!(attrs, :scenario_count)
    sample_count = fetch_non_negative_integer!(attrs, :sample_count)
    failure_count = fetch_non_negative_integer!(attrs, :failure_count)
    memory_delta_bytes = Map.get(attrs, :memory_delta_bytes)
    metadata = Map.get(attrs, :metadata, %{})

    unless is_nil(memory_delta_bytes) or is_integer(memory_delta_bytes) do
      raise ArgumentError, "memory_delta_bytes must be nil or an integer"
    end

    unless is_map(metadata), do: raise(ArgumentError, "metadata must be a map")

    %__MODULE__{
      id: Map.fetch!(attrs, :id),
      mode: Map.fetch!(attrs, :mode),
      backend: Map.fetch!(attrs, :backend),
      node: Map.get(attrs, :node, node()),
      scenario_count: scenario_count,
      sample_count: sample_count,
      failure_count: failure_count,
      elapsed_us: elapsed_us,
      memory_delta_bytes: memory_delta_bytes,
      options: Map.get(attrs, :options, []),
      metadata:
        Map.merge(metadata, %{
          scenarios_per_second: rate_per_second(scenario_count, elapsed_us),
          samples_per_second: rate_per_second(sample_count, elapsed_us)
        })
    }
  end

  defp fetch_non_negative_integer!(attrs, key) do
    value = Map.fetch!(attrs, key)

    if is_integer(value) and value >= 0 do
      value
    else
      raise ArgumentError, "#{key} must be a non-negative integer"
    end
  end

  defp rate_per_second(_count, 0), do: 0.0
  defp rate_per_second(count, elapsed_us), do: count / (elapsed_us / 1_000_000.0)
end
