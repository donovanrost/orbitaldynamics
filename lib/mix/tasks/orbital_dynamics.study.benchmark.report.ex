defmodule Mix.Tasks.OrbitalDynamics.Study.Benchmark.Report do
  @moduledoc """
  Prints a summary report for a saved study benchmark artifact.

  Usage:

      mix orbital_dynamics.study.benchmark.report study_results/monte_carlo_scaling.json
      mix orbital_dynamics.study.benchmark.report study_results/monte_carlo_scaling.json study_results/distributed_chunk_sweep.json
      mix orbital_dynamics.study.benchmark.report study_results/monte_carlo_scaling.json --format json
  """

  use Mix.Task

  alias OrbitalDynamics.Study.Benchmark.Report

  @shortdoc "Reports study benchmark medians, speedups, and node balance"

  @impl Mix.Task
  def run(args) do
    opts = parse_args!(args)
    paths = Keyword.fetch!(opts, :paths)
    format = Keyword.fetch!(opts, :format)

    case paths do
      [path] ->
        path
        |> Report.read_artifact!()
        |> Report.summarize(scale_target: Keyword.get(opts, :scale_target))
        |> print_report(path, format)

      paths ->
        paths
        |> Report.trend_summary(
          scale_target: Keyword.get(opts, :scale_target),
          tolerance_percent: Keyword.fetch!(opts, :tolerance_percent)
        )
        |> print_trend_report(paths, format)
    end
  end

  defp parse_args!(args) do
    {parsed, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          scale_target: :string,
          tolerance_percent: :float,
          format: :string
        ]
      )

    unless length(rest) >= 1 and invalid == [] do
      Mix.raise(
        "usage: mix orbital_dynamics.study.benchmark.report PATH [PATH ...] [--scale-target TARGET] [--tolerance-percent PERCENT]"
      )
    end

    format = Keyword.get(parsed, :format, "text")

    unless format in ["text", "json"] do
      Mix.raise("--format must be text or json")
    end

    parsed
    |> Keyword.put(:paths, rest)
    |> Keyword.put_new(:tolerance_percent, 0.0)
    |> Keyword.put(:format, format)
  end

  defp print_report(summary, path, "json") do
    %{
      report_type: "study_benchmark_summary",
      artifact: path,
      summary: summary
    }
    |> json_safe()
    |> :json.encode()
    |> IO.iodata_to_binary()
    |> Mix.shell().info()
  end

  defp print_report(summary, path, "text") do
    Mix.shell().info("")
    Mix.shell().info("OrbitalDynamics study benchmark report")
    Mix.shell().info("artifact: #{path}")
    Mix.shell().info("generated_at: #{summary.generated_at}")
    Mix.shell().info("manifest: #{summary.manifest["path"] || "unknown"}")
    Mix.shell().info("options: #{inspect(summary.benchmark_options)}")
    Mix.shell().info("")

    Mix.shell().info(
      pad("mc count", 12) <>
        pad("propagator", 24) <>
        pad("conc", 8) <>
        pad("eff conc", 10) <>
        pad("chunk", 10) <>
        pad("mode", 14) <>
        pad("reps", 8) <>
        pad("scenarios", 12) <>
        pad("median ms", 14) <>
        pad("prop ms", 12) <>
        pad("overhead", 12) <>
        pad("over %", 10) <>
        pad("sched %", 10) <>
        pad("artifact", 10) <>
        pad("size MB", 10) <>
        pad("scen/s", 14) <>
        pad("vs local", 12) <>
        pad("match", 8) <>
        pad("nodes", 8) <>
        pad("balance", 10) <>
        "node balance"
    )

    Mix.shell().info(String.duplicate("-", 160))

    Enum.each(summary.groups, fn group ->
      Mix.shell().info(
        pad(format_count(group.monte_carlo_count), 12) <>
          pad(group.propagator || "default", 24) <>
          pad(format_count(group.max_concurrency), 8) <>
          pad(format_count(group.effective_task_concurrency), 10) <>
          pad(format_count(group.task_chunk_size), 10) <>
          pad(group.mode, 14) <>
          pad(to_string(group.repetitions), 8) <>
          pad(format_float(group.scenario_count), 12) <>
          pad(format_float(group.median_duration_ms), 14) <>
          pad(format_optional_float(group.median_propagation_ms), 12) <>
          pad(format_optional_float(group.median_overhead_ms), 12) <>
          pad(format_optional_percent(group.median_overhead_percent), 10) <>
          pad(format_optional_ratio_percent(group.median_scheduler_utilization), 10) <>
          pad(format_optional_float(group.median_artifact_build_ms), 10) <>
          pad(format_optional_float(group.median_artifact_size_mb), 10) <>
          pad(format_optional_float(group.median_scenarios_per_second), 14) <>
          pad(format_speedup(group.speedup_vs_local), 12) <>
          pad(to_string(group.output_matches_baseline), 8) <>
          pad(to_string(group.node_count), 8) <>
          pad(format_optional_ratio_percent(group.node_balance_ratio), 10) <>
          format_node_counts(group.per_node_trajectory_counts)
      )
    end)

    Mix.shell().info("")
    print_fastest(summary.groups)
    print_output_mismatches(summary.groups)
    print_scale_comparisons(summary)
  end

  defp print_fastest(groups) do
    groups
    |> Enum.group_by(& &1.monte_carlo_count)
    |> Enum.sort_by(fn {count, _groups} -> count_sort_value(count) end)
    |> Enum.each(fn {count, groups} ->
      fastest = Enum.min_by(groups, & &1.median_duration_ms)

      Mix.shell().info(
        "fastest for #{format_count(count)}: #{fastest.mode} #{fastest.propagator || "default"}#{format_concurrency_suffix(fastest.max_concurrency)}#{format_chunk_suffix(fastest.task_chunk_size)} " <>
          "(#{format_float(fastest.median_duration_ms)} ms, " <>
          "#{format_optional_float(fastest.median_scenarios_per_second)} scenarios/s)"
      )
    end)
  end

  defp print_output_mismatches(groups) do
    mismatches = Enum.reject(groups, & &1.output_matches_baseline)

    if mismatches != [] do
      Mix.shell().info("")
      Mix.shell().info("output mismatches:")

      Enum.each(mismatches, fn group ->
        Mix.shell().info(
          "#{group.mode} #{group.propagator || "default"} #{format_count(group.monte_carlo_count)}#{format_concurrency_suffix(group.max_concurrency)}#{format_chunk_suffix(group.task_chunk_size)}"
        )
      end)
    end
  end

  defp print_scale_comparisons(%{operational_scale_target: nil}), do: :ok

  defp print_scale_comparisons(summary) do
    Mix.shell().info("")
    Mix.shell().info("operational scale target: #{summary.operational_scale_target}")

    Enum.each(summary.groups, fn group ->
      comparison = Map.get(group, :operational_scale_comparison)

      Mix.shell().info(
        "scale #{format_count(group.monte_carlo_count)} #{group.mode}: #{comparison_status(comparison)}, " <>
          "scenarios #{metric_status(comparison, "scenario_count")}, " <>
          "runtime #{metric_status(comparison, "local_runtime_s")}, " <>
          "distribution #{distribution_status(comparison)}"
      )
    end)
  end

  defp print_trend_report(summary, paths, "json") do
    %{
      report_type: "study_benchmark_trend",
      artifacts: paths,
      summary: summary
    }
    |> json_safe()
    |> :json.encode()
    |> IO.iodata_to_binary()
    |> Mix.shell().info()
  end

  defp print_trend_report(summary, paths, "text") do
    Mix.shell().info("")
    Mix.shell().info("OrbitalDynamics study benchmark trend report")
    Mix.shell().info("artifacts: #{Enum.join(paths, ", ")}")
    Mix.shell().info("artifact_count: #{summary.artifact_count}")
    print_trend_scale_comparison(summary)
    Mix.shell().info("")

    Mix.shell().info(
      pad("mc count", 12) <>
        pad("propagator", 24) <>
        pad("conc", 8) <>
        pad("chunk", 10) <>
        pad("mode", 14) <>
        pad("samples", 10) <>
        pad("first ms", 12) <>
        pad("latest ms", 12) <>
        pad("delta %", 10) <>
        pad("trend", 14) <>
        pad("match", 8) <>
        "generated_at"
    )

    Mix.shell().info(String.duplicate("-", 144))

    Enum.each(summary.groups, fn group ->
      Mix.shell().info(
        pad(format_count(group.monte_carlo_count), 12) <>
          pad(group.propagator || "default", 24) <>
          pad(format_count(group.max_concurrency), 8) <>
          pad(format_count(group.task_chunk_size), 10) <>
          pad(group.mode, 14) <>
          pad(to_string(group.sample_count), 10) <>
          pad(format_optional_float(group.first_median_duration_ms), 12) <>
          pad(format_optional_float(group.latest_median_duration_ms), 12) <>
          pad(format_optional_percent(group.duration_delta_percent), 10) <>
          pad(group.trend_status, 14) <>
          pad(to_string(group.latest_output_matches_baseline), 8) <>
          "#{group.first_generated_at} -> #{group.latest_generated_at}"
      )
    end)
  end

  defp print_trend_scale_comparison(%{operational_scale_target: nil}), do: :ok

  defp print_trend_scale_comparison(%{
         operational_scale_target: scale_target,
         operational_scale_trend_comparison: comparison
       }) do
    Mix.shell().info("operational scale target: #{scale_target}")
    Mix.shell().info("scale trend status: #{comparison_status(comparison)}")
  end

  defp print_trend_scale_comparison(_summary), do: :ok

  defp comparison_status(%{"status" => status}), do: status
  defp comparison_status(_comparison), do: "not_evaluated"

  defp metric_status(%{"rows" => rows}, metric) do
    rows
    |> Enum.find(&(&1["metric"] == metric))
    |> case do
      %{"status" => status} -> status
      _missing -> "not_evaluated"
    end
  end

  defp metric_status(_comparison, _metric), do: "not_evaluated"

  defp distribution_status(%{"distribution_guidance" => %{"status" => status}}), do: status
  defp distribution_status(_comparison), do: "not_evaluated"

  defp format_count(nil), do: "default"
  defp format_count(count), do: to_string(count)

  defp format_chunk_suffix(nil), do: ""
  defp format_chunk_suffix(chunk_size), do: " chunk #{chunk_size}"

  defp format_concurrency_suffix(nil), do: ""
  defp format_concurrency_suffix(max_concurrency), do: " concurrency #{max_concurrency}"

  defp count_sort_value(nil), do: 0
  defp count_sort_value(count), do: count

  defp format_node_counts(counts) when counts == %{}, do: "none"

  defp format_node_counts(counts) do
    counts
    |> Enum.sort_by(fn {node, _count} -> node end)
    |> Enum.map(fn {node, count} -> "#{node}:#{count}" end)
    |> Enum.join(", ")
  end

  defp pad(value, width), do: value |> to_string() |> String.pad_trailing(width)
  defp format_float(value), do: :erlang.float_to_binary(value * 1.0, decimals: 2)
  defp format_optional_float(nil), do: "n/a"
  defp format_optional_float(value), do: format_float(value)
  defp format_optional_percent(nil), do: "n/a"
  defp format_optional_percent(value), do: "#{format_float(value)}%"
  defp format_optional_ratio_percent(nil), do: "n/a"
  defp format_optional_ratio_percent(value), do: "#{format_float(value * 100.0)}%"
  defp format_speedup(nil), do: "n/a"
  defp format_speedup(value), do: "#{format_float(value)}x"

  defp json_safe(%{} = map) do
    Map.new(map, fn {key, value} -> {json_key(key), json_safe(value)} end)
  end

  defp json_safe(values) when is_list(values), do: Enum.map(values, &json_safe/1)
  defp json_safe(value) when is_atom(value), do: Atom.to_string(value)
  defp json_safe(value), do: value

  defp json_key(key) when is_atom(key), do: Atom.to_string(key)
  defp json_key(key), do: key
end
