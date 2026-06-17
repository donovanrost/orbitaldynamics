defmodule OrbitalDynamics.CampaignPlanner.CandidateSourceOperationalReadinessReplayRisk do
  @moduledoc false

  def operational_readiness(%{} = replay_summary) do
    if operational_readiness_scoring_pressure?(replay_summary) do
      operational_readiness_pressure_risk(replay_summary)
    else
      []
    end
  end

  def operational_readiness(_replay_summary), do: []

  defp operational_readiness_scoring_pressure?(replay_summary) do
    Map.get(replay_summary, "branch_local_review_pressure") == true or
      Map.get(replay_summary, "branch_local_import_pressure") == true or
      Map.get(replay_summary, "branch_local_execution_boundary_pressure") == true or
      summary_positive?(replay_summary, "review_gate_count") or
      summary_positive?(replay_summary, "blocked_gate_count") or
      summary_positive?(replay_summary, "non_passed_gate_count")
  end

  defp operational_readiness_pressure_risk(replay_summary) do
    readiness_levels = replay_summary |> Map.get("readiness_level_counts", %{}) |> map_keys()

    import_classifications =
      replay_summary |> Map.get("import_classification_counts", %{}) |> map_keys()

    readiness_statuses = replay_summary |> Map.get("status_counts", %{}) |> map_keys()

    gate_statuses = replay_summary |> Map.get("gate_status_counts", %{}) |> map_keys()

    gate_classifications =
      replay_summary |> Map.get("gate_classification_counts", %{}) |> map_keys()

    [
      %{
        "type" => "operational_readiness_pressure",
        "severity" =>
          readiness_pressure_risk_severity(%{
            "readiness_level" => pressure_priority_value(readiness_levels),
            "import_classification" => pressure_priority_value(import_classifications),
            "operational_readiness_status" => pressure_priority_value(readiness_statuses)
          }),
        "reason" =>
          "candidate source operational-readiness replay reports review, blocked, analysis-only, or import-boundary pressure",
        "readiness_level" => pressure_priority_value(readiness_levels),
        "import_classification" => pressure_priority_value(import_classifications),
        "operational_readiness_status" => pressure_priority_value(readiness_statuses),
        "readiness_levels" => readiness_levels,
        "import_classifications" => import_classifications,
        "operational_readiness_statuses" => readiness_statuses,
        "source_report_paths" => Map.get(replay_summary, "source_report_paths"),
        "gate_count" => Map.get(replay_summary, "gate_count"),
        "passed_gate_count" => Map.get(replay_summary, "passed_gate_count"),
        "review_gate_count" => Map.get(replay_summary, "review_gate_count"),
        "analysis_gate_count" => Map.get(replay_summary, "analysis_gate_count"),
        "blocked_gate_count" => Map.get(replay_summary, "blocked_gate_count"),
        "non_passed_gate_count" => Map.get(replay_summary, "non_passed_gate_count"),
        "gate_status_counts" => Map.get(replay_summary, "gate_status_counts"),
        "gate_classification_counts" => Map.get(replay_summary, "gate_classification_counts"),
        "gate_statuses" => gate_statuses,
        "gate_classifications" => gate_classifications,
        "review_required_gate_ids" => Map.get(replay_summary, "review_required_gate_ids"),
        "analysis_only_gate_ids" => Map.get(replay_summary, "analysis_only_gate_ids"),
        "blocked_gate_ids" => Map.get(replay_summary, "blocked_gate_ids"),
        "non_passed_gate_ids" => Map.get(replay_summary, "non_passed_gate_ids"),
        "branch_local_review_pressure" => Map.get(replay_summary, "branch_local_review_pressure"),
        "branch_local_import_pressure" => Map.get(replay_summary, "branch_local_import_pressure"),
        "branch_local_execution_boundary_pressure" =>
          Map.get(replay_summary, "branch_local_execution_boundary_pressure"),
        "feedback_source" => "candidate_source.operational_readiness_replay_summary",
        "feedback_scope" => "operational_readiness",
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries")
      }
      |> compact_map()
    ]
  end

  defp readiness_pressure_risk_severity(event) do
    blocked_values = ["blocked", "blocked_by_policy", "review_blocked_operational_readiness"]

    if Enum.any?(
         [
           event["readiness_level"],
           event["import_classification"],
           event["operational_readiness_status"],
           event["readiness_gate_status"],
           event["readiness_gate_classification"],
           event["quality_gate_status"],
           event["gate_status"],
           event["gate_classification"],
           event["required_operator_action"]
         ],
         &(&1 in blocked_values)
       ) do
      "high"
    else
      "medium"
    end
  end

  defp pressure_priority_value(values) do
    priority = [
      "blocked",
      "blocked_by_policy",
      "review_blocked_operational_readiness",
      "review_required",
      "review_only",
      "operator_review",
      "analysis_only"
    ]

    Enum.find(priority, &(&1 in values)) || List.first(values)
  end

  defp summary_positive?(summary, field) do
    case numeric_or_nil(Map.get(summary, field)) do
      value when is_number(value) -> value > 0
      _value -> false
    end
  end

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {parsed, ""} -> parsed
      _parsed -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp map_keys(%{} = map), do: map |> Map.keys() |> sorted_encoded_values()
  defp map_keys(_map), do: []

  defp sorted_encoded_values(values) do
    values
    |> List.wrap()
    |> List.flatten()
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

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
