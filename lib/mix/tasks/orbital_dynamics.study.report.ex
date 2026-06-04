defmodule Mix.Tasks.OrbitalDynamics.Study.Report do
  @moduledoc """
  Prints a summary report for a saved study result artifact.

  Usage:

      mix orbital_dynamics.study.report --input study_results/leo_access_demo.json
      mix orbital_dynamics.study.report --input study_results/leo_access_demo.json --rank final_radius_km --limit 5
      mix orbital_dynamics.study.report --input study_results/leo_access_demo.json --compare study_results/leo_access_demo_manifest.json
  """

  use Mix.Task

  alias OrbitalDynamics.ResultSet.Report

  @shortdoc "Reports study artifact summaries and comparisons"

  @impl Mix.Task
  def run(args) do
    opts = parse_args!(args)
    input_path = Keyword.fetch!(opts, :input)
    input = Report.read_artifact!(input_path)

    cond do
      Keyword.has_key?(opts, :compare) ->
        compare_path = Keyword.fetch!(opts, :compare)
        compare = Report.read_artifact!(compare_path)

        input
        |> Report.compare(compare)
        |> print_comparison(input_path, compare_path)

      Keyword.has_key?(opts, :rank) ->
        objective = Keyword.fetch!(opts, :rank)
        limit = Keyword.get(opts, :limit, 10)

        input
        |> Report.rank(objective, limit: limit)
        |> print_ranking(input_path, objective)

      true ->
        input
        |> Report.summarize()
        |> print_summary(input_path)
    end
  end

  defp parse_args!(args) do
    {parsed, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          input: :string,
          compare: :string,
          rank: :string,
          limit: :integer
        ]
      )

    unless rest == [] and invalid == [] do
      Mix.raise("invalid study report arguments: #{inspect(rest ++ invalid)}")
    end

    unless Keyword.has_key?(parsed, :input) do
      Mix.raise("--input is required")
    end

    parsed
  end

  defp print_summary(summary, path) do
    Mix.shell().info("")
    Mix.shell().info("OrbitalDynamics study report")
    Mix.shell().info("artifact: #{path}")
    Mix.shell().info("study: #{summary.study_id}")
    Mix.shell().info("generated_at: #{summary.generated_at}")
    Mix.shell().info("outputs: #{format_list(get_in(summary.assumptions, ["outputs"]) || [])}")
    Mix.shell().info("propagator: #{summary.assumptions["propagator"]}")
    Mix.shell().info("central_body: #{summary.assumptions["central_body"]}")
    Mix.shell().info("interpolation: #{format_list(summary.interpolation_modes)}")
    print_run(summary.run)
    Mix.shell().info("")
    print_counts(summary.counts)
    print_maneuvers(summary.maneuvers)
    Mix.shell().info("")
    print_duration_stats("access duration", summary.durations.access_windows)
    print_duration_stats("eclipse duration", summary.durations.eclipse_intervals)
    print_monte_carlo(summary.monte_carlo)
    print_constraints(summary.constraints, summary.best_feasible_ranking)
    print_declared_ranking(summary.scenario_rankings)
  end

  defp print_comparison(comparison, left_path, right_path) do
    Mix.shell().info("")
    Mix.shell().info("OrbitalDynamics study comparison")
    Mix.shell().info("left: #{left_path}")
    Mix.shell().info("right: #{right_path}")
    Mix.shell().info("same study id: #{comparison.same_study_id}")
    Mix.shell().info("same scenario ids: #{comparison.scenario_ids.same}")
    Mix.shell().info("same outputs: #{comparison.outputs.same}")
    Mix.shell().info("")
    print_count_deltas(comparison.count_deltas)
    Mix.shell().info("")
    print_boundary_summary("access windows", comparison.boundary_deltas.access_windows)
    print_boundary_summary("eclipse intervals", comparison.boundary_deltas.eclipse_intervals)
    print_ranking_comparison(comparison.ranking_comparison_report)
  end

  defp print_ranking(rows, path, objective) do
    Mix.shell().info("")
    Mix.shell().info("OrbitalDynamics study ranking")
    Mix.shell().info("artifact: #{path}")
    Mix.shell().info("objective: #{objective}")
    Mix.shell().info("")
    Mix.shell().info(pad("rank", 8) <> pad("scenario", 28) <> pad("value", 16) <> "delta-v km/s")
    Mix.shell().info(String.duplicate("-", 66))

    rows
    |> Enum.with_index(1)
    |> Enum.each(fn {row, rank} ->
      Mix.shell().info(
        pad(to_string(rank), 8) <>
          pad(row.scenario_id, 28) <>
          pad(format_float(row.value), 16) <>
          format_float(row.total_delta_v_km_s)
      )
    end)
  end

  defp print_declared_ranking(nil), do: :ok

  defp print_declared_ranking(%{"rows" => rows} = ranking) when is_list(rows) do
    Mix.shell().info("")

    Mix.shell().info(
      "declared ranking: #{ranking["objective"]} (#{ranking["objective_direction"]})"
    )

    Mix.shell().info(pad("rank", 8) <> pad("scenario", 28) <> pad("value", 16) <> "delta-v km/s")
    Mix.shell().info(String.duplicate("-", 66))

    rows
    |> Enum.with_index(1)
    |> Enum.each(fn {row, rank} ->
      Mix.shell().info(
        pad(to_string(rank), 8) <>
          pad(row["scenario_id"], 28) <>
          pad(format_float(row["value"]), 16) <>
          format_float(row["total_delta_v_km_s"])
      )
    end)
  end

  defp print_declared_ranking(_ranking), do: :ok

  defp print_run(nil), do: :ok

  defp print_run(%{} = run) do
    metadata = Map.get(run, "metadata", %{})

    Mix.shell().info("run duration: #{format_milliseconds(run["duration_ms"])}")
    Mix.shell().info("execution: #{Map.get(metadata, "execution_mode", "unknown")}")
    Mix.shell().info("node: #{Map.get(run, "node", "unknown")}")

    Mix.shell().info(
      "task supervisor node: #{Map.get(metadata, "task_supervisor_node", "unknown")}"
    )

    Mix.shell().info(
      "max concurrency: #{get_in(run, ["options", "max_concurrency"]) || "unknown"}"
    )

    Mix.shell().info("schedulers: #{Map.get(metadata, "scheduler_count", "unknown")}")
  end

  defp print_constraints(%{count: 0}, _best_feasible_ranking), do: :ok

  defp print_constraints(constraints, best_feasible_ranking) do
    Mix.shell().info("")

    Mix.shell().info(
      "constraints: pass #{constraints.pass}, fail #{constraints.fail}, warning #{constraints.warning}"
    )

    if constraints.failing_scenarios != [] do
      Mix.shell().info("failing scenarios: #{format_list(constraints.failing_scenarios)}")
    end

    print_best_feasible_ranking(best_feasible_ranking)
  end

  defp print_best_feasible_ranking(nil), do: :ok

  defp print_best_feasible_ranking(row) do
    Mix.shell().info(
      "best feasible ranked scenario: #{row["scenario_id"]} " <>
        "(#{row["objective"]} #{format_float(row["value"])}, delta-v #{format_float(row["total_delta_v_km_s"])} km/s)"
    )
  end

  defp print_ranking_comparison(nil), do: :ok

  defp print_ranking_comparison(%{} = report) do
    Mix.shell().info("")

    Mix.shell().info(
      "ranking comparison: #{report["objective"]} (#{report["objective_direction"]})"
    )

    Mix.shell().info("winner changed: #{get_in(report, ["winner", "changed"])}")

    Mix.shell().info(
      "ranking rows: #{report["row_count"]}, matched #{report["matched_count"]}, " <>
        "left-only #{report["left_only_count"]}, right-only #{report["right_only_count"]}"
    )
  end

  defp print_counts(counts) do
    Mix.shell().info("trajectories: #{counts.trajectories}")
    Mix.shell().info("access windows: #{counts.access_windows}")
    Mix.shell().info("eclipse intervals: #{counts.eclipse_intervals}")
    Mix.shell().info("errors: #{counts.errors}")
  end

  defp print_count_deltas(deltas) do
    Mix.shell().info("count deltas, right - left")
    Mix.shell().info("trajectories: #{signed(deltas.trajectories)}")
    Mix.shell().info("access windows: #{signed(deltas.access_windows)}")
    Mix.shell().info("eclipse intervals: #{signed(deltas.eclipse_intervals)}")
    Mix.shell().info("errors: #{signed(deltas.errors)}")
  end

  defp print_maneuvers(maneuvers) do
    Mix.shell().info("maneuver scenarios: #{maneuvers.scenario_count_with_maneuvers}")
    Mix.shell().info("maneuvers: #{maneuvers.maneuver_count}")
    Mix.shell().info("total delta-v: #{format_float(maneuvers.total_delta_v_km_s)} km/s")
  end

  defp print_duration_stats(label, stats) do
    Mix.shell().info(
      "#{label}: count #{stats.count}, min #{format_seconds(stats.min_s)}, " <>
        "mean #{format_seconds(stats.mean_s)}, max #{format_seconds(stats.max_s)}"
    )
  end

  defp print_monte_carlo(nil), do: :ok

  defp print_monte_carlo(%{} = monte_carlo) do
    Mix.shell().info("")

    Mix.shell().info(
      "monte carlo: samples #{monte_carlo.sample_count}/#{monte_carlo.requested_count}, seed #{monte_carlo.seed}"
    )

    print_metric_stats("final radius km", monte_carlo.metrics.final_radius_km)
    print_metric_stats("final speed km/s", monte_carlo.metrics.final_speed_km_s)
    print_metric_stats("min altitude km", monte_carlo.metrics.min_altitude_km)
    print_metric_stats("max altitude km", monte_carlo.metrics.max_altitude_km)
    print_metric_stats("perigee altitude km", monte_carlo.metrics.perigee_altitude_km)
    print_metric_stats("apogee altitude km", monte_carlo.metrics.apogee_altitude_km)
    print_metric_stats("eccentricity", monte_carlo.metrics.eccentricity)
    print_metric_stats("access duration", monte_carlo.metrics.access_duration_s)
    print_metric_stats("eclipse duration", monte_carlo.metrics.eclipse_duration_s)
    print_metric_stats("total delta-v km/s", monte_carlo.metrics.total_delta_v_km_s)
    print_monte_carlo_constraints(monte_carlo.constraints)
  end

  defp print_metric_stats(label, stats) do
    Mix.shell().info(
      "#{label}: min #{format_float_or_na(stats.min)}, mean #{format_float_or_na(stats.mean)}, " <>
        "max #{format_float_or_na(stats.max)}"
    )
  end

  defp print_monte_carlo_constraints(%{pass_probability: nil}), do: :ok

  defp print_monte_carlo_constraints(%{} = constraints) do
    Mix.shell().info(
      "constraint pass probability: #{format_probability(constraints.pass_probability)} " <>
        "(#{constraints.passed_scenarios} passed)"
    )
  end

  defp print_boundary_summary(label, deltas) do
    max_start_delta =
      deltas.rows
      |> Enum.map(& &1.starts_at_delta_s)
      |> max_abs()

    max_end_delta =
      deltas.rows
      |> Enum.map(& &1.ends_at_delta_s)
      |> max_abs()

    Mix.shell().info(
      "#{label}: matched #{deltas.matched_count}, missing_left #{length(deltas.missing_left)}, " <>
        "missing_right #{length(deltas.missing_right)}, max_start_delta #{format_seconds(max_start_delta)}, " <>
        "max_end_delta #{format_seconds(max_end_delta)}"
    )
  end

  defp format_list([]), do: "none"
  defp format_list(values), do: Enum.join(values, ", ")
  defp pad(value, width), do: value |> to_string() |> String.pad_trailing(width)

  defp format_seconds(nil), do: "n/a"
  defp format_seconds(value), do: "#{:erlang.float_to_binary(value * 1.0, decimals: 3)}s"
  defp format_milliseconds(nil), do: "n/a"
  defp format_milliseconds(value), do: "#{value}ms"
  defp format_float(value), do: :erlang.float_to_binary(value * 1.0, decimals: 6)
  defp format_float_or_na(nil), do: "n/a"
  defp format_float_or_na(value), do: format_float(value)
  defp format_probability(value), do: :erlang.float_to_binary(value * 100.0, decimals: 2) <> "%"

  defp max_abs([]), do: nil

  defp max_abs(values) do
    values
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> nil
      values -> values |> Enum.map(&abs/1) |> Enum.max()
    end
  end

  defp signed(value) when value > 0, do: "+#{value}"
  defp signed(value), do: to_string(value)
end
