defmodule OrbitalDynamics.Constraints.CampaignLocal do
  @moduledoc """
  Deterministic campaign planner constraint rows for planning artifacts.

  This is a reusable report builder around the V1/V2 campaign constraint map.
  It keeps the planner-specific threshold language visible as
  `constraint_report.v1` rows without claiming to be a general constraint
  solver.
  """

  @behaviour OrbitalDynamics.Constraint

  @model_limits [
    "planner_local_constraints_only",
    "evaluated_after_candidate_generation_filters",
    "resource_projection_constraints_are_planning_grade",
    "link_capacity_constraints_are_fixed_rate_summaries",
    "not_a_general_constraint_solver"
  ]

  @supported_constraints [
    "max_timeline_activities",
    "min_activity_duration_s",
    "avoid_eclipse",
    "min_projected_storage_margin",
    "min_projected_downlink_margin",
    "min_projected_power_margin",
    "min_selected_capacity_utilization_fraction",
    "max_selected_downlink_shortfall_mb",
    "min_actual_completion_fraction"
  ]

  @doc """
  Declares the campaign-local constraint model and known limits.
  """
  @impl OrbitalDynamics.Constraint
  def capabilities do
    %{
      constraint: :campaign_local,
      model: :campaign_planner_local_constraint_summary,
      validation_level: :artifact_contract,
      supported_constraints: @supported_constraints,
      outputs: [
        :constraint_rows,
        :constraint_report
      ],
      known_limits: Enum.map(@model_limits, &String.to_atom/1)
    }
  end

  @doc """
  Evaluates campaign-local constraints from a planning input map.
  """
  @impl OrbitalDynamics.Constraint
  def evaluate(%{} = input, opts) when is_list(opts) do
    report_opts = Keyword.take(opts, [:model, :source, :constraint_model])

    report =
      report(
        Map.get(input, :candidates, Map.get(input, "candidates", [])),
        Map.get(input, :timelines, Map.get(input, "timelines", [])),
        Map.get(input, :constraints, Map.get(input, "constraints", %{})),
        Map.get(input, :resource_projection_report, Map.get(input, "resource_projection_report")),
        Map.get(input, :link_capacity_report, Map.get(input, "link_capacity_report")),
        report_opts
      )

    {:ok,
     %{
       status: String.to_atom(report["status"]),
       metadata: %{"rows" => report["rows"], "report" => report}
     }}
  end

  def evaluate(_input, _opts), do: {:error, {:invalid_field, "campaign_constraint_input"}}

  @doc """
  Builds a deterministic `constraint_report.v1` for campaign-local constraints.
  """
  def report(
        candidates,
        timelines,
        constraints,
        resource_projection_report,
        link_capacity_report,
        opts \\ []
      ) do
    constraints = stringify_keys(constraints || %{})
    candidates = normalize_input_rows(candidates)
    timelines = normalize_input_rows(timelines)
    resource_projection_report = normalize_input_map(resource_projection_report)
    link_capacity_report = normalize_input_map(link_capacity_report)

    rows =
      max_timeline_activity_constraint_rows(timelines, constraints) ++
        min_activity_duration_constraint_rows(candidates, constraints) ++
        avoid_eclipse_constraint_rows(candidates, constraints) ++
        resource_projection_constraint_rows(resource_projection_report, constraints) ++
        link_capacity_constraint_rows(link_capacity_report, constraints)

    %{
      "schema_contract" => "constraint_report.v1",
      "model" => Keyword.get(opts, :model, "campaign_planner_local_constraint_summary"),
      "constraint_count" => constraint_count(constraints),
      "row_count" => length(rows),
      "status" => report_status(rows),
      "status_counts" => status_counts(rows),
      "model_limits" => @model_limits,
      "rows" => rows,
      "assumptions" => %{
        "source" => Keyword.get(opts, :source, "campaign_plan.assumptions.constraints"),
        "constraint_model" =>
          Keyword.get(opts, :constraint_model, "campaign_v1_planner_local_constraints"),
        "missing_or_nil_values" => "not_evaluated"
      }
    }
  end

  defp max_timeline_activity_constraint_rows(timelines, constraints) when is_list(timelines) do
    max = constraint_value(constraints, "max_timeline_activities")

    if is_number(max) do
      severity = constraint_violation_severity(constraints, "max_timeline_activities")

      Enum.map(timelines, fn timeline ->
        value = metric_number(timeline, "activity_count", 0)

        %{
          "constraint_id" => "campaign:max_timeline_activities",
          "scenario_id" => Map.get(timeline, "scenario_id"),
          "metric" => "activity_count",
          "operator" => "<=",
          "threshold" => max,
          "violation_severity" => severity,
          "value" => value,
          "score" => max - value,
          "status" => constraint_status(value <= max, severity)
        }
      end)
    else
      []
    end
  end

  defp max_timeline_activity_constraint_rows(_timelines, _constraints), do: []

  defp min_activity_duration_constraint_rows(candidates, constraints) when is_list(candidates) do
    min_duration = constraint_value(constraints, "min_activity_duration_s")

    if is_number(min_duration) do
      severity = constraint_violation_severity(constraints, "min_activity_duration_s")

      Enum.map(candidates, fn candidate ->
        value = metric_number(candidate, "duration_s", 0.0)

        %{
          "constraint_id" => "campaign:min_activity_duration_s",
          "scenario_id" => Map.get(candidate, "scenario_id"),
          "metric" => "duration_s",
          "operator" => ">=",
          "threshold" => min_duration,
          "violation_severity" => severity,
          "value" => value,
          "score" => value - min_duration,
          "status" => constraint_status(value >= min_duration, severity),
          "activity_id" => activity_id(candidate)
        }
      end)
    else
      []
    end
  end

  defp min_activity_duration_constraint_rows(_candidates, _constraints), do: []

  defp avoid_eclipse_constraint_rows(candidates, constraints) when is_list(candidates) do
    if constraint_enabled?(constraints, "avoid_eclipse") do
      severity = constraint_violation_severity(constraints, "avoid_eclipse")

      candidates
      |> Enum.filter(&(metric_number(&1, "eclipse_overlap_s") != nil))
      |> Enum.map(fn candidate ->
        value = metric_number(candidate, "eclipse_overlap_s", 0.0)

        %{
          "constraint_id" => "campaign:avoid_eclipse",
          "scenario_id" => Map.get(candidate, "scenario_id"),
          "metric" => "eclipse_overlap_s",
          "operator" => "==",
          "threshold" => 0.0,
          "violation_severity" => severity,
          "value" => value,
          "score" => -value,
          "status" => constraint_status(value == 0.0, severity),
          "activity_id" => activity_id(candidate)
        }
      end)
    else
      []
    end
  end

  defp avoid_eclipse_constraint_rows(_candidates, _constraints), do: []

  defp resource_projection_constraint_rows(nil, _constraints), do: []

  defp resource_projection_constraint_rows(%{} = resource_projection_report, constraints) do
    rows = Map.get(resource_projection_report, "projected_resources", [])

    [
      {"min_projected_storage_margin", "projected_storage_margin"},
      {"min_projected_downlink_margin", "projected_downlink_margin"},
      {"min_projected_power_margin", "projected_power_margin"}
    ]
    |> Enum.flat_map(fn {constraint_key, metric} ->
      min_margin = constraint_value(constraints, constraint_key)

      if is_number(min_margin) do
        severity = constraint_violation_severity(constraints, constraint_key)

        rows
        |> Enum.filter(&(metric_number(&1, metric) |> is_number()))
        |> Enum.map(fn row ->
          value = metric_number(row, metric)

          %{
            "constraint_id" => "campaign:#{constraint_key}",
            "scenario_id" => resource_projection_constraint_scenario_id(row),
            "spacecraft_id" => Map.get(row, "spacecraft_id"),
            "metric" => metric,
            "operator" => ">=",
            "threshold" => min_margin,
            "violation_severity" => severity,
            "value" => value,
            "score" => value - min_margin,
            "status" => constraint_status(value >= min_margin, severity),
            "activity_id" => Map.get(row, "first_resource_pressure_activity_id"),
            "resource_pressure_status" => Map.get(row, "resource_pressure_status"),
            "resource_pressure_types" => Map.get(row, "resource_pressure_types")
          }
          |> compact_map()
        end)
      else
        []
      end
    end)
  end

  defp resource_projection_constraint_rows(_resource_projection_report, _constraints), do: []

  defp link_capacity_constraint_rows(nil, _constraints), do: []

  defp link_capacity_constraint_rows(%{} = link_capacity_report, constraints) do
    rows = [link_capacity_report]

    [
      {"min_selected_capacity_utilization_fraction", "selected_capacity_utilization_fraction",
       ">="},
      {"max_selected_downlink_shortfall_mb", "selected_downlink_shortfall_mb", "<="},
      {"min_actual_completion_fraction", "actual_completion_fraction", ">="}
    ]
    |> Enum.flat_map(fn {constraint_key, metric, operator} ->
      threshold = constraint_value(constraints, constraint_key)

      if is_number(threshold) do
        severity = constraint_violation_severity(constraints, constraint_key)

        rows
        |> Enum.filter(&(metric_number(&1, metric) |> is_number()))
        |> Enum.map(fn row ->
          value = metric_number(row, metric)
          pass? = link_capacity_constraint_pass?(value, operator, threshold)

          %{
            "constraint_id" => "campaign:#{constraint_key}",
            "scenario_id" => link_capacity_constraint_scenario_id(row),
            "ground_station_id" => Map.get(row, "ground_station_id"),
            "metric" => metric,
            "operator" => operator,
            "threshold" => threshold,
            "violation_severity" => severity,
            "value" => value,
            "score" => link_capacity_constraint_score(value, operator, threshold),
            "status" => constraint_status(pass?, severity),
            "selection_utilization_status" => Map.get(row, "selection_utilization_status"),
            "downlink_requirement_status" => Map.get(row, "downlink_requirement_status"),
            "actual_downlink_requirement_status" =>
              Map.get(row, "actual_downlink_requirement_status")
          }
          |> compact_map()
        end)
      else
        []
      end
    end)
  end

  defp link_capacity_constraint_rows(_link_capacity_report, _constraints), do: []

  defp resource_projection_constraint_scenario_id(%{"scenario_id" => scenario_id})
       when is_binary(scenario_id) and scenario_id != "",
       do: scenario_id

  defp resource_projection_constraint_scenario_id(%{"spacecraft_id" => spacecraft_id})
       when is_binary(spacecraft_id) and spacecraft_id != "",
       do: spacecraft_id

  defp resource_projection_constraint_scenario_id(_row), do: "resource_projection"

  defp link_capacity_constraint_scenario_id(%{"ground_station_id" => ground_station_id})
       when is_binary(ground_station_id) and ground_station_id != "",
       do: "link_capacity:#{ground_station_id}"

  defp link_capacity_constraint_scenario_id(_row), do: "link_capacity"

  defp link_capacity_constraint_pass?(value, ">=", threshold), do: value >= threshold
  defp link_capacity_constraint_pass?(value, "<=", threshold), do: value <= threshold

  defp link_capacity_constraint_score(value, ">=", threshold), do: value - threshold
  defp link_capacity_constraint_score(value, "<=", threshold), do: threshold - value

  defp constraint_value(constraints, key) do
    value =
      case Map.get(constraints, key) do
        %{"value" => value} -> value
        %{"threshold" => threshold} -> threshold
        value -> value
      end

    case numeric_value(value) do
      number when is_number(number) -> number
      _value -> value
    end
  end

  defp numeric_value(value) when is_integer(value) or is_float(value), do: value

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _other -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp raw_constraint_value(constraints, key) do
    case Map.get(constraints, key) do
      %{"value" => value} -> value
      %{"threshold" => threshold} -> threshold
      value -> value
    end
  end

  defp metric_number(row, key, default \\ nil) do
    case numeric_value(Map.get(row, key)) do
      number when is_number(number) -> number
      _value -> default
    end
  end

  defp constraint_enabled?(constraints, key) do
    case raw_constraint_value(constraints, key) do
      true ->
        true

      _value ->
        case Map.get(constraints, key) do
          %{"enabled" => true} -> true
          _value -> false
        end
    end
  end

  defp constraint_violation_severity(constraints, key) do
    severity =
      case Map.get(constraints, key) do
        %{"severity" => value} -> value
        %{"violation_severity" => value} -> value
        _value -> Map.get(constraints, "#{key}_severity", "fail")
      end

    if severity == "warning", do: "warning", else: "fail"
  end

  defp constraint_count(constraints) do
    [
      is_number(constraint_value(constraints, "max_timeline_activities")),
      is_number(constraint_value(constraints, "min_activity_duration_s")),
      constraint_enabled?(constraints, "avoid_eclipse"),
      is_number(constraint_value(constraints, "min_projected_storage_margin")),
      is_number(constraint_value(constraints, "min_projected_downlink_margin")),
      is_number(constraint_value(constraints, "min_projected_power_margin")),
      is_number(constraint_value(constraints, "min_selected_capacity_utilization_fraction")),
      is_number(constraint_value(constraints, "max_selected_downlink_shortfall_mb")),
      is_number(constraint_value(constraints, "min_actual_completion_fraction"))
    ]
    |> Enum.count(& &1)
  end

  defp report_status(rows) do
    cond do
      Enum.any?(rows, &(&1["status"] == "fail")) -> "fail"
      Enum.any?(rows, &(&1["status"] == "warning")) -> "warning"
      true -> "pass"
    end
  end

  defp status_counts(rows) do
    rows
    |> Enum.map(&Map.get(&1, "status", "warning"))
    |> Enum.frequencies()
    |> Map.put_new("pass", 0)
    |> Map.put_new("fail", 0)
    |> Map.put_new("warning", 0)
  end

  defp constraint_status(true, _severity), do: "pass"
  defp constraint_status(false, "warning"), do: "warning"
  defp constraint_status(false, _severity), do: "fail"

  defp activity_id(activity), do: encode_value(Map.fetch!(activity, "id"))

  defp normalize_input_rows(rows) when is_list(rows), do: Enum.map(rows, &normalize_input_map/1)
  defp normalize_input_rows(rows), do: rows

  defp normalize_input_map(nil), do: nil
  defp normalize_input_map(%{} = map), do: stringify_keys(map)
  defp normalize_input_map(value), do: value

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
