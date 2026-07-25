defmodule OrbitalDynamics.OperatorReview.StationCalendar do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @provider_result_map_value_keys ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)
  @schema_contract "operator_review_package.v1"

  def package(report) do
    {rows, source_artifact_id, provenance} = package_input(report)

    build_package(rows, "station_calendar_report.v1", source_artifact_id, provenance)
  end

  def package_input(report) do
    report = stringify_keys(report || %{})

    {
      report_rows(report),
      Map.get(report, "id") || get_in(report, ["assumptions", "source"]) ||
        "station_calendar_report",
      Map.get(report, "provenance", %{})
    }
  end

  def report_rows(report, source \\ "station_calendar_report") do
    report = stringify_keys(report)

    rows(Map.get(report, "affected_contacts", []), "#{source}.affected_contacts") ++
      provider_contention_rows(
        Map.get(report, "provider_calendar_contention_groups", []),
        "#{source}.provider_calendar_contention_groups"
      )
  end

  def rows(rows, source \\ "station_calendar_report.affected_contacts") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(&normalize_station_calendar_status_fields/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      action = row["required_operator_action"] || station_calendar_action(row)
      approval_status = row["approval_status"] || "operator_review_required"
      reason = row["operator_action_reason"] || station_calendar_reason(row)
      escalation = matched_policy_escalation(row)

      %{
        "id" =>
          review_id([
            "station_calendar",
            row["contact_id"],
            row["station_calendar_entry_id"],
            index
          ]),
        "review_type" => "station_calendar_review",
        "source" => source,
        "subject_id" => row["contact_id"],
        "contact_id" => row["contact_id"],
        "scenario_id" => row["scenario_id"],
        "activity_type" => row["contact_type"],
        "direction" => row["direction"],
        "ground_station_id" => row["ground_station_id"],
        "starts_at_s" => row["starts_at_s"],
        "ends_at_s" => row["ends_at_s"],
        "contact_success" => row["contact_success"],
        "contact_success_factor" => row["contact_success_factor"],
        "contact_success_factor_source" => row["contact_success_factor_source"],
        "command_success" => row["command_success"],
        "contact_result" => provider_result_artifact_value(row["contact_result"]),
        "command_result" => provider_result_artifact_value(row["command_result"]),
        "command_success_factor" => row["command_success_factor"],
        "command_success_factor_source" => row["command_success_factor_source"],
        "station_calendar_entry_id" => row["station_calendar_entry_id"],
        "station_calendar_provider_id" => row["station_calendar_provider_id"],
        "station_calendar_provider_entry_id" => row["station_calendar_provider_entry_id"],
        "station_calendar_directions" => row["station_calendar_directions"],
        "station_calendar_overlap_count" => row["station_calendar_overlap_count"],
        "station_calendar_overlap_entry_ids" => row["station_calendar_overlap_entry_ids"],
        "station_calendar_overlap_availabilities" =>
          row["station_calendar_overlap_availabilities"],
        "station_calendar_entry_ambiguous" => row["station_calendar_entry_ambiguous"],
        "station_calendar_ambiguous_entry_count" => row["station_calendar_ambiguous_entry_count"],
        "station_calendar_ambiguous_entry_ids" => row["station_calendar_ambiguous_entry_ids"],
        "station_calendar_reservation_overlap_count" =>
          row["station_calendar_reservation_overlap_count"],
        "station_calendar_reservation_ids" => row["station_calendar_reservation_ids"],
        "station_calendar_reserved_by" => row["station_calendar_reserved_by"],
        "station_calendar_reservation_statuses" => row["station_calendar_reservation_statuses"],
        "station_calendar_reservation_expires_at_s" =>
          row["station_calendar_reservation_expires_at_s"],
        "provider_counteroffer_id" => row["provider_counteroffer_id"],
        "provider_counteroffer_status" => row["provider_counteroffer_status"],
        "provider_counteroffer_negotiation_state" =>
          row["provider_counteroffer_negotiation_state"],
        "provider_counteroffer_reason_code" => row["provider_counteroffer_reason_code"],
        "provider_counteroffer_cost_delta" => row["provider_counteroffer_cost_delta"],
        "provider_counteroffer_lock_deadline_s" => row["provider_counteroffer_lock_deadline_s"],
        "provider_counteroffer_starts_at_s" => row["provider_counteroffer_starts_at_s"],
        "provider_counteroffer_ends_at_s" => row["provider_counteroffer_ends_at_s"],
        "provider_counteroffer_start_delta_s" =>
          row["provider_counteroffer_start_delta_s"] ||
            numeric_delta(row["provider_counteroffer_starts_at_s"], row["starts_at_s"]),
        "provider_counteroffer_end_delta_s" =>
          row["provider_counteroffer_end_delta_s"] ||
            numeric_delta(row["provider_counteroffer_ends_at_s"], row["ends_at_s"]),
        "provider_counteroffer_duration_delta_s" =>
          row["provider_counteroffer_duration_delta_s"] ||
            provider_counteroffer_duration_delta(row),
        "station_calendar_trust_boundary_status" => row["station_calendar_trust_boundary_status"],
        "trust_boundary" => row["trust_boundary"],
        "status" => row["status"],
        "station_availability" => row["station_availability"],
        "capacity_fraction" => row["capacity_fraction"],
        "station_contention_status" => row["station_contention_status"],
        "station_reservation_id" => row["station_reservation_id"],
        "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
        "station_reserved_by" => row["station_reserved_by"],
        "station_reservation_status" => row["station_reservation_status"],
        "station_reservation_match_status" => row["station_reservation_match_status"],
        "station_reservation_hold_import_status" => row["station_reservation_hold_import_status"],
        "station_reservation_hold_import_readiness_summary_model" =>
          row["station_reservation_hold_import_readiness_summary_model"],
        "station_reservation_hold_import_readiness_source" =>
          row["station_reservation_hold_import_readiness_source"],
        "station_reservation_hold_import_readiness_source_artifact_type" =>
          row["station_reservation_hold_import_readiness_source_artifact_type"],
        "station_reservation_hold_import_readiness_status" =>
          row["station_reservation_hold_import_readiness_status"],
        "station_reservation_hold_import_classification" =>
          row["station_reservation_hold_import_classification"],
        "station_reservation_hold_count" => row["station_reservation_hold_count"],
        "station_reservation_hold_ids" => row["station_reservation_hold_ids"],
        "station_reservation_hold_ids_by_import_status" =>
          row["station_reservation_hold_ids_by_import_status"],
        "station_reservation_hold_ids_by_required_import_action" =>
          row["station_reservation_hold_ids_by_required_import_action"],
        "station_reservation_hold_ids_by_direction" =>
          row["station_reservation_hold_ids_by_direction"],
        "station_reservation_hold_ids_by_direction_and_ground_station_id" =>
          row["station_reservation_hold_ids_by_direction_and_ground_station_id"],
        "station_reservation_hold_contact_ids_by_import_status" =>
          row["station_reservation_hold_contact_ids_by_import_status"],
        "station_reservation_hold_contact_ids_by_expiration_status" =>
          row["station_reservation_hold_contact_ids_by_expiration_status"],
        "station_reservation_hold_contact_ids_by_direction" =>
          row["station_reservation_hold_contact_ids_by_direction"],
        "station_reservation_hold_contact_ids_by_direction_and_ground_station_id" =>
          row["station_reservation_hold_contact_ids_by_direction_and_ground_station_id"],
        "station_reservation_hold_import_status_counts" =>
          row["station_reservation_hold_import_status_counts"],
        "station_reservation_hold_required_import_action_counts" =>
          row["station_reservation_hold_required_import_action_counts"],
        "station_reservation_hold_import_execution_boundary" =>
          row["station_reservation_hold_import_execution_boundary"],
        "station_reservation_hold_provider_write" =>
          row["station_reservation_hold_provider_write"],
        "station_reservation_hold_cadence_write" => row["station_reservation_hold_cadence_write"],
        "station_reservation_hold_reservation_acceptance" =>
          row["station_reservation_hold_reservation_acceptance"],
        "source_station_reservation_hold_import_readiness_summary" =>
          row["source_station_reservation_hold_import_readiness_summary"],
        "base_station_calendar_row_id" => row["base_station_calendar_row_id"],
        "duplicate_station_calendar_row_id_collision" =>
          row["duplicate_station_calendar_row_id_collision"],
        "duplicate_station_calendar_row_index" => row["duplicate_station_calendar_row_index"],
        "duplicate_station_calendar_row_count" => row["duplicate_station_calendar_row_count"],
        "invalid_feedback_confidence" => row["invalid_feedback_confidence"],
        "invalid_feedback_confidence_reason" => row["invalid_feedback_confidence_reason"],
        "source_contact_candidate" => row["source_contact_candidate"],
        "action" => action,
        "required_operator_action" => action,
        "approval_status" => approval_status,
        "reason" => reason,
        "operator_action_reason" => row["operator_action_reason"],
        "approval_requirements" => row["approval_requirements"],
        "approval_rule_matches" => row["approval_rule_matches"],
        "source_policy_decision" => row["policy_decision"],
        "escalation_level" => escalation["escalation_level"],
        "escalation_queue" => escalation["escalation_queue"],
        "escalation_role" => escalation["escalation_role"],
        "required_authority" => escalation["required_authority"],
        "sla_s" => escalation["sla_s"],
        "source_policy_escalation" => escalation,
        "source_station_calendar_entry" => row["source_station_calendar_entry"],
        "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
        "source_station_calendar_review" => row
      }
      |> compact_map()
    end)
  end

  def provider_contention_rows(
        groups,
        source \\ "station_calendar_report.provider_calendar_contention_groups"
      ) do
    groups
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {group, index} ->
      escalation = matched_policy_escalation(group)

      %{
        "id" => review_id(["station_provider_contention", group["id"], index]),
        "review_type" => "station_calendar_review",
        "source" => source,
        "subject_id" => group["id"],
        "ground_station_id" => group["ground_station_id"],
        "starts_at_s" => group["starts_at_s"],
        "ends_at_s" => group["ends_at_s"],
        "overlap_duration_s" => group["overlap_duration_s"],
        "action" =>
          Map.get(group, "required_operator_action", "review_station_provider_contention"),
        "required_operator_action" =>
          Map.get(group, "required_operator_action", "review_station_provider_contention"),
        "approval_status" => Map.get(group, "approval_status", "operator_review_required"),
        "reason" => station_provider_contention_reason(group),
        "operator_action_reason" => group["operator_action_reason"],
        "approval_requirements" => group["approval_requirements"],
        "approval_rule_matches" => group["approval_rule_matches"],
        "source_policy_decision" => group["policy_decision"],
        "escalation_level" => escalation["escalation_level"],
        "escalation_queue" => escalation["escalation_queue"],
        "escalation_role" => escalation["escalation_role"],
        "required_authority" => escalation["required_authority"],
        "sla_s" => escalation["sla_s"],
        "source_policy_escalation" => escalation,
        "provider_calendar_contention_status" => group["provider_calendar_contention_status"],
        "provider_calendar_contention_group_id" => group["id"],
        "provider_calendar_contention_entry_count" => group["entry_count"],
        "provider_calendar_contention_entry_ids" => group["entry_ids"],
        "provider_calendar_contention_provider_ids" => group["provider_ids"],
        "provider_calendar_contention_provider_entry_ids" => group["provider_entry_ids"],
        "provider_calendar_contention_availabilities" => group["availabilities"],
        "provider_calendar_contention_directions" => group["directions"],
        "provider_calendar_contention_reservation_ids" => group["reservation_ids"],
        "provider_calendar_contention_reserved_by" => group["reserved_by"],
        "provider_calendar_contention_reservation_statuses" => group["reservation_statuses"],
        "provider_calendar_contention_reservation_expires_at_s" =>
          group["reservation_expires_at_s"],
        "station_reservation_hold_import_status" =>
          group["station_reservation_hold_import_status"],
        "station_reservation_hold_import_readiness_summary_model" =>
          group["station_reservation_hold_import_readiness_summary_model"],
        "station_reservation_hold_import_readiness_source" =>
          group["station_reservation_hold_import_readiness_source"],
        "station_reservation_hold_import_readiness_source_artifact_type" =>
          group["station_reservation_hold_import_readiness_source_artifact_type"],
        "station_reservation_hold_import_readiness_status" =>
          group["station_reservation_hold_import_readiness_status"],
        "station_reservation_hold_import_classification" =>
          group["station_reservation_hold_import_classification"],
        "station_reservation_hold_count" => group["station_reservation_hold_count"],
        "station_reservation_hold_ids" => group["station_reservation_hold_ids"],
        "station_reservation_hold_ids_by_import_status" =>
          group["station_reservation_hold_ids_by_import_status"],
        "station_reservation_hold_ids_by_required_import_action" =>
          group["station_reservation_hold_ids_by_required_import_action"],
        "station_reservation_hold_ids_by_direction" =>
          group["station_reservation_hold_ids_by_direction"],
        "station_reservation_hold_ids_by_direction_and_ground_station_id" =>
          group["station_reservation_hold_ids_by_direction_and_ground_station_id"],
        "station_reservation_hold_contact_ids_by_import_status" =>
          group["station_reservation_hold_contact_ids_by_import_status"],
        "station_reservation_hold_contact_ids_by_expiration_status" =>
          group["station_reservation_hold_contact_ids_by_expiration_status"],
        "station_reservation_hold_contact_ids_by_direction" =>
          group["station_reservation_hold_contact_ids_by_direction"],
        "station_reservation_hold_contact_ids_by_direction_and_ground_station_id" =>
          group["station_reservation_hold_contact_ids_by_direction_and_ground_station_id"],
        "station_reservation_hold_import_status_counts" =>
          group["station_reservation_hold_import_status_counts"],
        "station_reservation_hold_required_import_action_counts" =>
          group["station_reservation_hold_required_import_action_counts"],
        "station_reservation_hold_import_execution_boundary" =>
          group["station_reservation_hold_import_execution_boundary"],
        "station_reservation_hold_provider_write" =>
          group["station_reservation_hold_provider_write"],
        "station_reservation_hold_cadence_write" =>
          group["station_reservation_hold_cadence_write"],
        "station_reservation_hold_reservation_acceptance" =>
          group["station_reservation_hold_reservation_acceptance"],
        "source_station_reservation_hold_import_readiness_summary" =>
          group["source_station_reservation_hold_import_readiness_summary"],
        "provider_calendar_contention_trust_boundary_statuses" =>
          group["trust_boundary_statuses"],
        "provider_calendar_contention_overlap_pairs" => group["overlap_pairs"],
        "source_station_calendar_provider_contention" => group
      }
      |> compact_map()
    end)
  end

  defp station_provider_contention_reason(%{
         "ground_station_id" => station_id,
         "entry_count" => entry_count
       }) do
    "review #{entry_count} overlapping provider calendar entries at #{station_id}"
  end

  defp station_provider_contention_reason(_group) do
    "review overlapping provider calendar entries"
  end

  defp station_calendar_precedence_summary?(%{} = summary) do
    model = summary["model"] || summary[:model]
    schema_contract = summary["schema_contract"] || summary[:schema_contract]

    model == "artifact_only_station_calendar_precedence_summary" or
      schema_contract == "station_calendar_precedence_summary.v1"
  end

  defp station_calendar_precedence_summary?(_summary), do: false

  defp station_calendar_precedence_summary_rows(summary, source) do
    summary = stringify_keys(summary)
    context = station_calendar_precedence_summary_context(summary)

    if station_calendar_precedence_reviewable_summary?(summary) do
      [
        %{
          "id" =>
            review_id([
              "station_calendar_precedence_summary",
              stable_id_fragment(source),
              summary["source"] || summary["source_artifact_type"]
            ]),
          "review_type" => "station_calendar_review",
          "source" => source,
          "subject_id" =>
            summary["source"] ||
              summary["source_artifact_type"] ||
              "station_calendar_precedence_summary",
          "source_artifact_type" => summary["source_artifact_type"],
          "action" => "review_station_calendar",
          "required_operator_action" => "review_station_calendar",
          "approval_status" => "operator_review_required",
          "reason" => "review station calendar precedence summary",
          "station_calendar_precedence_review_status" => summary["precedence_review_status"],
          "station_calendar_precedence_affected_contact_count" =>
            summary["affected_contact_count"],
          "station_calendar_precedence_applied_availability_counts" =>
            summary["applied_availability_counts"],
          "station_calendar_precedence_overlap_availability_counts" =>
            summary["overlap_availability_counts"],
          "station_calendar_precedence_affected_contact_ids_by_applied_availability" =>
            summary["affected_contact_ids_by_applied_availability"],
          "station_calendar_precedence_affected_contact_ids_by_overlap_availability" =>
            summary["affected_contact_ids_by_overlap_availability"],
          "station_calendar_precedence_reserved_under_higher_precedence_contact_count" =>
            summary["reserved_under_higher_precedence_contact_count"],
          "station_calendar_precedence_reserved_under_higher_precedence_contact_ids" =>
            summary["reserved_under_higher_precedence_contact_ids"],
          "station_calendar_precedence_reserved_under_higher_precedence_contact_ids_by_applied_availability" =>
            summary["reserved_under_higher_precedence_contact_ids_by_applied_availability"],
          "station_calendar_precedence_reserved_overlap_contact_ids" =>
            summary["reserved_overlap_contact_ids"],
          "station_calendar_precedence_reduced_capacity_contact_ids" =>
            summary["reduced_capacity_contact_ids"],
          "station_calendar_precedence_unavailable_contact_ids" =>
            summary["unavailable_contact_ids"],
          "station_calendar_precedence_model_limits" => summary["model_limits"],
          "source_station_calendar_precedence_summary" => context
        }
        |> compact_map()
      ]
    else
      []
    end
  end

  defp station_calendar_precedence_reviewable_summary?(summary) do
    summary["precedence_review_status"] not in [nil, "passed", "importable"] or
      positive_report_count?(summary, "affected_contact_count") or
      positive_report_count?(summary, "reserved_under_higher_precedence_contact_count")
  end

  defp station_calendar_precedence_summary_context(summary) do
    summary
    |> Map.put_new("source_summary_schema_contract", summary["schema_contract"])
    |> Map.put_new("source_summary_model", summary["model"])
  end

  defp station_calendar_action(%{"provider_counteroffer_id" => id}) when is_binary(id),
    do: "review_provider_counteroffer"

  defp station_calendar_action(%{"provider_counteroffer_status" => status})
       when is_binary(status),
       do: "review_provider_counteroffer"

  defp station_calendar_action(%{"station_contention_status" => "reserved_overlap"}),
    do: "review_station_reservation_overlap"

  defp station_calendar_action(%{"station_calendar_reservation_overlap_count" => count})
       when is_number(count) and count > 0,
       do: "review_station_reservation_overlap"

  defp station_calendar_action(%{"station_availability" => "reserved"}),
    do: "review_station_reservation_overlap"

  defp station_calendar_action(%{"station_availability" => "reduced_capacity"}),
    do: "review_reduced_station_capacity"

  defp station_calendar_action(_row), do: "review_station_availability"

  defp station_calendar_reason(%{
         "provider_counteroffer_id" => counteroffer_id,
         "ground_station_id" => station
       })
       when is_binary(counteroffer_id) and is_binary(station) do
    "station #{station} provider counteroffer #{counteroffer_id} requires operator review"
  end

  defp station_calendar_reason(%{"provider_counteroffer_id" => counteroffer_id})
       when is_binary(counteroffer_id),
       do: "provider counteroffer #{counteroffer_id} requires operator review"

  defp station_calendar_reason(%{
         "station_availability" => availability,
         "ground_station_id" => station
       })
       when is_binary(availability) and is_binary(station) do
    "station #{station} calendar reports #{availability}"
  end

  defp station_calendar_reason(%{"station_availability" => availability})
       when is_binary(availability),
       do: "station calendar reports #{availability}"

  defp station_calendar_reason(_row), do: "station calendar row requires operator review"

  defp normalize_station_calendar_status_fields(%{} = row) do
    row
    |> normalize_station_calendar_status_field("availability")
    |> normalize_station_calendar_status_field("status")
    |> normalize_station_calendar_status_field("station_availability")
    |> normalize_station_calendar_status_field("station_calendar_status")
    |> normalize_station_calendar_status_field("station_contention_status")
    |> normalize_station_calendar_status_field("reservation_status")
    |> normalize_station_calendar_status_field("station_reservation_status")
    |> normalize_station_calendar_status_field("reservation_match_status")
    |> normalize_station_calendar_status_field("station_reservation_match_status")
    |> normalize_station_calendar_status_field("station_calendar_overlap_availabilities")
    |> normalize_station_calendar_status_field("station_calendar_reservation_statuses")
    |> normalize_nested_station_calendar_status_field("source_station_calendar_entry")
    |> normalize_nested_station_calendar_status_field("source_station_calendar_overlaps")
  end

  defp normalize_station_calendar_status_fields(value), do: value

  defp normalize_nested_station_calendar_status_field(row, field) do
    case Map.fetch(row, field) do
      {:ok, value} -> Map.put(row, field, normalize_station_calendar_status_value(value))
      :error -> row
    end
  end

  defp normalize_station_calendar_status_field(row, field) do
    case Map.fetch(row, field) do
      {:ok, value} -> Map.put(row, field, normalize_station_calendar_status_value(value))
      :error -> row
    end
  end

  defp normalize_station_calendar_status_value(values) when is_list(values) do
    Enum.map(values, &normalize_station_calendar_status_value/1)
  end

  defp normalize_station_calendar_status_value(%{} = value) do
    normalize_station_calendar_status_fields(value)
  end

  defp normalize_station_calendar_status_value(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp normalize_station_calendar_status_value(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> normalize_station_calendar_status_value()
  end

  defp normalize_station_calendar_status_value(value), do: value

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

  defp policy_escalation_context?(%{} = row) do
    Enum.any?(
      ["escalation_level", "escalation_queue", "escalation_role", "required_authority", "sla_s"],
      &Map.has_key?(row, &1)
    )
  end

  defp policy_escalation_context?(_row), do: false

  def candidate_refresh_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_station_calendar_report",
         artifact["source_station_calendar_report"]},
        {"candidate_refresh.station_calendar_report", artifact["station_calendar_report"]},
        {"candidate_refresh.accepted_planning_state.source_station_calendar_precedence_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_station_calendar_precedence_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.station_calendar_precedence_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "station_calendar_precedence_summary"
         ])},
        {"candidate_refresh.mission_state.source_station_calendar_precedence_summary",
         get_in(artifact, [
           "mission_state",
           "source_station_calendar_precedence_summary"
         ])},
        {"candidate_refresh.mission_state.station_calendar_precedence_summary",
         get_in(artifact, [
           "mission_state",
           "station_calendar_precedence_summary"
         ])},
        {"candidate_refresh.source_station_calendar_precedence_summary",
         artifact["source_station_calendar_precedence_summary"]},
        {"candidate_refresh.station_calendar_precedence_summary",
         artifact["station_calendar_precedence_summary"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_rows(artifact)
  end

  def source_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_report_rows(report, "#{source}[#{index}]")
    end)
  end

  def source_report_rows(%{} = report, source) do
    report = stringify_keys(report)

    if station_calendar_precedence_summary?(report) do
      station_calendar_precedence_summary_rows(report, source)
    else
      rows(
        Map.get(report, "affected_contacts", []),
        "#{source}.affected_contacts"
      ) ++
        provider_contention_rows(
          Map.get(report, "provider_calendar_contention_groups", []),
          "#{source}.provider_calendar_contention_groups"
        )
    end
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
         %{"schema_contract" => "station_calendar_report.v1"} = report,
         source
       ) do
    source_report_rows(report, source)
  end

  defp result_artifact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_station_calendar_report", artifact["source_station_calendar_report"]},
      {"#{source}.station_calendar_report", artifact["station_calendar_report"]},
      {"#{source}.source_station_calendar_precedence_summary",
       artifact["source_station_calendar_precedence_summary"]},
      {"#{source}.station_calendar_precedence_summary",
       artifact["station_calendar_precedence_summary"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_rows(_artifact, _source), do: []

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

  defp stable_id_fragment(nil), do: nil

  defp stable_id_fragment(value) when is_binary(value) do
    value
    |> String.replace(~r/[^A-Za-z0-9._:@-]/, "_")
    |> String.trim("_")
    |> case do
      "" ->
        "root"

      fragment ->
        if Regex.match?(~r/^[A-Za-z0-9]/, fragment) do
          fragment
        else
          "path:#{fragment}"
        end
    end
  end

  defp stable_id_fragment(value), do: encode_value(value)

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

  defp provider_counteroffer_duration_delta(row) do
    with start when is_number(start) <- numeric_or_nil(row["starts_at_s"]),
         finish when is_number(finish) <- numeric_or_nil(row["ends_at_s"]),
         counter_start when is_number(counter_start) <-
           numeric_or_nil(row["provider_counteroffer_starts_at_s"]),
         counter_finish when is_number(counter_finish) <-
           numeric_or_nil(row["provider_counteroffer_ends_at_s"]) do
      counter_finish - counter_start - (finish - start)
    else
      _value -> nil
    end
  end

  defp numeric_delta(left, right) do
    with left when is_number(left) <- numeric_or_nil(left),
         right when is_number(right) <- numeric_or_nil(right) do
      left - right
    else
      _value -> nil
    end
  end

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
    Enum.flat_map(@provider_result_map_value_keys, fn key ->
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

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _other -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp positive_report_count?(summary, field) do
    case numeric_or_nil(summary[field]) do
      nil -> false
      value -> value > 0
    end
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
