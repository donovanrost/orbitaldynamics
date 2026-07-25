defmodule OrbitalDynamics.OperatorReview.CommandWindow do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def package(report) do
    {rows, source_artifact_id, provenance} = package_input(report)

    build_package(rows, "command_window_report.v1", source_artifact_id, provenance)
  end

  def candidate_refresh_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_command_window_report",
         artifact["source_command_window_report"]},
        {"candidate_refresh.command_window_report", artifact["command_window_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_rows(artifact)
  end

  def package_input(report) do
    report = stringify_keys(report || %{})

    {
      rows(Map.get(report, "rows", [])),
      Map.get(report, "id") || Map.get(report, "source") || "command_window_report",
      Map.get(report, "provenance", %{})
    }
  end

  def source_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_report_rows(report, "#{source}[#{index}]")
    end)
  end

  def source_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> Map.get("rows", [])
    |> rows("#{source}.rows")
  end

  def source_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_rows(
         %{"schema_contract" => "command_window_report.v1"} = report,
         source
       ) do
    source_report_rows(report, source)
  end

  defp result_artifact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_command_window_report", artifact["source_command_window_report"]},
      {"#{source}.command_window_report", artifact["command_window_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_rows(_artifact, _source), do: []

  def rows(rows, source \\ "command_window_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.reject(&(&1["required_operator_action"] in no_command_window_review_actions()))
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      requirement = row["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = row["approval_rule_matches"] |> first_map() |> stringify_keys()
      policy_decision = stringify_keys(row["policy_decision"] || %{})
      policy_escalation = row |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["command_window", row["activity_id"], index]),
        "review_type" => "command_window_review",
        "source" => source,
        "subject_id" => row["activity_id"],
        "activity_id" => row["activity_id"],
        "timeline_id" => row["timeline_id"],
        "scenario_id" => row["scenario_id"],
        "activity_type" => row["activity_type"],
        "window_type" => row["window_type"],
        "direction" => row["direction"],
        "ground_station_id" => row["ground_station_id"],
        "starts_at_s" => row["starts_at_s"],
        "ends_at_s" => row["ends_at_s"],
        "status" => row["status"],
        "approval_status" => operational_timeline_approval_status(row),
        "source_approval_status" => row["approval_status"],
        "locked" => row["locked"],
        "contact_success" => row["contact_success"],
        "command_success" => row["command_success"],
        "contact_result" => provider_result_artifact_value(row["contact_result"]),
        "command_result" => provider_result_artifact_value(row["command_result"]),
        "command_success_factor" => row["command_success_factor"],
        "command_success_factor_source" => row["command_success_factor_source"],
        "station_availability" => row["station_availability"],
        "capacity_fraction" => row["capacity_fraction"],
        "station_contention_status" => row["station_contention_status"],
        "station_calendar_entry_id" => row["station_calendar_entry_id"],
        "station_calendar_provider_id" => row["station_calendar_provider_id"],
        "station_calendar_provider_entry_id" => row["station_calendar_provider_entry_id"],
        "station_calendar_directions" => row["station_calendar_directions"],
        "station_calendar_status" => row["station_calendar_status"],
        "station_calendar_trust_boundary_status" => row["station_calendar_trust_boundary_status"],
        "trust_boundary" => row["trust_boundary"],
        "provenance" => row["provenance"],
        "source_station_calendar_entry" => row["source_station_calendar_entry"],
        "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
        "station_calendar_reservation_overlap_count" =>
          row["station_calendar_reservation_overlap_count"],
        "station_calendar_reservation_ids" => row["station_calendar_reservation_ids"],
        "station_calendar_reserved_by" => row["station_calendar_reserved_by"],
        "station_calendar_reservation_statuses" => row["station_calendar_reservation_statuses"],
        "station_calendar_reservation_expires_at_s" =>
          row["station_calendar_reservation_expires_at_s"],
        "station_reservation_id" => row["station_reservation_id"],
        "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
        "station_reserved_by" => row["station_reserved_by"],
        "station_reservation_status" => row["station_reservation_status"],
        "station_reservation_match_status" => row["station_reservation_match_status"],
        "action" => row["required_operator_action"],
        "required_operator_action" => row["required_operator_action"],
        "reason" => row["operator_action_reason"] || "command window requires operator review",
        "operator_action_reason" => row["operator_action_reason"],
        "superseded_required_operator_action" => row["superseded_required_operator_action"],
        "superseded_operator_action_reason" => row["superseded_operator_action_reason"],
        "timeline_integrity_status" => row["timeline_integrity_status"],
        "timeline_integrity_issue_count" => row["timeline_integrity_issue_count"],
        "timeline_integrity_issue_types" => row["timeline_integrity_issue_types"],
        "timeline_integrity_issues" => row["timeline_integrity_issues"],
        "missing_dependency_activity_ids" => row["missing_dependency_activity_ids"],
        "missing_dependency_timeline_ids" => row["missing_dependency_timeline_ids"],
        "self_dependency_activity_ids" => row["self_dependency_activity_ids"],
        "self_dependency_timeline_ids" => row["self_dependency_timeline_ids"],
        "dependency_cycle_activity_ids" => row["dependency_cycle_activity_ids"],
        "dependency_cycle_timeline_ids" => row["dependency_cycle_timeline_ids"],
        "dependency_order_violation_activity_ids" =>
          row["dependency_order_violation_activity_ids"],
        "dependency_order_violation_timeline_ids" =>
          row["dependency_order_violation_timeline_ids"],
        "exclusivity_violation_activity_ids" => row["exclusivity_violation_activity_ids"],
        "exclusivity_violation_timeline_ids" => row["exclusivity_violation_timeline_ids"],
        "exclusivity_violation_group" => row["exclusivity_violation_group"],
        "execution_boundary" => row["execution_boundary"],
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || rule_match["required_authority"] ||
            policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => row["approval_requirements"],
        "approval_rule_matches" => row["approval_rule_matches"],
        "source_policy_decision" => row["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "cadence_import_status" => row["cadence_import_status"],
        "cadence_import_type" => row["cadence_import_type"],
        "dependency_activity_ids" => row["dependency_activity_ids"],
        "dependency_timeline_ids" => row["dependency_timeline_ids"],
        "exclusive_with_activity_ids" => row["exclusive_with_activity_ids"],
        "exclusive_with_timeline_ids" => row["exclusive_with_timeline_ids"],
        "source_window_id" => row["source_window_id"],
        "source_window_type" => row["source_window_type"],
        "has_source_window" => row["has_source_window"],
        "has_cadence_import" => row["has_cadence_import"],
        "timeline_identity" => row["timeline_identity"],
        "invalid_activity_input" => row["invalid_activity_input"],
        "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
        "source_activity" => row["source_activity"],
        "source_activity_context" =>
          normalize_provider_result_artifact_fields(row["activity_context"]),
        "source_command_window" => row
      }
      |> compact_map()
    end)
  end

  defp no_command_window_review_actions do
    ["monitor_activity", "none_locked_activity", "none_terminal_activity"]
  end

  defp operational_timeline_approval_status(%{"required_operator_action" => action})
       when action in [
              "review_command_contact",
              "review_activity_approval",
              "resolve_rejected_activity",
              "resolve_contact_conflict",
              "review_terminal_activity_exception"
            ],
       do: "operator_review_required"

  defp operational_timeline_approval_status(row),
    do: Map.get(row, "approval_status", "operator_review_required")

  defp normalize_provider_result_artifact_fields(%{} = map) do
    Enum.reduce(provider_result_fields(), map, fn field, acc ->
      case Map.fetch(acc, field) do
        {:ok, value} ->
          case provider_result_artifact_value(value) do
            nil -> Map.delete(acc, field)
            normalized -> Map.put(acc, field, normalized)
          end

        :error ->
          acc
      end
    end)
  end

  defp normalize_provider_result_artifact_fields(value), do: value

  defp provider_result_fields,
    do: ~w(contact_result command_result observation_result maneuver_result)

  defp matched_policy_escalation(row) do
    preferred_rule_id =
      row
      |> preferred_approval_rule_match()
      |> Map.get("rule_id")

    rule_ids =
      row
      |> Map.get("approval_rule_matches", [])
      |> List.wrap()
      |> Enum.map(&Map.get(&1, "rule_id"))
      |> Enum.reject(&is_nil/1)

    escalations =
      row
      |> get_in(["policy_decision", "escalations"])
      |> List.wrap()
      |> Enum.filter(&is_map/1)

    escalation =
      Enum.find(escalations, &(Map.get(&1, "rule_id") == preferred_rule_id)) ||
        Enum.find(escalations, &(Map.get(&1, "rule_id") in rule_ids)) ||
        List.first(escalations) ||
        row
        |> Map.get("approval_rule_matches", [])
        |> List.wrap()
        |> Enum.find(&policy_escalation_context?/1)

    escalation || %{}
  end

  defp preferred_approval_rule_match(%{} = row) do
    preferred_classification =
      row["approval_status"] || get_in(row, ["policy_decision", "classification"])

    preferred_approval_rule_match(row["approval_rule_matches"], preferred_classification)
  end

  defp preferred_approval_rule_match(rule_matches, preferred_classification)
       when is_list(rule_matches) do
    rule_matches =
      rule_matches
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)

    Enum.find(rule_matches, &(&1["classification"] == preferred_classification)) ||
      List.first(rule_matches) ||
      %{}
  end

  defp preferred_approval_rule_match(_rule_matches, _preferred_classification), do: %{}

  defp policy_escalation_context?(%{} = row) do
    Enum.any?(
      ["escalation_level", "escalation_queue", "escalation_role", "required_authority", "sla_s"],
      &Map.has_key?(row, &1)
    )
  end

  defp policy_escalation_context?(_row), do: false

  defp provider_result_values(result) when is_binary(result) do
    result
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp provider_result_values(values) when is_list(values) do
    Enum.flat_map(values, &provider_result_values/1)
  end

  defp provider_result_values(%{} = result) do
    Enum.flat_map(provider_result_map_value_keys(), fn key ->
      result
      |> Map.get(key)
      |> provider_result_values()
    end)
  end

  defp provider_result_values(nil), do: []

  defp provider_result_values(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> provider_result_values()
  end

  defp provider_result_values(result)
       when is_integer(result) or is_float(result) or is_boolean(result) do
    result
    |> to_string()
    |> provider_result_values()
  end

  defp provider_result_values(_result), do: []

  defp provider_result_artifact_value(nil), do: nil

  defp provider_result_artifact_value(result) when is_binary(result) do
    case String.trim(result) do
      "" -> nil
      _value -> result
    end
  end

  defp provider_result_artifact_value(results) when is_list(results) do
    case provider_result_values(results) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp provider_result_artifact_value(%{} = result) do
    case provider_result_values(result) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp provider_result_artifact_value(result) when is_integer(result),
    do: Integer.to_string(result)

  defp provider_result_artifact_value(result) when is_float(result), do: Float.to_string(result)
  defp provider_result_artifact_value(result) when is_boolean(result), do: Atom.to_string(result)

  defp provider_result_artifact_value(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> provider_result_artifact_value()
  end

  defp provider_result_artifact_value(_result), do: nil

  defp provider_result_map_value_keys do
    ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)
  end

  defp first_map(values) when is_list(values), do: Enum.find(values, %{}, &is_map/1)
  defp first_map(_values), do: %{}

  defp non_empty_map(%{} = map) when map_size(map) > 0, do: map
  defp non_empty_map(_map), do: nil

  defp review_id(parts) do
    parts
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(nil), do: nil
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp build_package(rows, source_artifact_type, source_artifact_id, provenance) do
    PackageBuilder.build(
      rows,
      source_artifact_type,
      source_artifact_id,
      provenance,
      @schema_contract,
      Capabilities.model_limits()
    )
  end
end
