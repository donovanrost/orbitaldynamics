defmodule OrbitalDynamics.OperatorReview.ContactAllocation do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.ContactAllocationSummary
  alias OrbitalDynamics.OperatorReview.PackageBuilder
  alias OrbitalDynamics.OperatorReview.StationCalendar

  @schema_contract "operator_review_package.v1"

  def report_package(report) do
    {rows, source_artifact_id, provenance} = report_package_input(report)

    package(rows, "contact_allocation_report.v1", source_artifact_id, provenance)
    |> ContactAllocationSummary.put([report])
  end

  def capacity_pack_summary_package(summary) do
    {rows, source_artifact_id, provenance} = capacity_pack_summary_package_input(summary)

    package(
      rows,
      "contact_allocation_capacity_pack_summary.v1",
      source_artifact_id,
      provenance
    )
    |> ContactAllocationSummary.put([summary])
  end

  def reservation_conflict_summary_package(summary) do
    {rows, source_artifact_id, provenance} = reservation_conflict_summary_package_input(summary)

    package(
      rows,
      "contact_allocation_reservation_conflict_summary.v1",
      source_artifact_id,
      provenance
    )
    |> ContactAllocationSummary.put([summary])
  end

  def report_package_input(report) do
    report = stringify_keys(report || %{})

    {
      report_rows(report),
      Map.get(report, "id") || Map.get(report, "source") || "contact_allocation_report",
      Map.get(report, "provenance", %{})
    }
  end

  def capacity_pack_summary_package_input(summary) do
    summary = stringify_keys(summary || %{})

    {
      summary_rows(summary, "contact_allocation_capacity_pack_summary"),
      Map.get(summary, "id") || Map.get(summary, "source") ||
        "contact_allocation_capacity_pack_summary",
      Map.get(summary, "provenance", %{})
    }
  end

  def reservation_conflict_summary_package_input(summary) do
    summary = stringify_keys(summary || %{})

    {
      summary_rows(summary, "contact_allocation_reservation_conflict_summary"),
      Map.get(summary, "id") || Map.get(summary, "source") ||
        "contact_allocation_reservation_conflict_summary",
      Map.get(summary, "provenance", %{})
    }
  end

  def report_rows(report, source \\ "contact_allocation_report") do
    report = stringify_keys(report)

    rows(Map.get(report, "rows", []), "#{source}.rows") ++
      capacity_pack_rows(
        Map.get(report, "reduced_capacity_pack_groups", []),
        "#{source}.reduced_capacity_pack_groups"
      ) ++
      station_calendar_provider_contention_rows(report, source)
  end

  def summary_rows(%{} = summary, source) do
    summary = stringify_keys(summary)

    summary_contact_review_rows(summary, source) ++
      summary_capacity_pack_rows(summary, source)
  end

  def candidate_refresh_rows(artifact) do
    artifact = stringify_keys(artifact)

    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_contact_allocation_report",
         get_in(artifact, ["accepted_planning_state", "source_contact_allocation_report"])},
        {"candidate_refresh.accepted_planning_state.contact_allocation_report",
         get_in(artifact, ["accepted_planning_state", "contact_allocation_report"])},
        {"candidate_refresh.accepted_planning_state.source_contact_allocation_summary",
         get_in(artifact, ["accepted_planning_state", "source_contact_allocation_summary"])},
        {"candidate_refresh.accepted_planning_state.contact_allocation_summary",
         get_in(artifact, ["accepted_planning_state", "contact_allocation_summary"])},
        {"candidate_refresh.accepted_planning_state.source_contact_allocation_station_pressure_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_contact_allocation_station_pressure_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.contact_allocation_station_pressure_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "contact_allocation_station_pressure_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.source_contact_allocation_reservation_conflict_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_contact_allocation_reservation_conflict_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.contact_allocation_reservation_conflict_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "contact_allocation_reservation_conflict_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.source_contact_allocation_capacity_pack_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_contact_allocation_capacity_pack_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.contact_allocation_capacity_pack_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "contact_allocation_capacity_pack_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.source_contact_allocation_provider_reservation_request_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_contact_allocation_provider_reservation_request_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.contact_allocation_provider_reservation_request_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "contact_allocation_provider_reservation_request_summary"
         ])},
        {"candidate_refresh.mission_state.source_contact_allocation_report",
         get_in(artifact, ["mission_state", "source_contact_allocation_report"])},
        {"candidate_refresh.mission_state.contact_allocation_report",
         get_in(artifact, ["mission_state", "contact_allocation_report"])},
        {"candidate_refresh.mission_state.source_contact_allocation_summary",
         get_in(artifact, ["mission_state", "source_contact_allocation_summary"])},
        {"candidate_refresh.mission_state.contact_allocation_summary",
         get_in(artifact, ["mission_state", "contact_allocation_summary"])},
        {"candidate_refresh.mission_state.source_contact_allocation_station_pressure_summary",
         get_in(artifact, [
           "mission_state",
           "source_contact_allocation_station_pressure_summary"
         ])},
        {"candidate_refresh.mission_state.contact_allocation_station_pressure_summary",
         get_in(artifact, ["mission_state", "contact_allocation_station_pressure_summary"])},
        {"candidate_refresh.mission_state.source_contact_allocation_reservation_conflict_summary",
         get_in(artifact, [
           "mission_state",
           "source_contact_allocation_reservation_conflict_summary"
         ])},
        {"candidate_refresh.mission_state.contact_allocation_reservation_conflict_summary",
         get_in(artifact, [
           "mission_state",
           "contact_allocation_reservation_conflict_summary"
         ])},
        {"candidate_refresh.mission_state.source_contact_allocation_capacity_pack_summary",
         get_in(artifact, ["mission_state", "source_contact_allocation_capacity_pack_summary"])},
        {"candidate_refresh.mission_state.contact_allocation_capacity_pack_summary",
         get_in(artifact, ["mission_state", "contact_allocation_capacity_pack_summary"])},
        {"candidate_refresh.mission_state.source_contact_allocation_provider_reservation_request_summary",
         get_in(artifact, [
           "mission_state",
           "source_contact_allocation_provider_reservation_request_summary"
         ])},
        {"candidate_refresh.mission_state.contact_allocation_provider_reservation_request_summary",
         get_in(artifact, [
           "mission_state",
           "contact_allocation_provider_reservation_request_summary"
         ])},
        {"candidate_refresh.source_contact_allocation_report",
         artifact["source_contact_allocation_report"]},
        {"candidate_refresh.contact_allocation_report", artifact["contact_allocation_report"]},
        {"candidate_refresh.source_contact_allocation_summary",
         artifact["source_contact_allocation_summary"]},
        {"candidate_refresh.contact_allocation_summary", artifact["contact_allocation_summary"]},
        {"candidate_refresh.source_contact_allocation_station_pressure_summary",
         artifact["source_contact_allocation_station_pressure_summary"]},
        {"candidate_refresh.contact_allocation_station_pressure_summary",
         artifact["contact_allocation_station_pressure_summary"]},
        {"candidate_refresh.source_contact_allocation_reservation_conflict_summary",
         artifact["source_contact_allocation_reservation_conflict_summary"]},
        {"candidate_refresh.contact_allocation_reservation_conflict_summary",
         artifact["contact_allocation_reservation_conflict_summary"]},
        {"candidate_refresh.source_contact_allocation_capacity_pack_summary",
         artifact["source_contact_allocation_capacity_pack_summary"]},
        {"candidate_refresh.contact_allocation_capacity_pack_summary",
         artifact["contact_allocation_capacity_pack_summary"]},
        {"candidate_refresh.source_contact_allocation_provider_reservation_request_summary",
         artifact["source_contact_allocation_provider_reservation_request_summary"]},
        {"candidate_refresh.contact_allocation_provider_reservation_request_summary",
         artifact["contact_allocation_provider_reservation_request_summary"]}
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

    cond do
      review_summary?(report) ->
        summary_rows(report, source)

      provider_reservation_request_summary?(report) ->
        report
        |> source_report_rows_from_provider_reservation_summary()
        |> rows("#{source}.provider_reservation_request_rows")

      true ->
        report_rows(report, source)
    end
  end

  def source_report_rows(_report, _source), do: []

  def rows(rows, source \\ "contact_allocation_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      contact_id = row["contact_id"]
      required_operator_action = contact_allocation_required_operator_action(row)
      requirement = row["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = preferred_approval_rule_match(row)
      policy_decision = stringify_keys(row["policy_decision"] || %{})
      policy_escalation = row |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["contact_allocation", stable_id_fragment(source), contact_id, index]),
        "review_type" => "contact_allocation_review",
        "source" => source,
        "subject_id" => contact_id,
        "activity_id" => contact_id,
        "activity_type" => row["type"],
        "contact_id" => contact_id,
        "scenario_id" => row["scenario_id"],
        "spacecraft_id" => row["spacecraft_id"],
        "ground_station_id" => row["ground_station_id"],
        "direction" => row["direction"],
        "starts_at_s" => row["starts_at_s"],
        "ends_at_s" => row["ends_at_s"],
        "source_window_id" => row["source_window_id"],
        "source_window_type" => row["source_window_type"],
        "source_window" => row["source_window"],
        "actual_throughput_mb" => row["actual_throughput_mb"],
        "actual_data_rate_throughput_derivation" => row["actual_data_rate_throughput_derivation"],
        "completed_fraction" => row["completed_fraction"],
        "required_downlink_mb" => row["required_downlink_mb"],
        "candidate_downlink_mb" => row["candidate_downlink_mb"],
        "downlink_completion_ratio" => row["downlink_completion_ratio"],
        "selected_downlink_shortfall_mb" => row["selected_downlink_shortfall_mb"],
        "downlink_requirement_status" => row["downlink_requirement_status"],
        "downlink_completion_source" => row["downlink_completion_source"],
        "downlink_completion_sources" => row["downlink_completion_sources"],
        "required_capacity_fraction" => row["required_capacity_fraction"],
        "required_capacity_fraction_source" => row["required_capacity_fraction_source"],
        "contact_success" => row["contact_success"],
        "contact_success_factor" => row["contact_success_factor"],
        "contact_success_factor_source" => row["contact_success_factor_source"],
        "command_success" => row["command_success"],
        "contact_result" => provider_result_artifact_value(row["contact_result"]),
        "command_result" => provider_result_artifact_value(row["command_result"]),
        "command_success_factor" => row["command_success_factor"],
        "command_success_factor_source" => row["command_success_factor_source"],
        "allocation_status" => row["allocation_status"],
        "effective_allocation_status" => row["effective_allocation_status"],
        "allocation_reason" => row["allocation_reason"],
        "selected" => row["selected"],
        "contention_group_id" => row["contention_group_id"],
        "selected_contact_id" => row["selected_contact_id"],
        "deferred_contact_ids" => Map.get(row, "deferred_contact_ids", []),
        "capacity_pack_group_id" => row["capacity_pack_group_id"],
        "capacity_pack_status" => row["capacity_pack_status"],
        "capacity_pack_capacity_fraction" => row["capacity_pack_capacity_fraction"],
        "capacity_pack_used_fraction" => row["capacity_pack_used_fraction"],
        "selected_priority" => row["selected_priority"],
        "selected_priority_source" => row["selected_priority_source"],
        "deferred_contact_priorities" => row["deferred_contact_priorities"],
        "requested_priority_fields" => row["requested_priority_fields"],
        "priority_field_evidence_counts" => row["priority_field_evidence_counts"],
        "priority_fields_without_numeric_evidence_count" =>
          row["priority_fields_without_numeric_evidence_count"],
        "priority_fields_without_numeric_evidence" =>
          row["priority_fields_without_numeric_evidence"],
        "resolution_priority_override_count" => row["resolution_priority_override_count"],
        "resolution_priority_override_contact_ids" =>
          row["resolution_priority_override_contact_ids"],
        "ignored_priority_override_count" => row["ignored_priority_override_count"],
        "ignored_priority_override_keys" => row["ignored_priority_override_keys"],
        "ignored_priority_override_contact_ids" => row["ignored_priority_override_contact_ids"],
        "ignored_priority_override_input" => row["ignored_priority_override_input"],
        "suppressed_reason" => row["suppressed_reason"],
        "duplicate_contact_id_collision" => row["duplicate_contact_id_collision"],
        "duplicate_contact_index" => row["duplicate_contact_index"],
        "duplicate_contact_candidate_count" => row["duplicate_contact_candidate_count"],
        "duplicate_contact_candidate_ids" => row["duplicate_contact_candidate_ids"],
        "duplicate_contact_candidates" => row["duplicate_contact_candidates"],
        "station_calendar_entry_id" => row["station_calendar_entry_id"],
        "station_calendar_provider_id" => row["station_calendar_provider_id"],
        "station_calendar_provider_entry_id" => row["station_calendar_provider_entry_id"],
        "station_calendar_directions" => row["station_calendar_directions"],
        "station_calendar_status" => row["station_calendar_status"],
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
        "station_calendar_trust_boundary_status" => row["station_calendar_trust_boundary_status"],
        "trust_boundary" => row["trust_boundary"],
        "provenance" => row["provenance"],
        "provider_counteroffer_id" => row["provider_counteroffer_id"],
        "provider_counteroffer_status" => row["provider_counteroffer_status"],
        "provider_counteroffer_negotiation_state" =>
          row["provider_counteroffer_negotiation_state"],
        "provider_counteroffer_reason_code" => row["provider_counteroffer_reason_code"],
        "provider_counteroffer_cost_delta" => row["provider_counteroffer_cost_delta"],
        "provider_counteroffer_lock_deadline_s" => row["provider_counteroffer_lock_deadline_s"],
        "provider_counteroffer_starts_at_s" => row["provider_counteroffer_starts_at_s"],
        "provider_counteroffer_ends_at_s" => row["provider_counteroffer_ends_at_s"],
        "provider_counteroffer_start_delta_s" => row["provider_counteroffer_start_delta_s"],
        "provider_counteroffer_end_delta_s" => row["provider_counteroffer_end_delta_s"],
        "provider_counteroffer_duration_delta_s" => row["provider_counteroffer_duration_delta_s"],
        "station_availability" => row["station_availability"],
        "capacity_fraction" => row["capacity_fraction"],
        "station_contention_status" => row["station_contention_status"],
        "station_reservation_id" => row["station_reservation_id"],
        "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
        "station_reserved_by" => row["station_reserved_by"],
        "station_reservation_status" => row["station_reservation_status"],
        "station_reservation_match_status" => row["station_reservation_match_status"],
        "provider_reservation_request_status" => row["provider_reservation_request_status"],
        "provider_reservation_request_summary_model" =>
          row["provider_reservation_request_summary_model"],
        "provider_reservation_request_summary_schema_contract" =>
          row["provider_reservation_request_summary_schema_contract"],
        "provider_reservation_request_source_artifact_type" =>
          row["provider_reservation_request_source_artifact_type"],
        "provider_reservation_request_source" => row["provider_reservation_request_source"],
        "provider_reservation_request_execution_boundary" =>
          row["provider_reservation_request_execution_boundary"],
        "provider_reservation_execution" => row["provider_reservation_execution"],
        "resource_blocking_dimension" => row["resource_blocking_dimension"],
        "resource_source_quality" => row["resource_source_quality"],
        "resource_trust_boundary" => row["resource_trust_boundary"],
        "resource_trust_boundary_status" => row["resource_trust_boundary_status"],
        "resource_provenance" => row["resource_provenance"],
        "fuel_margin" => row["fuel_margin"],
        "thermal_margin_c" => row["thermal_margin_c"],
        "power_margin" => row["power_margin"],
        "storage_margin" => row["storage_margin"],
        "downlink_margin" => row["downlink_margin"],
        "battery_capacity_wh" => row["battery_capacity_wh"],
        "battery_energy_used_wh" => row["battery_energy_used_wh"],
        "battery_energy_generated_wh" => row["battery_energy_generated_wh"],
        "battery_state_of_charge" => row["battery_state_of_charge"],
        "spacecraft_available" => row["spacecraft_available"],
        "planned_spacecraft_available" => row["planned_spacecraft_available"],
        "realized_spacecraft_available" => row["realized_spacecraft_available"],
        "spacecraft_available_match_status" => row["spacecraft_available_match_status"],
        "payload_available" => row["payload_available"],
        "planned_payload_available" => row["planned_payload_available"],
        "realized_payload_available" => row["realized_payload_available"],
        "payload_available_match_status" => row["payload_available_match_status"],
        "antenna_available" => row["antenna_available"],
        "planned_antenna_available" => row["planned_antenna_available"],
        "realized_antenna_available" => row["realized_antenna_available"],
        "antenna_available_match_status" => row["antenna_available_match_status"],
        "degraded" => row["degraded"],
        "planned_degraded" => row["planned_degraded"],
        "realized_degraded" => row["realized_degraded"],
        "degraded_match_status" => row["degraded_match_status"],
        "mode" => row["mode"],
        "planned_mode" => row["planned_mode"],
        "realized_mode" => row["realized_mode"],
        "mode_match_status" => row["mode_match_status"],
        "incompatible_activity_types" => row["incompatible_activity_types"],
        "suppressed_activity_types" => row["suppressed_activity_types"],
        "action" => required_operator_action,
        "required_operator_action" => required_operator_action,
        "approval_status" => row["approval_status"] || "operator_review_required",
        "reason" => contact_allocation_reason(row),
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
        "source_contact_allocation" => row,
        "source_policy_decision" => row["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_contact_candidate" => row["source_contact_candidate"],
        "source_resource_summary" => row["source_resource_summary"],
        "source_resource_suppression" => row["source_resource_suppression"],
        "source_contact_suppression" => row["source_contact_suppression"],
        "source_station_calendar_entry" => row["source_station_calendar_entry"],
        "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
        "source_contention_recommendation" => row["source_contention_recommendation"],
        "source_provider_reservation_request_summary" =>
          row["source_provider_reservation_request_summary"]
      }
      |> compact_map()
    end)
  end

  defp contact_allocation_required_operator_action(%{
         "provider_reservation_request_status" => "request_ready"
       }),
       do: "review_provider_reservation_request"

  defp contact_allocation_required_operator_action(_row), do: "review_contact_allocation"

  defp contact_allocation_reason(%{
         "allocation_status" => status,
         "allocation_reason" => reason,
         "contact_id" => contact_id
       }) do
    "review #{status} contact allocation for #{contact_id}: #{reason}"
  end

  defp contact_allocation_reason(_row), do: "review contact allocation row"

  def capacity_pack_rows(
        groups,
        source \\ "contact_allocation_report.reduced_capacity_pack_groups"
      ) do
    groups
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {group, index} ->
      group = put_contact_allocation_capacity_pack_direction_summary(group)
      group_id = group["contention_group_id"]

      %{
        "id" =>
          review_id([
            "contact_allocation_capacity_pack",
            stable_id_fragment(source),
            group_id,
            index
          ]),
        "review_type" => "contact_allocation_capacity_pack_review",
        "source" => source,
        "subject_id" => group_id,
        "contention_group_id" => group_id,
        "ground_station_id" => group["ground_station_id"],
        "capacity_fraction" => group["capacity_fraction"],
        "used_capacity_fraction" => group["used_capacity_fraction"],
        "unused_capacity_fraction" => group["unused_capacity_fraction"],
        "default_required_capacity_fraction" => group["default_required_capacity_fraction"],
        "input_contact_ids" => group["input_contact_ids"],
        "selected_contact_ids" => group["selected_contact_ids"],
        "capacity_packed_contact_ids" => group["capacity_packed_contact_ids"],
        "deferred_contact_ids" => group["deferred_contact_ids"],
        "capacity_pack_contact_ids_by_direction" =>
          group["capacity_pack_contact_ids_by_direction"],
        "capacity_pack_selected_contact_ids_by_direction" =>
          group["capacity_pack_selected_contact_ids_by_direction"],
        "capacity_pack_deferred_contact_ids_by_direction" =>
          group["capacity_pack_deferred_contact_ids_by_direction"],
        "capacity_pack_required_capacity_fraction_by_direction" =>
          group["capacity_pack_required_capacity_fraction_by_direction"],
        "capacity_pack_selected_required_capacity_fraction_by_direction" =>
          group["capacity_pack_selected_required_capacity_fraction_by_direction"],
        "capacity_pack_deferred_required_capacity_fraction_by_direction" =>
          group["capacity_pack_deferred_required_capacity_fraction_by_direction"],
        "capacity_requirement_rows" => group["capacity_requirement_rows"],
        "pack_status" => group["pack_status"],
        "action" => "review_contact_allocation_capacity_pack",
        "required_operator_action" => "review_contact_allocation_capacity_pack",
        "approval_status" => "operator_review_required",
        "reason" => contact_allocation_capacity_pack_reason(group),
        "source_contact_allocation_capacity_pack" => group,
        "source_contention_recommendation" => group["source_contention_recommendation"]
      }
      |> compact_map()
    end)
  end

  defp station_calendar_provider_contention_rows(
         report,
         source_prefix
       ) do
    report
    |> get_in(["station_calendar_report", "provider_calendar_contention_groups"])
    |> case do
      groups when is_list(groups) ->
        StationCalendar.provider_contention_rows(
          groups,
          "#{source_prefix}.station_calendar_report.provider_calendar_contention_groups"
        )

      _groups ->
        []
    end
  end

  defp summary_contact_review_rows(%{} = summary, source) do
    summary_context = summary_context(summary)
    {rows, row_source} = summary_review_row_source(summary, source)

    rows
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(&put_summary_context(&1, summary, summary_context))
    |> rows(row_source)
  end

  defp summary_capacity_pack_rows(
         %{"schema_contract" => "contact_allocation_capacity_pack_summary.v1"} = summary,
         source
       ) do
    summary_context = summary_context(summary)

    summary
    |> Map.get("reduced_capacity_pack_groups", [])
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(fn group ->
      group
      |> Map.put("source_contact_allocation_summary", summary_context)
      |> Map.put("source_summary_model", summary["model"])
      |> Map.put("source_summary_schema_contract", summary["schema_contract"])
      |> Map.put("source_artifact_type", summary["source_artifact_type"])
      |> Map.put("source", summary["source"])
      |> Map.put("schema_contract", summary["schema_contract"])
      |> compact_map()
    end)
    |> capacity_pack_rows("#{source}.reduced_capacity_pack_groups")
  end

  defp summary_capacity_pack_rows(_summary, _source), do: []

  defp summary_review_row_source(
         %{"schema_contract" => "contact_allocation_reservation_conflict_summary.v1"} = summary,
         source
       ) do
    first_summary_rows(summary, [
      {"reservation_review_rows", "#{source}.reservation_review_rows"},
      {"reservation_conflict_rows", "#{source}.reservation_conflict_rows"},
      {"review_rows", "#{source}.review_rows"},
      {"rows", "#{source}.rows"}
    ])
  end

  defp summary_review_row_source(summary, source) do
    first_summary_rows(summary, [
      {"review_rows", "#{source}.review_rows"},
      {"rows", "#{source}.rows"}
    ])
  end

  defp first_summary_rows(summary, row_sources) do
    Enum.find_value(row_sources, {[], "contact_allocation_summary.rows"}, fn {field, source} ->
      rows = Map.get(summary, field, [])

      if is_list(rows) and rows != [] do
        {rows, source}
      end
    end)
  end

  defp put_summary_context(row, summary, summary_context) do
    row
    |> Map.put("source_contact_allocation_summary", summary_context)
    |> Map.put("source_summary_model", summary["model"])
    |> Map.put("source_summary_schema_contract", summary["schema_contract"])
    |> Map.put("source_artifact_type", summary["source_artifact_type"])
    |> Map.put("source", summary["source"])
    |> Map.put("schema_contract", summary["schema_contract"])
    |> compact_map()
  end

  defp summary_context(%{} = summary) do
    %{
      "model" => summary["model"],
      "schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "source" => summary["source"],
      "input_contact_count" => summary["input_contact_count"],
      "allocated_contact_count" => summary["allocated_contact_count"],
      "returned_allocated_contact_count" => summary["returned_allocated_contact_count"],
      "deferred_contact_count" => summary["deferred_contact_count"],
      "blocked_contact_count" => summary["blocked_contact_count"],
      "review_contact_ids" => summary["review_contact_ids"],
      "station_pressure_review_contact_ids" => summary["station_pressure_review_contact_ids"],
      "station_pressure_contact_ids_by_status" =>
        summary["station_pressure_contact_ids_by_status"],
      "station_pressure_contact_ids_by_direction" =>
        summary["station_pressure_contact_ids_by_direction"],
      "station_pressure_contact_ids_by_direction_and_ground_station_id" =>
        summary["station_pressure_contact_ids_by_direction_and_ground_station_id"],
      "reservation_review_contact_ids" => summary["reservation_review_contact_ids"],
      "reservation_conflict_contact_ids_by_direction" =>
        summary["reservation_conflict_contact_ids_by_direction"],
      "reservation_conflict_contact_ids_by_direction_and_ground_station_id" =>
        summary["reservation_conflict_contact_ids_by_direction_and_ground_station_id"],
      "capacity_pack_review_status" => summary["capacity_pack_review_status"],
      "reduced_capacity_pack_group_count" => summary["reduced_capacity_pack_group_count"],
      "assumptions" => summary["assumptions"]
    }
    |> compact_map()
  end

  defp review_summary?(%{
         "schema_contract" => schema_contract
       })
       when schema_contract in [
              "contact_allocation_summary.v1",
              "contact_allocation_station_pressure_summary.v1",
              "contact_allocation_reservation_conflict_summary.v1",
              "contact_allocation_capacity_pack_summary.v1"
            ],
       do: true

  defp review_summary?(_summary), do: false

  defp source_report_rows_from_provider_reservation_summary(%{} = summary) do
    summary = stringify_keys(summary)
    assumptions = stringify_keys(Map.get(summary, "assumptions", %{}))

    summary_context =
      %{
        "model" => summary["model"],
        "schema_contract" => summary["schema_contract"],
        "source_artifact_type" => summary["source_artifact_type"],
        "source" => summary["source"],
        "provider_reservation_candidate_contact_count" =>
          summary["provider_reservation_candidate_contact_count"],
        "provider_reservation_request_contact_count" =>
          summary["provider_reservation_request_contact_count"],
        "provider_reservation_review_contact_count" =>
          summary["provider_reservation_review_contact_count"],
        "provider_reservation_no_request_contact_count" =>
          summary["provider_reservation_no_request_contact_count"],
        "provider_reservation_request_status" => summary["provider_reservation_request_status"],
        "assumptions" => summary["assumptions"]
      }
      |> compact_map()

    request_rows =
      provider_reservation_summary_rows(
        summary["provider_reservation_request_rows"],
        "request_ready",
        summary,
        assumptions,
        summary_context
      )

    review_rows =
      provider_reservation_summary_rows(
        summary["provider_reservation_review_rows"],
        "review_required",
        summary,
        assumptions,
        summary_context
      )

    request_rows ++ review_rows
  end

  defp provider_reservation_summary_rows(rows, status, summary, assumptions, summary_context) do
    rows
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(fn row ->
      row
      |> Map.put("provider_reservation_request_status", status)
      |> Map.put("provider_reservation_request_summary_model", summary["model"])
      |> Map.put(
        "provider_reservation_request_summary_schema_contract",
        summary["schema_contract"]
      )
      |> Map.put(
        "provider_reservation_request_source_artifact_type",
        summary["source_artifact_type"]
      )
      |> Map.put("provider_reservation_request_source", summary["source"])
      |> Map.put(
        "provider_reservation_request_execution_boundary",
        assumptions["execution_boundary"]
      )
      |> Map.put("provider_reservation_execution", assumptions["provider_reservation_execution"])
      |> Map.put("source_provider_reservation_request_summary", summary_context)
      |> compact_map()
    end)
  end

  defp provider_reservation_request_summary?(%{
         "model" => "artifact_only_contact_allocation_provider_reservation_request_summary"
       }),
       do: true

  defp provider_reservation_request_summary?(_summary), do: false

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
         %{"schema_contract" => "contact_allocation_report.v1"} = report,
         source
       ) do
    source_report_rows(report, source)
  end

  defp result_artifact_rows(
         %{"schema_contract" => schema_contract} = summary,
         source
       )
       when schema_contract in [
              "contact_allocation_summary.v1",
              "contact_allocation_station_pressure_summary.v1",
              "contact_allocation_reservation_conflict_summary.v1",
              "contact_allocation_capacity_pack_summary.v1",
              "contact_allocation_provider_reservation_request_summary.v1"
            ] do
    source_report_rows(summary, source)
  end

  defp result_artifact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_contact_allocation_report",
       artifact["source_contact_allocation_report"]},
      {"#{source}.contact_allocation_report", artifact["contact_allocation_report"]},
      {"#{source}.source_contact_allocation_summary",
       artifact["source_contact_allocation_summary"]},
      {"#{source}.contact_allocation_summary", artifact["contact_allocation_summary"]},
      {"#{source}.source_contact_allocation_station_pressure_summary",
       artifact["source_contact_allocation_station_pressure_summary"]},
      {"#{source}.contact_allocation_station_pressure_summary",
       artifact["contact_allocation_station_pressure_summary"]},
      {"#{source}.source_contact_allocation_reservation_conflict_summary",
       artifact["source_contact_allocation_reservation_conflict_summary"]},
      {"#{source}.contact_allocation_reservation_conflict_summary",
       artifact["contact_allocation_reservation_conflict_summary"]},
      {"#{source}.source_contact_allocation_capacity_pack_summary",
       artifact["source_contact_allocation_capacity_pack_summary"]},
      {"#{source}.contact_allocation_capacity_pack_summary",
       artifact["contact_allocation_capacity_pack_summary"]},
      {"#{source}.source_contact_allocation_provider_reservation_request_summary",
       artifact["source_contact_allocation_provider_reservation_request_summary"]},
      {"#{source}.contact_allocation_provider_reservation_request_summary",
       artifact["contact_allocation_provider_reservation_request_summary"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_rows(_artifact, _source), do: []

  defp put_contact_allocation_capacity_pack_direction_summary(%{} = group) do
    rows =
      group
      |> Map.get("capacity_requirement_rows", [])
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)

    contact_directions = contact_allocation_capacity_pack_contact_directions(group, rows)

    routed_rows =
      rows
      |> Enum.map(fn row ->
        direction = row["direction"] || contact_directions[row["contact_id"]]

        row
        |> Map.put("direction", direction)
        |> compact_map()
      end)
      |> Enum.filter(&(is_binary(&1["contact_id"]) and is_binary(&1["direction"])))

    if routed_rows == [] do
      group
    else
      selected_rows =
        Enum.filter(routed_rows, &(&1["allocation_status"] == "allocated"))

      deferred_rows =
        Enum.filter(routed_rows, &(&1["allocation_status"] == "deferred"))

      Map.merge(group, %{
        "capacity_pack_contact_ids_by_direction" =>
          contact_allocation_capacity_pack_contact_ids_by_direction(routed_rows),
        "capacity_pack_selected_contact_ids_by_direction" =>
          contact_allocation_capacity_pack_contact_ids_by_direction(selected_rows),
        "capacity_pack_deferred_contact_ids_by_direction" =>
          contact_allocation_capacity_pack_contact_ids_by_direction(deferred_rows),
        "capacity_pack_required_capacity_fraction_by_direction" =>
          contact_allocation_capacity_pack_required_fraction_by_direction(routed_rows),
        "capacity_pack_selected_required_capacity_fraction_by_direction" =>
          contact_allocation_capacity_pack_required_fraction_by_direction(selected_rows),
        "capacity_pack_deferred_required_capacity_fraction_by_direction" =>
          contact_allocation_capacity_pack_required_fraction_by_direction(deferred_rows)
      })
    end
  end

  defp put_contact_allocation_capacity_pack_direction_summary(group), do: group

  defp contact_allocation_capacity_pack_contact_directions(%{} = group, rows) do
    fallback_direction =
      cond do
        is_binary(group["direction"]) ->
          group["direction"]

        match?([direction] when is_binary(direction), List.wrap(group["directions"])) ->
          List.first(group["directions"])

        true ->
          nil
      end

    group_candidate_directions =
      group
      |> Map.get("source_contact_candidates", [])
      |> contact_allocation_capacity_pack_candidate_directions()

    recommendation_candidate_directions =
      group
      |> get_in(["source_contention_recommendation", "source_contact_candidates"])
      |> contact_allocation_capacity_pack_candidate_directions()

    row_directions =
      rows
      |> Enum.filter(&(is_binary(&1["contact_id"]) and is_binary(&1["direction"])))
      |> Map.new(&{&1["contact_id"], &1["direction"]})

    fallback_directions =
      rows
      |> Enum.filter(&(is_binary(&1["contact_id"]) and is_binary(fallback_direction)))
      |> Map.new(&{&1["contact_id"], fallback_direction})

    fallback_directions
    |> Map.merge(group_candidate_directions)
    |> Map.merge(recommendation_candidate_directions)
    |> Map.merge(row_directions)
  end

  defp contact_allocation_capacity_pack_candidate_directions(candidates) do
    candidates
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&(is_binary(&1["id"]) and is_binary(&1["direction"])))
    |> Map.new(&{&1["id"], &1["direction"]})
  end

  defp contact_allocation_capacity_pack_contact_ids_by_direction(rows) do
    rows
    |> Enum.group_by(& &1["direction"], & &1["contact_id"])
    |> Map.new(fn {direction, contact_ids} ->
      {direction, contact_ids |> Enum.uniq() |> Enum.sort()}
    end)
  end

  defp contact_allocation_capacity_pack_required_fraction_by_direction(rows) do
    rows
    |> Enum.reduce(%{}, fn row, acc ->
      case {row["direction"], row["required_capacity_fraction"]} do
        {direction, fraction} when is_binary(direction) and is_number(fraction) ->
          Map.update(acc, direction, fraction, &(&1 + fraction))

        _row_without_fraction ->
          acc
      end
    end)
    |> Map.new(fn {direction, fraction} -> {direction, Float.round(fraction, 10)} end)
  end

  defp contact_allocation_capacity_pack_reason(%{
         "contention_group_id" => group_id,
         "ground_station_id" => station_id,
         "pack_status" => status
       }) do
    "review #{status} reduced-capacity contact packing for #{station_id} group #{group_id}"
  end

  defp contact_allocation_capacity_pack_reason(_group) do
    "review reduced-capacity contact packing group"
  end

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
    |> String.trim()
    |> case do
      "" -> []
      value -> [value]
    end
  end

  defp provider_result_values(values) when is_list(values) do
    values
    |> Enum.flat_map(&provider_result_values/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
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
       when is_integer(result) or is_float(result) or is_boolean(result),
       do: [encode_value(result)]

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

  defp package(rows, source_artifact_type, source_artifact_id, provenance) do
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
