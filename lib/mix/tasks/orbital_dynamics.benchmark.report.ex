defmodule Mix.Tasks.OrbitalDynamics.Benchmark.Report do
  @moduledoc """
  Prints a summary report for a saved benchmark artifact.

  Usage:

      mix orbital_dynamics.benchmark.report benchmark_results/exla_cpu_long_1000.json
  """

  use Mix.Task

  alias OrbitalDynamics.Benchmark.Report

  @shortdoc "Reports benchmark artifact medians and speedups"

  @impl Mix.Task
  def run(args) do
    opts = parse_args!(args)
    path = Keyword.fetch!(opts, :path)

    path
    |> Report.read_artifact!()
    |> Report.summarize(scale_target: Keyword.get(opts, :scale_target))
    |> print_report(path)
  end

  defp parse_args!(args) do
    {parsed, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          scale_target: :string
        ]
      )

    unless length(rest) == 1 and invalid == [] do
      Mix.raise("usage: mix orbital_dynamics.benchmark.report PATH [--scale-target TARGET]")
    end

    Keyword.put(parsed, :path, hd(rest))
  end

  defp print_report(summary, path) do
    Mix.shell().info("")
    Mix.shell().info("OrbitalDynamics benchmark report")
    Mix.shell().info("artifact: #{path}")
    Mix.shell().info("generated_at: #{summary.generated_at}")
    print_environment(summary.environment)
    print_options(summary.benchmark_options)
    Mix.shell().info("")

    Mix.shell().info(
      pad("scenarios", 12) <>
        pad("mode", 18) <>
        pad("reps", 8) <>
        pad("median ms", 14) <>
        pad("samples/s", 16) <>
        pad("vs scalar", 14) <>
        pad("vs runner", 14) <>
        "failures"
    )

    Mix.shell().info(String.duplicate("-", 108))

    Enum.each(summary.groups, fn group ->
      Mix.shell().info(
        pad(to_string(group.scenario_count), 12) <>
          pad(group.mode, 18) <>
          pad(to_string(group.repetitions), 8) <>
          pad(format_float(group.median_elapsed_ms), 14) <>
          pad(format_float(group.median_samples_per_second), 16) <>
          pad(format_speedup(group.speedup_vs_scalar_direct), 14) <>
          pad(format_speedup(group.speedup_vs_scenario_runner), 14) <>
          to_string(group.failures)
      )
    end)

    Mix.shell().info("")
    print_fastest(summary.groups)
    print_scale_comparisons(summary)
  end

  defp print_environment(environment) do
    Mix.shell().info(
      "environment: Elixir #{environment["elixir_version"]}, OTP #{environment["otp_release"]}, " <>
        "schedulers #{environment["schedulers_online"]}, #{environment["system_architecture"]}"
    )
  end

  defp print_options(options) do
    Mix.shell().info("options: #{inspect(options)}")
  end

  defp print_fastest(groups) do
    groups
    |> Enum.group_by(& &1.scenario_count)
    |> Enum.sort_by(fn {scenario_count, _groups} -> scenario_count end)
    |> Enum.each(fn {scenario_count, count_groups} ->
      fastest = Enum.min_by(count_groups, & &1.median_elapsed_ms)

      Mix.shell().info(
        "fastest for #{scenario_count} scenarios: #{fastest.mode} " <>
          "(#{format_float(fastest.median_elapsed_ms)} ms)"
      )
    end)
  end

  defp print_scale_comparisons(%{operational_scale_target: nil}), do: :ok

  defp print_scale_comparisons(summary) do
    Mix.shell().info("")
    Mix.shell().info("operational scale target: #{summary.operational_scale_target}")

    Enum.each(summary.groups, fn group ->
      comparison = Map.get(group, :operational_scale_comparison)

      Mix.shell().info(
        "scale #{group.scenario_count} #{group.mode}: #{comparison_status(comparison)}, " <>
          "scenarios #{metric_status(comparison, "scenario_count")}, " <>
          "runtime #{metric_status(comparison, "local_runtime_s")}, " <>
          "distribution #{distribution_status(comparison)}"
      )
    end)
  end

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

  defp pad(value, width), do: value |> to_string() |> String.pad_trailing(width)
  defp format_float(value), do: :erlang.float_to_binary(value * 1.0, decimals: 2)

  defp format_speedup(nil), do: "n/a"
  defp format_speedup(value), do: "#{format_float(value)}x"
end
