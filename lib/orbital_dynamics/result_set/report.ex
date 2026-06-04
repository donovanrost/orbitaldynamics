defmodule OrbitalDynamics.ResultSet.Report do
  @moduledoc """
  Summary and comparison helpers for persisted study result artifacts.
  """

  alias OrbitalDynamics.Optimizer

  @doc """
  Declares the reporting model, supported metrics, and known limits.
  """
  def capabilities do
    %{
      report: :result_set_summary,
      model: :persisted_artifact_summary_and_ranking,
      validation_level: :artifact_contract,
      supported_objectives: supported_objectives(),
      ranking_directions:
        Map.new(supported_objectives(), fn objective ->
          {objective, objective_direction_label(objective)}
        end),
      known_limits: [
        :artifact_level_only,
        :no_rerun_propagation,
        :event_duration_from_artifact_boundaries,
        :missing_metric_rows_are_excluded_from_rankings
      ]
    }
  end

  @doc """
  Returns the declared model limits for persisted result-artifact summaries and rankings.
  """
  def model_limits do
    capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  @doc """
  Reads a study result artifact from disk.
  """
  def read_artifact!(path) when is_binary(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  @doc """
  Builds a compact summary from a study result artifact map.
  """
  def summarize(%{} = artifact) do
    trajectories = Map.get(artifact, "trajectories", [])
    access_windows = Map.get(artifact, "access_windows", [])
    eclipse_intervals = Map.get(artifact, "eclipse_intervals", [])
    errors = Map.get(artifact, "errors", [])

    %{
      schema_version: artifact["schema_version"],
      generated_at: artifact["generated_at"],
      study_id: artifact["study_id"],
      counts: %{
        trajectories: length(trajectories),
        access_windows: length(access_windows),
        eclipse_intervals: length(eclipse_intervals),
        errors: length(errors)
      },
      scenario_ids: scenario_ids(artifact),
      assumptions: Map.get(artifact, "assumptions", %{}),
      maneuvers: maneuver_summary(trajectories),
      interpolation_modes: interpolation_modes(access_windows, eclipse_intervals),
      durations: %{
        access_windows: duration_stats(access_windows),
        eclipse_intervals: duration_stats(eclipse_intervals)
      },
      monte_carlo: monte_carlo_summary(artifact),
      run: Map.get(artifact, "run") || get_in(artifact, ["metadata", "run"]),
      scenario_rankings: Map.get(artifact, "scenario_rankings"),
      constraints: constraint_summary(Map.get(artifact, "constraint_results", [])),
      best_feasible_ranking: best_feasible_ranking(artifact)
    }
  end

  @doc """
  Compares two study result artifacts.
  """
  def compare(%{} = left, %{} = right) do
    left_summary = summarize(left)
    right_summary = summarize(right)

    %{
      left: left_summary,
      right: right_summary,
      same_study_id: left_summary.study_id == right_summary.study_id,
      scenario_ids: compare_lists(left_summary.scenario_ids, right_summary.scenario_ids),
      outputs:
        compare_lists(outputs(left_summary.assumptions), outputs(right_summary.assumptions)),
      count_deltas: %{
        trajectories: right_summary.counts.trajectories - left_summary.counts.trajectories,
        access_windows: right_summary.counts.access_windows - left_summary.counts.access_windows,
        eclipse_intervals:
          right_summary.counts.eclipse_intervals - left_summary.counts.eclipse_intervals,
        errors: right_summary.counts.errors - left_summary.counts.errors
      },
      boundary_deltas: %{
        access_windows: boundary_deltas(access_window_rows(left), access_window_rows(right)),
        eclipse_intervals:
          boundary_deltas(eclipse_interval_rows(left), eclipse_interval_rows(right))
      },
      ranking_comparison_report: ranking_comparison_report(left_summary, right_summary)
    }
  end

  @doc """
  Ranks scenarios in an artifact by a supported objective.

  Objectives:

    * `"final_radius_km"` - maximize final orbital radius
    * `"final_speed_km_s"` - maximize final speed
    * `"min_altitude_km"` - maximize minimum sampled altitude
    * `"max_altitude_km"` - maximize maximum sampled altitude
    * `"perigee_altitude_km"` - maximize final-state perigee altitude
    * `"apogee_altitude_km"` - maximize final-state apogee altitude
    * `"eccentricity"` - minimize final-state eccentricity
    * `"access_duration_s"` - maximize total access duration
    * `"eclipse_duration_s"` - minimize total eclipse duration
    * `"total_delta_v_km_s"` - minimize total delta-v
  """
  def rank(%{} = artifact, objective, opts \\ []) when is_binary(objective) do
    direction = objective_direction(objective)
    limit = Keyword.get(opts, :limit, :all)

    artifact
    |> scenario_metrics()
    |> Enum.map(&ranking_row(&1, objective))
    |> Enum.filter(&is_number(&1.value))
    |> Enum.sort_by(& &1.value, sort_direction(direction))
    |> maybe_limit(limit)
  end

  @doc """
  Returns one compact metric row per scenario.
  """
  def scenario_metrics(%{} = artifact) do
    access_durations = event_durations_by_scenario(Map.get(artifact, "access_windows", []))
    eclipse_durations = event_durations_by_scenario(Map.get(artifact, "eclipse_intervals", []))

    artifact
    |> Map.get("trajectories", [])
    |> Enum.map(fn trajectory ->
      scenario_id = trajectory["scenario_id"]
      assumptions = Map.get(trajectory, "assumptions", %{})

      %{
        scenario_id: scenario_id,
        total_delta_v_km_s: numeric_value(Map.get(assumptions, "total_delta_v_km_s")) || 0.0,
        final_radius_km: numeric_value(trajectory["final_radius_km"]),
        final_speed_km_s: numeric_value(trajectory["final_speed_km_s"]),
        min_radius_km: numeric_value(trajectory["min_radius_km"]),
        max_radius_km: numeric_value(trajectory["max_radius_km"]),
        min_altitude_km: numeric_value(trajectory["min_altitude_km"]),
        max_altitude_km: numeric_value(trajectory["max_altitude_km"]),
        semi_major_axis_km: numeric_value(trajectory["semi_major_axis_km"]),
        eccentricity: numeric_value(trajectory["eccentricity"]),
        perigee_radius_km: numeric_value(trajectory["perigee_radius_km"]),
        apogee_radius_km: numeric_value(trajectory["apogee_radius_km"]),
        perigee_altitude_km: numeric_value(trajectory["perigee_altitude_km"]),
        apogee_altitude_km: numeric_value(trajectory["apogee_altitude_km"]),
        access_duration_s: Map.get(access_durations, scenario_id, 0.0),
        eclipse_duration_s: Map.get(eclipse_durations, scenario_id, 0.0)
      }
    end)
  end

  @doc """
  Returns supported objective names.
  """
  def supported_objectives do
    [
      "final_radius_km",
      "final_speed_km_s",
      "min_radius_km",
      "max_radius_km",
      "min_altitude_km",
      "max_altitude_km",
      "semi_major_axis_km",
      "eccentricity",
      "perigee_radius_km",
      "apogee_radius_km",
      "perigee_altitude_km",
      "apogee_altitude_km",
      "access_duration_s",
      "eclipse_duration_s",
      "total_delta_v_km_s"
    ]
  end

  @doc """
  Returns the ranking sort direction for a supported objective.
  """
  def objective_direction(objective) when objective in ["final_radius_km", "final_speed_km_s"],
    do: :desc

  def objective_direction(objective)
      when objective in [
             "min_radius_km",
             "max_radius_km",
             "min_altitude_km",
             "max_altitude_km",
             "semi_major_axis_km",
             "perigee_radius_km",
             "apogee_radius_km",
             "perigee_altitude_km",
             "apogee_altitude_km"
           ],
      do: :desc

  def objective_direction(objective)
      when objective in ["access_duration_s"],
      do: :desc

  def objective_direction(objective)
      when objective in ["eclipse_duration_s", "total_delta_v_km_s", "eccentricity"],
      do: :asc

  def objective_direction(objective),
    do: raise(ArgumentError, "unsupported objective: #{objective}")

  @doc """
  Returns a manifest-facing direction label for a supported objective.
  """
  def objective_direction_label(objective) do
    case objective_direction(objective) do
      :asc -> "minimize"
      :desc -> "maximize"
    end
  end

  defp ranking_row(row, objective) do
    row
    |> Map.put(:objective, objective)
    |> Map.put(:value, Map.fetch!(row, metric_key(objective)))
  end

  defp metric_key("final_radius_km"), do: :final_radius_km
  defp metric_key("final_speed_km_s"), do: :final_speed_km_s
  defp metric_key("min_radius_km"), do: :min_radius_km
  defp metric_key("max_radius_km"), do: :max_radius_km
  defp metric_key("min_altitude_km"), do: :min_altitude_km
  defp metric_key("max_altitude_km"), do: :max_altitude_km
  defp metric_key("semi_major_axis_km"), do: :semi_major_axis_km
  defp metric_key("eccentricity"), do: :eccentricity
  defp metric_key("perigee_radius_km"), do: :perigee_radius_km
  defp metric_key("apogee_radius_km"), do: :apogee_radius_km
  defp metric_key("perigee_altitude_km"), do: :perigee_altitude_km
  defp metric_key("apogee_altitude_km"), do: :apogee_altitude_km
  defp metric_key("access_duration_s"), do: :access_duration_s
  defp metric_key("eclipse_duration_s"), do: :eclipse_duration_s
  defp metric_key("total_delta_v_km_s"), do: :total_delta_v_km_s

  defp event_durations_by_scenario(rows) do
    rows
    |> Enum.group_by(& &1["scenario_id"])
    |> Map.new(fn {scenario_id, scenario_rows} ->
      {scenario_id,
       scenario_rows |> Enum.map(&duration_s/1) |> Enum.reject(&is_nil/1) |> Enum.sum()}
    end)
  end

  defp sort_direction(:asc), do: :asc
  defp sort_direction(:desc), do: :desc

  defp maybe_limit(rows, :all), do: rows
  defp maybe_limit(rows, limit) when is_integer(limit) and limit > 0, do: Enum.take(rows, limit)

  defp scenario_ids(artifact) do
    artifact
    |> Map.get("trajectories", [])
    |> Enum.map(& &1["scenario_id"])
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp interpolation_modes(access_windows, eclipse_intervals) do
    (access_windows ++ eclipse_intervals)
    |> Enum.map(&get_in(&1, ["assumptions", "interpolation"]))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp maneuver_summary(trajectories) do
    trajectory_assumptions = Enum.map(trajectories, &Map.get(&1, "assumptions", %{}))

    %{
      scenario_count_with_maneuvers:
        Enum.count(trajectory_assumptions, fn assumptions ->
          integer_count(Map.get(assumptions, "maneuver_count")) > 0
        end),
      maneuver_count:
        Enum.reduce(trajectory_assumptions, 0, fn assumptions, total ->
          total + integer_count(Map.get(assumptions, "maneuver_count"))
        end),
      total_delta_v_km_s:
        Enum.reduce(trajectory_assumptions, 0.0, fn assumptions, total ->
          total + (numeric_value(Map.get(assumptions, "total_delta_v_km_s")) || 0.0)
        end)
    }
  end

  defp duration_stats(rows) do
    durations =
      rows
      |> Enum.map(&duration_s/1)
      |> Enum.reject(&is_nil/1)

    case durations do
      [] ->
        %{count: 0, min_s: nil, max_s: nil, mean_s: nil}

      durations ->
        %{
          count: length(durations),
          min_s: Enum.min(durations),
          max_s: Enum.max(durations),
          mean_s: Enum.sum(durations) / length(durations)
        }
    end
  end

  defp duration_s(%{"starts_at_s" => starts_at_s, "ends_at_s" => ends_at_s}) do
    starts_at_s = numeric_value(starts_at_s)
    ends_at_s = numeric_value(ends_at_s)

    if is_number(starts_at_s) and is_number(ends_at_s) do
      (ends_at_s - starts_at_s) * 1.0
    end
  end

  defp duration_s(_row), do: nil

  defp monte_carlo_summary(%{} = artifact) do
    case get_in(artifact, ["assumptions", "study_metadata", "monte_carlo"]) do
      %{} = monte_carlo ->
        rows = scenario_metrics(artifact)

        %{
          generator: Map.get(monte_carlo, "generator"),
          seed: Map.get(monte_carlo, "seed"),
          requested_count: Map.get(monte_carlo, "count"),
          sample_count: length(rows),
          position_sigma_km: Map.get(monte_carlo, "position_sigma_km"),
          velocity_sigma_km_s: Map.get(monte_carlo, "velocity_sigma_km_s"),
          metrics: %{
            final_radius_km: metric_stats(rows, :final_radius_km),
            final_speed_km_s: metric_stats(rows, :final_speed_km_s),
            min_altitude_km: metric_stats(rows, :min_altitude_km),
            max_altitude_km: metric_stats(rows, :max_altitude_km),
            perigee_altitude_km: metric_stats(rows, :perigee_altitude_km),
            apogee_altitude_km: metric_stats(rows, :apogee_altitude_km),
            eccentricity: metric_stats(rows, :eccentricity),
            access_duration_s: metric_stats(rows, :access_duration_s),
            eclipse_duration_s: metric_stats(rows, :eclipse_duration_s),
            total_delta_v_km_s: metric_stats(rows, :total_delta_v_km_s)
          },
          constraints: monte_carlo_constraint_summary(artifact, rows)
        }

      _metadata ->
        nil
    end
  end

  defp metric_stats(rows, metric) do
    values =
      rows
      |> Enum.map(&Map.get(&1, metric))
      |> Enum.filter(&is_number/1)

    case values do
      [] ->
        %{count: 0, min: nil, mean: nil, max: nil}

      values ->
        %{
          count: length(values),
          min: Enum.min(values),
          mean: Enum.sum(values) / length(values),
          max: Enum.max(values)
        }
    end
  end

  defp monte_carlo_constraint_summary(artifact, metric_rows) do
    constraint_rows = Map.get(artifact, "constraint_results", [])

    if constraint_rows == [] do
      %{count: 0, passed_scenarios: nil, failed_scenarios: [], pass_probability: nil}
    else
      scenario_ids = Enum.map(metric_rows, & &1.scenario_id)

      failed_scenarios =
        constraint_rows
        |> Enum.filter(&(Map.get(&1, "status") == "fail"))
        |> Enum.map(&Map.get(&1, "scenario_id"))
        |> Enum.reject(&is_nil/1)
        |> MapSet.new()

      passed_count =
        Enum.count(scenario_ids, fn scenario_id ->
          not MapSet.member?(failed_scenarios, scenario_id)
        end)

      sample_count = length(scenario_ids)

      %{
        count: length(constraint_rows),
        passed_scenarios: passed_count,
        failed_scenarios: failed_scenarios |> MapSet.to_list() |> Enum.sort(),
        pass_probability: pass_probability(passed_count, sample_count)
      }
    end
  end

  defp pass_probability(_passed_count, 0), do: nil
  defp pass_probability(passed_count, sample_count), do: passed_count / sample_count

  defp constraint_summary([]) do
    %{
      count: 0,
      pass: 0,
      fail: 0,
      warning: 0,
      failing_scenarios: []
    }
  end

  defp constraint_summary(rows) do
    statuses = Enum.map(rows, &Map.get(&1, "status"))

    %{
      count: length(rows),
      pass: Enum.count(statuses, &(&1 == "pass")),
      fail: Enum.count(statuses, &(&1 == "fail")),
      warning: Enum.count(statuses, &(&1 == "warning")),
      failing_scenarios:
        rows
        |> Enum.filter(&(Map.get(&1, "status") == "fail"))
        |> Enum.map(&Map.get(&1, "scenario_id"))
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> Enum.sort()
    }
  end

  defp best_feasible_ranking(%{"scenario_rankings" => %{"rows" => ranking_rows}} = artifact)
       when is_list(ranking_rows) do
    failed_scenarios =
      artifact
      |> Map.get("constraint_results", [])
      |> Enum.filter(&(Map.get(&1, "status") == "fail"))
      |> Enum.map(&Map.get(&1, "scenario_id"))
      |> MapSet.new()

    Enum.find(ranking_rows, fn row ->
      not MapSet.member?(failed_scenarios, Map.get(row, "scenario_id"))
    end)
  end

  defp best_feasible_ranking(_artifact), do: nil

  defp ranking_comparison_report(
         %{scenario_rankings: %{"rows" => left_rows} = left_ranking},
         %{scenario_rankings: %{"rows" => right_rows} = right_ranking}
       )
       when is_list(left_rows) and is_list(right_rows) do
    left_objective = Map.get(left_ranking, "objective")
    right_objective = Map.get(right_ranking, "objective")
    left_direction = Map.get(left_ranking, "objective_direction")
    right_direction = Map.get(right_ranking, "objective_direction")

    if comparable_rankings?(left_objective, right_objective, left_direction, right_direction) do
      Optimizer.ranking_comparison_report(left_rows, right_rows,
        source: "result_set.compare.scenario_rankings",
        objective: left_objective,
        objective_direction: left_direction,
        left_label: "left_artifact",
        right_label: "right_artifact"
      )
    end
  end

  defp ranking_comparison_report(_left_summary, _right_summary), do: nil

  defp comparable_rankings?(objective, objective, direction, direction)
       when is_binary(objective) and is_binary(direction),
       do: true

  defp comparable_rankings?(_left_objective, _right_objective, _left_direction, _right_direction),
    do: false

  defp outputs(%{"outputs" => outputs}) when is_list(outputs), do: Enum.sort(outputs)
  defp outputs(_assumptions), do: []

  defp compare_lists(left, right) do
    %{
      same: left == right,
      left: left,
      right: right,
      only_left: Enum.sort(left -- right),
      only_right: Enum.sort(right -- left)
    }
  end

  defp access_window_rows(artifact) do
    artifact
    |> Map.get("access_windows", [])
    |> Enum.group_by(&{&1["scenario_id"], &1["ground_station_id"]})
    |> Enum.flat_map(fn {{scenario_id, ground_station_id}, rows} ->
      rows
      |> Enum.sort_by(&event_sort_key/1)
      |> Enum.with_index(1)
      |> Enum.map(fn {row, index} ->
        {%{
           event_type: "access_window",
           scenario_id: scenario_id,
           ground_station_id: ground_station_id,
           ordinal: index
         }, row}
      end)
    end)
  end

  defp eclipse_interval_rows(artifact) do
    artifact
    |> Map.get("eclipse_intervals", [])
    |> Enum.group_by(& &1["scenario_id"])
    |> Enum.flat_map(fn {scenario_id, rows} ->
      rows
      |> Enum.sort_by(&event_sort_key/1)
      |> Enum.with_index(1)
      |> Enum.map(fn {row, index} ->
        {%{
           event_type: "eclipse_interval",
           scenario_id: scenario_id,
           ordinal: index
         }, row}
      end)
    end)
  end

  defp boundary_deltas(left_rows, right_rows) do
    left_by_key = Map.new(left_rows)
    right_by_key = Map.new(right_rows)

    left_keys = Map.keys(left_by_key)
    right_keys = Map.keys(right_by_key)
    matched_keys = Enum.sort(left_keys -- (left_keys -- right_keys))

    %{
      matched_count: length(matched_keys),
      missing_left: Enum.sort(right_keys -- left_keys),
      missing_right: Enum.sort(left_keys -- right_keys),
      rows:
        Enum.map(matched_keys, fn key ->
          left = Map.fetch!(left_by_key, key)
          right = Map.fetch!(right_by_key, key)

          %{
            key: key,
            starts_at_delta_s: delta(right["starts_at_s"], left["starts_at_s"]),
            ends_at_delta_s: delta(right["ends_at_s"], left["ends_at_s"])
          }
        end)
    }
  end

  defp event_sort_key(row) do
    case numeric_value(row["starts_at_s"]) do
      number when is_number(number) -> {0, number}
      nil -> {1, inspect(row["starts_at_s"])}
    end
  end

  defp delta(right, left) do
    right = numeric_value(right)
    left = numeric_value(left)

    if is_number(right) and is_number(left) do
      (right - left) * 1.0
    end
  end

  defp integer_count(value) do
    case numeric_value(value) do
      number when is_number(number) and number >= 0 and trunc(number) == number -> trunc(number)
      _value -> 0
    end
  end

  defp numeric_value(value) when is_number(value), do: value

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_value(_value), do: nil
end
