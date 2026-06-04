defmodule OrbitalDynamics.Benchmark.Report do
  @moduledoc """
  Analysis helpers for persisted benchmark artifacts.
  """

  alias OrbitalDynamics.OperationalScale

  @baseline_modes ["scalar_direct", "scenario_runner"]

  @doc """
  Declares the benchmark report model, baselines, and known limits.
  """
  def capabilities do
    %{
      report: :propagator_benchmark_summary,
      model: :persisted_benchmark_median_speedup_summary,
      validation_level: :artifact_contract,
      baseline_modes: @baseline_modes,
      grouping: [:scenario_count, :mode],
      statistics: [:median_elapsed_ms, :median_samples_per_second, :speedup_vs_baseline],
      known_limits: [
        :artifact_level_only,
        :median_summary_only,
        :no_statistical_significance_test,
        :speedup_depends_on_matching_scenario_count_baselines
      ]
    }
  end

  @type mode_summary :: %{
          mode: String.t(),
          scenario_count: non_neg_integer(),
          sample_count: non_neg_integer(),
          repetitions: pos_integer(),
          failures: non_neg_integer(),
          median_elapsed_ms: float(),
          median_samples_per_second: float(),
          speedup_vs_scalar_direct: float() | nil,
          speedup_vs_scenario_runner: float() | nil
        }

  @doc """
  Reads a benchmark artifact from disk.
  """
  def read_artifact!(path) when is_binary(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  @doc """
  Builds grouped benchmark summaries from an artifact map.
  """
  def summarize(artifact, opts \\ [])

  def summarize(%{"results" => results} = artifact, opts) when is_list(results) do
    groups =
      results
      |> Enum.group_by(fn result -> {integer_value(result["scenario_count"]), result["mode"]} end)
      |> Enum.map(fn {{scenario_count, mode}, rows} ->
        sample_count = rows |> Enum.map(&numeric_value(&1["sample_count"])) |> median()

        %{
          mode: mode,
          scenario_count: scenario_count,
          sample_count: maybe_round(sample_count),
          repetitions: length(rows),
          failures: Enum.reduce(rows, 0, &((integer_value(&1["failure_count"]) || 0) + &2)),
          median_elapsed_ms: median(Enum.map(rows, &elapsed_ms/1)),
          median_samples_per_second: median(Enum.map(rows, &samples_per_second/1))
        }
      end)
      |> Enum.sort_by(&{&1.scenario_count || 0, &1.median_elapsed_ms || :infinity})

    baselines = baseline_by_count(groups)

    %{
      schema_version: artifact["schema_version"],
      generated_at: artifact["generated_at"],
      environment: artifact["environment"] || %{},
      benchmark_options: artifact["benchmark_options"] || %{},
      operational_scale_target: Keyword.get(opts, :scale_target),
      groups:
        Enum.map(groups, fn group ->
          group
          |> attach_speedups(baselines)
          |> attach_scale_comparison(Keyword.get(opts, :scale_target))
        end)
    }
  end

  defp baseline_by_count(groups) do
    groups
    |> Enum.filter(&(&1.mode in @baseline_modes))
    |> Enum.group_by(& &1.scenario_count)
    |> Map.new(fn {scenario_count, rows} ->
      baselines =
        Map.new(rows, fn row ->
          {row.mode, row.median_elapsed_ms}
        end)

      {scenario_count, baselines}
    end)
  end

  defp attach_speedups(summary, baselines) do
    count_baselines = Map.get(baselines, summary.scenario_count, %{})

    summary
    |> Map.put(
      :speedup_vs_scalar_direct,
      speedup(Map.get(count_baselines, "scalar_direct"), summary.median_elapsed_ms)
    )
    |> Map.put(
      :speedup_vs_scenario_runner,
      speedup(Map.get(count_baselines, "scenario_runner"), summary.median_elapsed_ms)
    )
  end

  defp attach_scale_comparison(group, nil), do: group

  defp attach_scale_comparison(group, scale_target) do
    case OperationalScale.compare_benchmark_group(scale_target, group) do
      {:ok, comparison} -> Map.put(group, :operational_scale_comparison, comparison)
      {:error, _reason} -> group
    end
  end

  defp elapsed_ms(%{"elapsed_ms" => elapsed_ms}) do
    numeric_value(elapsed_ms)
  end

  defp elapsed_ms(%{"elapsed_us" => elapsed_us}) do
    case numeric_value(elapsed_us) do
      value when is_number(value) -> value / 1_000.0
      nil -> nil
    end
  end

  defp samples_per_second(%{"metadata" => %{"samples_per_second" => value}}) do
    numeric_value(value)
  end

  defp samples_per_second(row) do
    sample_count = numeric_value(row["sample_count"])
    elapsed_ms = elapsed_ms(row)

    if is_number(sample_count) and is_number(elapsed_ms) and elapsed_ms != 0.0 do
      sample_count / (elapsed_ms / 1_000.0)
    end
  end

  defp speedup(nil, _elapsed_ms), do: nil
  defp speedup(_baseline_ms, nil), do: nil

  defp speedup(_baseline_ms, elapsed_ms) when elapsed_ms == 0.0 do
    nil
  end

  defp speedup(baseline_ms, elapsed_ms), do: baseline_ms / elapsed_ms

  defp integer_value(value) do
    case numeric_value(value) do
      number when is_number(number) and trunc(number) == number -> trunc(number)
      _value -> nil
    end
  end

  defp numeric_value(value) when is_number(value), do: value * 1.0

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp maybe_round(value) when is_number(value), do: round(value)
  defp maybe_round(_value), do: 0

  defp median(values) do
    sorted = values |> Enum.filter(&is_number/1) |> Enum.sort()
    count = length(sorted)
    middle = div(count, 2)

    cond do
      count == 0 -> nil
      rem(count, 2) == 1 -> Enum.at(sorted, middle) * 1.0
      true -> (Enum.at(sorted, middle - 1) + Enum.at(sorted, middle)) / 2.0
    end
  end
end
