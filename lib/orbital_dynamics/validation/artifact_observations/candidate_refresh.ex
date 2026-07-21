defmodule OrbitalDynamics.Validation.ArtifactObservations.CandidateRefresh do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    candidate_activities = map_rows(artifact, "candidate_activities")
    contact_intents = map_rows(artifact, "contact_intents")
    invalidated_candidates = map_rows(artifact, "invalidated_candidates")
    candidate_rejection_report = map_field(artifact, "candidate_rejection_report")
    candidate_rejection_rows = map_rows(candidate_rejection_report, "rows")

    contact_allocation_candidate_filter_rows =
      candidate_filter_provenance_rows(
        candidate_rejection_rows,
        "contact_allocation_candidate_filter"
      )

    operational_readiness_candidate_filter_rows =
      candidate_filter_provenance_rows(
        candidate_rejection_rows,
        "operational_readiness_candidate_filter"
      )

    source_reports = get_in(artifact, ["provenance", "source_reports"]) || %{}
    candidate_rejection_summary = Map.get(source_reports, "candidate_rejection_report") || %{}
    contact_contention_summary = Map.get(source_reports, "contact_contention_report") || %{}
    contact_allocation_summary = Map.get(source_reports, "contact_allocation_report") || %{}
    contact_filter_summary = Map.get(source_reports, "contact_filter_report") || %{}
    contact_intent_summary = Map.get(source_reports, "contact_intent") || %{}
    constraint_summary = Map.get(source_reports, "constraint_report") || %{}
    freshness_summary = Map.get(source_reports, "freshness_report") || %{}
    link_capacity_summary = Map.get(source_reports, "link_capacity_report") || %{}
    refresh_budget_summary = Map.get(source_reports, "refresh_budget_report") || %{}
    resource_filter_summary = Map.get(source_reports, "resource_filter_report") || %{}

    objective_satisfaction_summary =
      Map.get(source_reports, "objective_satisfaction_report") || %{}

    objective_tradeoff_summary = Map.get(source_reports, "objective_tradeoff_report") || %{}
    score_term_summary = Map.get(source_reports, "score_term_report") || %{}
    station_calendar_summary = Map.get(source_reports, "station_calendar_report") || %{}
    resource_projection_summary = Map.get(source_reports, "resource_projection_report") || %{}
    quality_gate_summary = Map.get(source_reports, "quality_gate_report") || %{}

    operational_readiness_summary =
      Map.get(source_reports, "operational_readiness_report") || %{}

    timeline_activity_precondition_summary =
      Map.get(source_reports, "timeline_activity_precondition_summary") || %{}

    timeline_activity_lifecycle_summary =
      Map.get(source_reports, "timeline_activity_lifecycle_state") || %{}

    timeline_lifecycle_state_summary =
      Map.get(source_reports, "timeline_lifecycle_state_summary") || %{}

    timeline_transition_summary =
      Map.get(source_reports, "timeline_transition_application_report") || %{}

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "schema_version" => Map.get(artifact, "schema_version"),
      "planner" => Map.get(artifact, "planner"),
      "candidate_count" => length(candidate_activities),
      "candidate_activity_id_keys" => optional_row_id_keys(candidate_activities, "id"),
      "contact_intent_count" => length(contact_intents),
      "contact_intent_activity_id_keys" => optional_row_id_keys(contact_intents, "activity_id"),
      "candidate_rejection_report_count" => if(map_size(candidate_rejection_report) > 0, do: 1),
      "candidate_rejection_candidate_count" =>
        Map.get(candidate_rejection_report, "candidate_count"),
      "candidate_rejection_rejected_count" =>
        Map.get(candidate_rejection_report, "rejected_count"),
      "candidate_rejection_rejected_candidate_id_keys" =>
        candidate_rejection_report
        |> list_values("rejected_candidate_ids")
        |> optional_stable_id_keys(),
      "candidate_rejection_reason_counts" =>
        Map.get(candidate_rejection_report, "rejection_reason_counts") || %{},
      "candidate_rejection_source" => Map.get(candidate_rejection_report, "source"),
      "candidate_rejection_operational_readiness_filter_candidate_id_keys" =>
        candidate_filter_candidate_id_keys(operational_readiness_candidate_filter_rows),
      "candidate_rejection_operational_readiness_filter_source_schema_contract_keys" =>
        candidate_filter_provenance_keys(
          operational_readiness_candidate_filter_rows,
          "source_schema_contract"
        ),
      "candidate_rejection_operational_readiness_filter_source_report_path_keys" =>
        candidate_filter_provenance_keys(
          operational_readiness_candidate_filter_rows,
          "source_report_paths"
        ),
      "candidate_rejection_operational_readiness_filter_source_artifact_type_keys" =>
        candidate_filter_provenance_keys(
          operational_readiness_candidate_filter_rows,
          "source_artifact_types"
        ),
      "candidate_rejection_operational_readiness_filter_source_artifact_id_keys" =>
        candidate_filter_provenance_keys(
          operational_readiness_candidate_filter_rows,
          "source_artifact_ids"
        ),
      "candidate_rejection_operational_readiness_filter_source_report_id_keys" =>
        candidate_filter_provenance_keys(
          operational_readiness_candidate_filter_rows,
          "source_readiness_report_ids"
        ),
      "candidate_rejection_operational_readiness_filter_status_keys" =>
        candidate_filter_provenance_keys(
          operational_readiness_candidate_filter_rows,
          "operational_readiness_statuses"
        ),
      "candidate_rejection_operational_readiness_filter_selection_scope_keys" =>
        candidate_filter_provenance_keys(
          operational_readiness_candidate_filter_rows,
          "selection_scopes"
        ),
      "candidate_rejection_operational_readiness_filter_trust_boundary_keys" =>
        candidate_filter_provenance_keys(
          operational_readiness_candidate_filter_rows,
          "trust_boundaries"
        ),
      "candidate_rejection_contact_allocation_filter_candidate_id_keys" =>
        candidate_filter_candidate_id_keys(contact_allocation_candidate_filter_rows),
      "candidate_rejection_contact_allocation_filter_source_schema_contract_keys" =>
        candidate_filter_provenance_keys(
          contact_allocation_candidate_filter_rows,
          "source_schema_contract"
        ),
      "candidate_rejection_contact_allocation_filter_source_report_path_keys" =>
        candidate_filter_provenance_keys(
          contact_allocation_candidate_filter_rows,
          "source_report_paths"
        ),
      "candidate_rejection_contact_allocation_filter_source_artifact_id_keys" =>
        candidate_filter_provenance_keys(
          contact_allocation_candidate_filter_rows,
          "source_artifact_ids"
        ),
      "candidate_rejection_contact_allocation_filter_source_report_id_keys" =>
        candidate_filter_provenance_keys(
          contact_allocation_candidate_filter_rows,
          "source_contact_allocation_report_ids"
        ),
      "candidate_rejection_contact_allocation_filter_source_report_source_keys" =>
        candidate_filter_provenance_keys(
          contact_allocation_candidate_filter_rows,
          "source_report_sources"
        ),
      "candidate_rejection_contact_allocation_filter_resource_blocking_dimension_keys" =>
        candidate_filter_provenance_keys(
          contact_allocation_candidate_filter_rows,
          "resource_blocking_dimensions"
        ),
      "candidate_rejection_contact_allocation_filter_blocked_spacecraft_id_keys" =>
        candidate_filter_provenance_keys(
          contact_allocation_candidate_filter_rows,
          "blocked_spacecraft_ids"
        ),
      "candidate_rejection_contact_allocation_filter_trust_boundary_keys" =>
        candidate_filter_provenance_keys(
          contact_allocation_candidate_filter_rows,
          "trust_boundaries"
        ),
      "invalidated_candidate_count" =>
        if(invalidated_candidates != [], do: length(invalidated_candidates)),
      "invalidated_candidate_id_keys" => optional_row_id_keys(invalidated_candidates, "id"),
      "invalidated_candidate_reason_counts" =>
        count_rows_by_value(invalidated_candidates, "invalidated_reason"),
      "access_window_count" =>
        count(get_in(artifact, ["refreshed_windows"]) || %{}, "access_windows"),
      "target_visibility_window_count" =>
        count(get_in(artifact, ["refreshed_windows"]) || %{}, "target_visibility_windows"),
      "eclipse_interval_count" =>
        count(get_in(artifact, ["refreshed_windows"]) || %{}, "eclipse_intervals"),
      "warning_count" => count(artifact, "warnings"),
      "source_report_family_count" => map_size(source_reports),
      "source_report_row_count" => candidate_refresh_source_report_row_count(source_reports),
      "source_contact_contention_report_count" => Map.get(contact_contention_summary, "count"),
      "source_contact_contention_row_count" => Map.get(contact_contention_summary, "row_count"),
      "source_contact_contention_conflict_group_count" =>
        Map.get(contact_contention_summary, "conflict_group_count"),
      "source_contact_contention_invalid_contact_input_count" =>
        Map.get(contact_contention_summary, "invalid_contact_input_count"),
      "source_contact_contention_resource_scope_counts" =>
        Map.get(contact_contention_summary, "resource_scope_counts") || %{},
      "source_contact_contention_direction_counts" =>
        Map.get(contact_contention_summary, "direction_counts") || %{},
      "source_contact_contention_contact_ids_by_direction" =>
        Map.get(contact_contention_summary, "contact_ids_by_direction") || %{},
      "source_contact_contention_required_operator_action_counts" =>
        Map.get(contact_contention_summary, "required_operator_action_counts") || %{},
      "source_contact_contention_trust_boundary_status" =>
        Map.get(contact_contention_summary, "trust_boundary_status"),
      "source_contact_allocation_report_count" => Map.get(contact_allocation_summary, "count"),
      "source_contact_allocation_row_count" => Map.get(contact_allocation_summary, "row_count"),
      "source_contact_allocation_path_keys" =>
        contact_allocation_summary
        |> list_values("paths")
        |> Enum.join("|")
        |> normalize_optional_string(),
      "source_contact_allocation_source_summary_schema_contract_counts" =>
        Map.get(contact_allocation_summary, "source_summary_schema_contract_counts") || %{},
      "source_contact_allocation_resource_blocked_contact_count" =>
        Map.get(contact_allocation_summary, "resource_blocked_contact_count"),
      "source_contact_allocation_resource_blocking_dimension_counts" =>
        Map.get(contact_allocation_summary, "resource_blocking_dimension_counts") || %{},
      "source_contact_allocation_resource_blocked_contact_ids_by_blocking_dimension" =>
        Map.get(
          contact_allocation_summary,
          "resource_blocked_contact_ids_by_blocking_dimension"
        ) || %{},
      "source_contact_allocation_resource_blocked_contact_ids_by_spacecraft" =>
        Map.get(contact_allocation_summary, "resource_blocked_contact_ids_by_spacecraft") ||
          %{},
      "source_contact_allocation_trust_boundary_status" =>
        Map.get(contact_allocation_summary, "trust_boundary_status"),
      "source_contact_allocation_reservation_conflict_contact_count" =>
        Map.get(contact_allocation_summary, "reservation_conflict_contact_count"),
      "source_contact_allocation_reservation_conflict_match_status_counts" =>
        Map.get(contact_allocation_summary, "reservation_conflict_match_status_counts") || %{},
      "source_contact_allocation_reservation_conflict_contact_ids_by_direction_and_ground_station" =>
        Map.get(
          contact_allocation_summary,
          "reservation_conflict_contact_ids_by_direction_and_ground_station"
        ) || %{},
      "source_contact_allocation_station_reservation_expiration_status_counts" =>
        Map.get(contact_allocation_summary, "station_reservation_expiration_status_counts") ||
          %{},
      "source_contact_allocation_provider_reservation_request_contact_count" =>
        Map.get(contact_allocation_summary, "provider_reservation_request_contact_count"),
      "source_contact_allocation_provider_reservation_review_contact_count" =>
        Map.get(contact_allocation_summary, "provider_reservation_review_contact_count"),
      "source_contact_allocation_provider_reservation_no_request_contact_count" =>
        Map.get(contact_allocation_summary, "provider_reservation_no_request_contact_count"),
      "source_contact_allocation_provider_reservation_request_status_counts" =>
        Map.get(contact_allocation_summary, "provider_reservation_request_status_counts") || %{},
      "source_contact_allocation_provider_reservation_request_contact_ids_by_direction_and_ground_station" =>
        Map.get(
          contact_allocation_summary,
          "provider_reservation_request_contact_ids_by_direction_and_ground_station"
        ) || %{},
      "source_contact_allocation_provider_reservation_review_contact_ids_by_direction_and_ground_station" =>
        Map.get(
          contact_allocation_summary,
          "provider_reservation_review_contact_ids_by_direction_and_ground_station"
        ) || %{},
      "source_contact_allocation_branch_local_reservation_conflict_pressure" =>
        positive_integer_observation?(
          contact_allocation_summary,
          "reservation_conflict_contact_count"
        ),
      "source_contact_allocation_branch_local_provider_reservation_request_pressure" =>
        positive_integer_observation?(
          contact_allocation_summary,
          "provider_reservation_request_contact_count"
        ) or
          positive_integer_observation?(
            contact_allocation_summary,
            "provider_reservation_review_contact_count"
          ),
      "source_contact_filter_report_count" => Map.get(contact_filter_summary, "count"),
      "source_contact_filter_row_count" => Map.get(contact_filter_summary, "row_count"),
      "source_contact_filter_suppressed_candidate_count" =>
        Map.get(contact_filter_summary, "suppressed_candidate_count"),
      "source_contact_filter_invalid_contact_input_count" =>
        Map.get(contact_filter_summary, "invalid_contact_input_count"),
      "source_contact_filter_invalid_contact_input_ids" =>
        Map.get(contact_filter_summary, "invalid_contact_input_ids") || [],
      "source_contact_filter_suppressed_reason_counts" =>
        Map.get(contact_filter_summary, "suppressed_reason_counts") || %{},
      "source_contact_filter_contact_ids_by_suppressed_reason" =>
        Map.get(contact_filter_summary, "contact_ids_by_suppressed_reason") || %{},
      "source_contact_filter_direction_counts" =>
        Map.get(contact_filter_summary, "direction_counts") || %{},
      "source_contact_filter_directions" => Map.get(contact_filter_summary, "directions") || [],
      "source_contact_filter_contact_ids_by_direction" =>
        Map.get(contact_filter_summary, "contact_ids_by_direction") || %{},
      "source_contact_filter_direction_routing" =>
        Map.get(contact_filter_summary, "direction_routing") || %{},
      "source_contact_filter_station_suppression_count" =>
        Map.get(contact_filter_summary, "station_suppression_count"),
      "source_contact_filter_station_suppression_ground_station_counts" =>
        Map.get(contact_filter_summary, "station_suppression_ground_station_counts") || %{},
      "source_contact_filter_station_suppression_availability_counts" =>
        Map.get(contact_filter_summary, "station_suppression_availability_counts") || %{},
      "source_contact_filter_station_suppression_status_counts" =>
        Map.get(contact_filter_summary, "station_suppression_status_counts") || %{},
      "source_contact_filter_station_suppression_contact_ids_by_ground_station" =>
        Map.get(contact_filter_summary, "station_suppression_contact_ids_by_ground_station") ||
          %{},
      "source_contact_filter_station_suppression_contact_ids_by_availability" =>
        Map.get(contact_filter_summary, "station_suppression_contact_ids_by_availability") ||
          %{},
      "source_contact_filter_station_suppression_contact_ids_by_status" =>
        Map.get(contact_filter_summary, "station_suppression_contact_ids_by_status") || %{},
      "source_contact_filter_station_suppression_station_calendar_entry_ids_by_ground_station" =>
        Map.get(
          contact_filter_summary,
          "station_suppression_station_calendar_entry_ids_by_ground_station"
        ) || %{},
      "source_contact_filter_station_suppression_station_calendar_entry_ids_by_availability" =>
        Map.get(
          contact_filter_summary,
          "station_suppression_station_calendar_entry_ids_by_availability"
        ) || %{},
      "source_contact_filter_station_suppression_station_calendar_entry_ids_by_status" =>
        Map.get(
          contact_filter_summary,
          "station_suppression_station_calendar_entry_ids_by_status"
        ) || %{},
      "source_contact_filter_station_suppression_station_calendar_provider_entry_ids_by_ground_station" =>
        Map.get(
          contact_filter_summary,
          "station_suppression_station_calendar_provider_entry_ids_by_ground_station"
        ) || %{},
      "source_contact_filter_station_suppression_station_calendar_provider_entry_ids_by_availability" =>
        Map.get(
          contact_filter_summary,
          "station_suppression_station_calendar_provider_entry_ids_by_availability"
        ) || %{},
      "source_contact_filter_station_suppression_station_calendar_provider_entry_ids_by_status" =>
        Map.get(
          contact_filter_summary,
          "station_suppression_station_calendar_provider_entry_ids_by_status"
        ) || %{},
      "source_contact_filter_station_suppression_station_reservation_ids_by_ground_station" =>
        Map.get(
          contact_filter_summary,
          "station_suppression_station_reservation_ids_by_ground_station"
        ) || %{},
      "source_contact_filter_station_suppression_station_reservation_ids_by_availability" =>
        Map.get(
          contact_filter_summary,
          "station_suppression_station_reservation_ids_by_availability"
        ) || %{},
      "source_contact_filter_station_suppression_station_reservation_ids_by_status" =>
        Map.get(
          contact_filter_summary,
          "station_suppression_station_reservation_ids_by_status"
        ) || %{},
      "source_contact_filter_trust_boundary_status" =>
        Map.get(contact_filter_summary, "trust_boundary_status"),
      "source_contact_filter_branch_local_contact_filter_pressure" =>
        contact_filter_branch_local_contact_filter_pressure?(contact_filter_summary),
      "source_contact_filter_branch_local_candidate_suppression_pressure" =>
        contact_filter_branch_local_candidate_suppression_pressure?(contact_filter_summary),
      "source_contact_filter_branch_local_invalid_contact_input_pressure" =>
        contact_filter_branch_local_invalid_contact_input_pressure?(contact_filter_summary),
      "source_contact_filter_branch_local_station_suppression_pressure" =>
        contact_filter_branch_local_station_suppression_pressure?(contact_filter_summary),
      "source_candidate_rejection_report_count" => Map.get(candidate_rejection_summary, "count"),
      "source_candidate_rejection_row_count" => Map.get(candidate_rejection_summary, "row_count"),
      "source_candidate_rejection_rejected_count" =>
        Map.get(candidate_rejection_summary, "rejected_count"),
      "source_candidate_rejection_reviewable_count" =>
        Map.get(candidate_rejection_summary, "reviewable_count"),
      "source_candidate_rejection_invalid_candidate_input_count" =>
        Map.get(candidate_rejection_summary, "invalid_candidate_input_count"),
      "source_candidate_rejection_rejection_reason_counts" =>
        Map.get(candidate_rejection_summary, "rejection_reason_counts") || %{},
      "source_candidate_rejection_required_operator_action_counts" =>
        Map.get(candidate_rejection_summary, "required_operator_action_counts") || %{},
      "source_candidate_rejection_candidate_id_counts" =>
        Map.get(candidate_rejection_summary, "candidate_rejection_candidate_id_counts") || %{},
      "source_candidate_rejection_ground_station_counts" =>
        Map.get(candidate_rejection_summary, "candidate_rejection_ground_station_counts") || %{},
      "source_candidate_rejection_trust_boundary_status" =>
        Map.get(candidate_rejection_summary, "trust_boundary_status"),
      "source_candidate_rejection_branch_local_rejection_pressure" =>
        candidate_rejection_branch_local_rejection_pressure?(candidate_rejection_summary),
      "source_candidate_rejection_branch_local_review_pressure" =>
        candidate_rejection_branch_local_review_pressure?(candidate_rejection_summary),
      "source_candidate_rejection_branch_local_invalid_input_pressure" =>
        candidate_rejection_branch_local_invalid_input_pressure?(candidate_rejection_summary),
      "source_freshness_report_count" => Map.get(freshness_summary, "count"),
      "source_freshness_row_count" => Map.get(freshness_summary, "row_count"),
      "source_freshness_path_keys" =>
        freshness_summary
        |> list_values("paths")
        |> Enum.join("|")
        |> normalize_optional_string(),
      "source_freshness_status_counts" => Map.get(freshness_summary, "status_counts") || %{},
      "source_freshness_stale_reason_count" => Map.get(freshness_summary, "stale_reason_count"),
      "source_freshness_stale_reason_keys" =>
        freshness_summary
        |> list_values("stale_reasons")
        |> Enum.join("|")
        |> normalize_optional_string(),
      "source_freshness_stale_reason_counts" =>
        Map.get(freshness_summary, "stale_reason_counts") || %{},
      "source_freshness_unknown_reason_count" =>
        Map.get(freshness_summary, "unknown_reason_count"),
      "source_freshness_unknown_reason_keys" =>
        freshness_summary
        |> list_values("unknown_reasons")
        |> Enum.join("|")
        |> normalize_optional_string(),
      "source_freshness_unknown_reason_counts" =>
        Map.get(freshness_summary, "unknown_reason_counts") || %{},
      "source_freshness_trust_boundary_status" =>
        Map.get(freshness_summary, "trust_boundary_status"),
      "source_freshness_branch_local_stale_pressure" =>
        freshness_branch_local_stale_pressure?(freshness_summary),
      "source_freshness_branch_local_unknown_pressure" =>
        freshness_branch_local_unknown_pressure?(freshness_summary),
      "source_freshness_branch_local_freshness_pressure" =>
        freshness_branch_local_freshness_pressure?(freshness_summary),
      "source_refresh_budget_report_count" => Map.get(refresh_budget_summary, "count"),
      "source_refresh_budget_row_count" => Map.get(refresh_budget_summary, "row_count"),
      "source_refresh_budget_path_keys" =>
        refresh_budget_summary
        |> list_values("paths")
        |> Enum.join("|")
        |> normalize_optional_string(),
      "source_refresh_budget_input_candidate_count" =>
        Map.get(refresh_budget_summary, "input_candidate_count"),
      "source_refresh_budget_kept_candidate_count" =>
        Map.get(refresh_budget_summary, "kept_candidate_count"),
      "source_refresh_budget_dropped_candidate_count" =>
        Map.get(refresh_budget_summary, "dropped_candidate_count"),
      "source_refresh_budget_invalid_candidate_limit_policy_count" =>
        Map.get(refresh_budget_summary, "invalid_candidate_limit_policy_count"),
      "source_refresh_budget_invalid_candidate_limit_policy_reason_counts" =>
        Map.get(refresh_budget_summary, "invalid_candidate_limit_policy_reason_counts") || %{},
      "source_refresh_budget_kept_candidate_id_keys" =>
        refresh_budget_summary
        |> list_values("kept_candidate_ids")
        |> Enum.join("|")
        |> normalize_optional_string(),
      "source_refresh_budget_dropped_candidate_id_keys" =>
        refresh_budget_summary
        |> list_values("dropped_candidate_ids")
        |> Enum.join("|")
        |> normalize_optional_string(),
      "source_refresh_budget_trust_boundary_status" =>
        Map.get(refresh_budget_summary, "trust_boundary_status"),
      "source_refresh_budget_branch_local_budget_pressure" =>
        refresh_budget_branch_local_budget_pressure?(refresh_budget_summary),
      "source_refresh_budget_branch_local_dropped_candidate_pressure" =>
        refresh_budget_branch_local_dropped_candidate_pressure?(refresh_budget_summary),
      "source_refresh_budget_branch_local_invalid_limit_pressure" =>
        refresh_budget_branch_local_invalid_limit_pressure?(refresh_budget_summary),
      "source_refresh_budget_branch_local_candidate_limit_applied" =>
        refresh_budget_branch_local_candidate_limit_applied?(refresh_budget_summary),
      "source_station_calendar_report_count" => Map.get(station_calendar_summary, "count"),
      "source_station_calendar_row_count" => Map.get(station_calendar_summary, "row_count"),
      "source_station_calendar_path_keys" =>
        station_calendar_summary
        |> list_values("paths")
        |> Enum.join("|")
        |> normalize_optional_string(),
      "source_station_calendar_affected_contact_count" =>
        Map.get(station_calendar_summary, "affected_contact_count"),
      "source_station_calendar_provider_calendar_contention_group_count" =>
        Map.get(station_calendar_summary, "provider_calendar_contention_group_count"),
      "source_station_calendar_provider_calendar_contention_group_id_keys" =>
        station_calendar_summary
        |> list_values("provider_calendar_contention_group_ids")
        |> Enum.join("|")
        |> normalize_optional_string(),
      "source_station_calendar_provider_calendar_contention_source_entry_id_keys" =>
        station_calendar_summary
        |> list_values("provider_calendar_contention_source_entry_ids")
        |> Enum.join("|")
        |> normalize_optional_string(),
      "source_station_calendar_provider_calendar_contention_provider_entry_id_keys" =>
        station_calendar_summary
        |> list_values("provider_calendar_contention_provider_entry_ids")
        |> Enum.join("|")
        |> normalize_optional_string(),
      "source_station_calendar_provider_calendar_contention_provider_counts" =>
        Map.get(station_calendar_summary, "provider_calendar_contention_provider_counts") || %{},
      "source_station_calendar_provider_calendar_contention_ground_station_counts" =>
        Map.get(station_calendar_summary, "provider_calendar_contention_ground_station_counts") ||
          %{},
      "source_station_calendar_provider_calendar_contention_direction_counts" =>
        Map.get(station_calendar_summary, "provider_calendar_contention_direction_counts") || %{},
      "source_station_calendar_provider_calendar_contention_minimum_capacity_fraction" =>
        Map.get(
          station_calendar_summary,
          "provider_calendar_contention_minimum_capacity_fraction"
        ),
      "source_station_calendar_affected_contact_ground_station_counts" =>
        Map.get(station_calendar_summary, "affected_contact_ground_station_counts") || %{},
      "source_station_calendar_affected_contact_availability_counts" =>
        Map.get(station_calendar_summary, "affected_contact_availability_counts") || %{},
      "source_station_calendar_direction_counts" =>
        Map.get(station_calendar_summary, "direction_counts") || %{},
      "source_station_calendar_status_counts" =>
        Map.get(station_calendar_summary, "station_calendar_status_counts") || %{},
      "source_station_calendar_trust_boundary_status" =>
        Map.get(station_calendar_summary, "trust_boundary_status"),
      "source_station_calendar_branch_local_station_calendar_pressure" =>
        station_calendar_branch_local_station_calendar_pressure?(station_calendar_summary),
      "source_station_calendar_branch_local_affected_contact_pressure" =>
        station_calendar_branch_local_affected_contact_pressure?(station_calendar_summary),
      "source_station_calendar_branch_local_provider_contention_pressure" =>
        station_calendar_branch_local_provider_contention_pressure?(station_calendar_summary),
      "source_station_calendar_branch_local_station_availability_pressure" =>
        station_calendar_branch_local_station_availability_pressure?(station_calendar_summary),
      "source_contact_intent_report_count" => Map.get(contact_intent_summary, "count"),
      "source_contact_intent_row_count" => Map.get(contact_intent_summary, "row_count"),
      "source_contact_intent_station_feedback_count" =>
        Map.get(contact_intent_summary, "station_feedback_count"),
      "source_contact_intent_capacity_pack_required_contact_count" =>
        Map.get(contact_intent_summary, "capacity_pack_required_contact_count"),
      "source_contact_intent_capacity_pack_required_capacity_fraction" =>
        Map.get(contact_intent_summary, "capacity_pack_required_capacity_fraction"),
      "source_contact_intent_capacity_pack_required_capacity_fraction_by_direction" =>
        Map.get(contact_intent_summary, "capacity_pack_required_capacity_fraction_by_direction") ||
          %{},
      "source_contact_intent_capacity_pack_required_capacity_fraction_by_direction_and_ground_station" =>
        Map.get(
          contact_intent_summary,
          "capacity_pack_required_capacity_fraction_by_direction_and_ground_station"
        ) || %{},
      "source_contact_intent_capacity_pack_contact_ids_by_direction" =>
        Map.get(contact_intent_summary, "capacity_pack_contact_ids_by_direction") || %{},
      "source_contact_intent_capacity_pack_contact_ids_by_direction_and_ground_station" =>
        Map.get(
          contact_intent_summary,
          "capacity_pack_contact_ids_by_direction_and_ground_station"
        ) ||
          %{},
      "source_contact_intent_direction_keys" =>
        contact_intent_summary
        |> list_values("directions")
        |> Enum.join("|")
        |> normalize_optional_string(),
      "source_contact_intent_direction_counts" =>
        Map.get(contact_intent_summary, "direction_counts") || %{},
      "source_contact_intent_contact_ids_by_direction" =>
        Map.get(contact_intent_summary, "contact_ids_by_direction") || %{},
      "source_contact_intent_contact_ids_by_direction_and_ground_station" =>
        Map.get(contact_intent_summary, "contact_ids_by_direction_and_ground_station") || %{},
      "source_contact_intent_direction_routing" =>
        Map.get(contact_intent_summary, "direction_routing") || %{},
      "source_contact_intent_trust_boundary_status" =>
        Map.get(contact_intent_summary, "trust_boundary_status"),
      "source_constraint_report_count" => Map.get(constraint_summary, "count"),
      "source_constraint_row_count" => Map.get(constraint_summary, "row_count"),
      "source_constraint_downlink_gap_row_count" =>
        Map.get(constraint_summary, "downlink_gap_row_count"),
      "source_constraint_resource_margin_row_count" =>
        Map.get(constraint_summary, "resource_margin_row_count"),
      "source_constraint_status_counts" => Map.get(constraint_summary, "status_counts") || %{},
      "source_constraint_ground_station_counts" =>
        Map.get(constraint_summary, "ground_station_counts") || %{},
      "source_constraint_metric_counts" =>
        Map.get(constraint_summary, "constraint_metric_counts") || %{},
      "source_constraint_id_counts" => Map.get(constraint_summary, "constraint_id_counts") || %{},
      "source_constraint_source_activity_id_counts" =>
        Map.get(constraint_summary, "source_activity_id_counts") || %{},
      "source_constraint_resource_counts" =>
        Map.get(constraint_summary, "constraint_resource_counts") || %{},
      "source_constraint_spacecraft_counts" =>
        Map.get(constraint_summary, "constraint_spacecraft_counts") || %{},
      "source_constraint_trust_boundary_status" =>
        Map.get(constraint_summary, "trust_boundary_status"),
      "source_constraint_branch_local_constraint_pressure" =>
        constraint_branch_local_constraint_pressure?(constraint_summary),
      "source_constraint_branch_local_downlink_gap_pressure" =>
        positive_integer_observation?(constraint_summary, "downlink_gap_row_count"),
      "source_constraint_branch_local_resource_margin_pressure" =>
        constraint_branch_local_resource_margin_pressure?(constraint_summary),
      "source_constraint_branch_local_constraint_routing_pressure" =>
        constraint_branch_local_routing_pressure?(constraint_summary),
      "source_link_capacity_report_count" => Map.get(link_capacity_summary, "count"),
      "source_link_capacity_row_count" => Map.get(link_capacity_summary, "row_count"),
      "source_link_capacity_selected_shortfall_row_count" =>
        Map.get(link_capacity_summary, "selected_shortfall_row_count"),
      "source_link_capacity_actual_shortfall_row_count" =>
        Map.get(link_capacity_summary, "actual_shortfall_row_count"),
      "source_link_capacity_actual_throughput_row_count" =>
        Map.get(link_capacity_summary, "actual_throughput_row_count"),
      "source_link_capacity_capacity_adjusted_throughput_row_count" =>
        Map.get(link_capacity_summary, "capacity_adjusted_throughput_row_count"),
      "source_link_capacity_capacity_adjusted_throughput_mb_total" =>
        Map.get(link_capacity_summary, "capacity_adjusted_throughput_mb_total"),
      "source_link_capacity_selected_capacity_adjusted_throughput_mb_total" =>
        Map.get(link_capacity_summary, "selected_capacity_adjusted_throughput_mb_total"),
      "source_link_capacity_unused_capacity_adjusted_throughput_mb_total" =>
        Map.get(link_capacity_summary, "unused_capacity_adjusted_throughput_mb_total"),
      "source_link_capacity_ground_station_counts" =>
        Map.get(link_capacity_summary, "ground_station_counts") || %{},
      "source_link_capacity_spacecraft_counts" =>
        Map.get(link_capacity_summary, "spacecraft_counts") || %{},
      "source_link_capacity_capacity_adjusted_throughput_mb_by_ground_station" =>
        Map.get(link_capacity_summary, "capacity_adjusted_throughput_mb_by_ground_station") ||
          %{},
      "source_link_capacity_selected_capacity_adjusted_throughput_mb_by_ground_station" =>
        Map.get(
          link_capacity_summary,
          "selected_capacity_adjusted_throughput_mb_by_ground_station"
        ) || %{},
      "source_link_capacity_unused_capacity_adjusted_throughput_mb_by_ground_station" =>
        Map.get(
          link_capacity_summary,
          "unused_capacity_adjusted_throughput_mb_by_ground_station"
        ) || %{},
      "source_link_capacity_capacity_adjusted_throughput_mb_by_direction" =>
        Map.get(link_capacity_summary, "capacity_adjusted_throughput_mb_by_direction") || %{},
      "source_link_capacity_selected_capacity_adjusted_throughput_mb_by_direction" =>
        Map.get(
          link_capacity_summary,
          "selected_capacity_adjusted_throughput_mb_by_direction"
        ) || %{},
      "source_link_capacity_unused_capacity_adjusted_throughput_mb_by_direction" =>
        Map.get(
          link_capacity_summary,
          "unused_capacity_adjusted_throughput_mb_by_direction"
        ) || %{},
      "source_link_capacity_direction_counts" =>
        Map.get(link_capacity_summary, "direction_counts") || %{},
      "source_link_capacity_directions" => Map.get(link_capacity_summary, "directions") || [],
      "source_link_capacity_contact_ids_by_direction" =>
        Map.get(link_capacity_summary, "contact_ids_by_direction") || %{},
      "source_link_capacity_source_window_ids_by_direction" =>
        Map.get(link_capacity_summary, "source_window_ids_by_direction") || %{},
      "source_link_capacity_station_calendar_entry_ids_by_direction" =>
        Map.get(link_capacity_summary, "station_calendar_entry_ids_by_direction") || %{},
      "source_link_capacity_station_calendar_provider_entry_ids_by_direction" =>
        Map.get(link_capacity_summary, "station_calendar_provider_entry_ids_by_direction") ||
          %{},
      "source_link_capacity_direction_routing" =>
        Map.get(link_capacity_summary, "direction_routing") || %{},
      "source_link_capacity_contact_ids_by_ground_station" =>
        Map.get(link_capacity_summary, "contact_ids_by_ground_station") || %{},
      "source_link_capacity_source_window_ids_by_ground_station" =>
        Map.get(link_capacity_summary, "source_window_ids_by_ground_station") || %{},
      "source_link_capacity_station_calendar_entry_ids_by_ground_station" =>
        Map.get(link_capacity_summary, "station_calendar_entry_ids_by_ground_station") || %{},
      "source_link_capacity_station_calendar_provider_entry_ids_by_ground_station" =>
        Map.get(link_capacity_summary, "station_calendar_provider_entry_ids_by_ground_station") ||
          %{},
      "source_link_capacity_contact_ids_by_spacecraft" =>
        Map.get(link_capacity_summary, "contact_ids_by_spacecraft") || %{},
      "source_link_capacity_source_window_ids_by_spacecraft" =>
        Map.get(link_capacity_summary, "source_window_ids_by_spacecraft") || %{},
      "source_link_capacity_station_calendar_entry_ids_by_spacecraft" =>
        Map.get(link_capacity_summary, "station_calendar_entry_ids_by_spacecraft") || %{},
      "source_link_capacity_station_calendar_provider_entry_ids_by_spacecraft" =>
        Map.get(link_capacity_summary, "station_calendar_provider_entry_ids_by_spacecraft") ||
          %{},
      "source_link_capacity_selected_contact_id_counts" =>
        Map.get(link_capacity_summary, "selected_contact_id_counts") || %{},
      "source_link_capacity_selected_contact_ids" =>
        Map.get(link_capacity_summary, "selected_contact_ids") || [],
      "source_link_capacity_selected_source_window_ids" =>
        Map.get(link_capacity_summary, "selected_source_window_ids") || [],
      "source_link_capacity_selected_station_calendar_entry_ids" =>
        Map.get(link_capacity_summary, "selected_station_calendar_entry_ids") || [],
      "source_link_capacity_selected_station_calendar_provider_entry_ids" =>
        Map.get(link_capacity_summary, "selected_station_calendar_provider_entry_ids") || [],
      "source_link_capacity_actual_throughput_contact_id_counts" =>
        Map.get(link_capacity_summary, "actual_throughput_contact_id_counts") || %{},
      "source_link_capacity_actual_throughput_contact_ids" =>
        Map.get(link_capacity_summary, "actual_throughput_contact_ids") || [],
      "source_link_capacity_actual_throughput_source_window_ids" =>
        Map.get(link_capacity_summary, "actual_throughput_source_window_ids") || [],
      "source_link_capacity_actual_throughput_station_calendar_entry_ids" =>
        Map.get(link_capacity_summary, "actual_throughput_station_calendar_entry_ids") || [],
      "source_link_capacity_actual_throughput_station_calendar_provider_entry_ids" =>
        Map.get(link_capacity_summary, "actual_throughput_station_calendar_provider_entry_ids") ||
          [],
      "source_link_capacity_downlink_requirement_status_counts" =>
        Map.get(link_capacity_summary, "downlink_requirement_status_counts") || %{},
      "source_link_capacity_contact_ids_by_requirement_status" =>
        Map.get(link_capacity_summary, "contact_ids_by_requirement_status") || %{},
      "source_link_capacity_source_window_ids_by_requirement_status" =>
        Map.get(link_capacity_summary, "source_window_ids_by_requirement_status") || %{},
      "source_link_capacity_station_calendar_entry_ids_by_requirement_status" =>
        Map.get(link_capacity_summary, "station_calendar_entry_ids_by_requirement_status") ||
          %{},
      "source_link_capacity_station_calendar_provider_entry_ids_by_requirement_status" =>
        Map.get(
          link_capacity_summary,
          "station_calendar_provider_entry_ids_by_requirement_status"
        ) || %{},
      "source_link_capacity_trust_boundary_status" =>
        Map.get(link_capacity_summary, "trust_boundary_status"),
      "source_link_capacity_branch_local_link_capacity_pressure" =>
        link_capacity_branch_local_link_capacity_pressure?(link_capacity_summary),
      "source_link_capacity_branch_local_capacity_adjusted_throughput_pressure" =>
        link_capacity_branch_local_capacity_adjusted_throughput_pressure?(link_capacity_summary),
      "source_link_capacity_branch_local_downlink_shortfall_pressure" =>
        link_capacity_branch_local_downlink_shortfall_pressure?(link_capacity_summary),
      "source_link_capacity_branch_local_actual_throughput_pressure" =>
        link_capacity_branch_local_actual_throughput_pressure?(link_capacity_summary),
      "source_resource_filter_report_count" => Map.get(resource_filter_summary, "count"),
      "source_resource_filter_row_count" => Map.get(resource_filter_summary, "row_count"),
      "source_resource_filter_suppressed_candidate_count" =>
        Map.get(resource_filter_summary, "suppressed_candidate_count"),
      "source_resource_filter_invalid_resource_summary_input_count" =>
        Map.get(resource_filter_summary, "invalid_resource_summary_input_count"),
      "source_resource_filter_invalid_resource_summary_input_ids" =>
        Map.get(resource_filter_summary, "invalid_resource_summary_input_ids") || [],
      "source_resource_filter_suppressed_reason_counts" =>
        Map.get(resource_filter_summary, "suppressed_reason_counts") || %{},
      "source_resource_filter_candidate_ids_by_suppressed_reason" =>
        Map.get(resource_filter_summary, "candidate_ids_by_suppressed_reason") || %{},
      "source_resource_filter_spacecraft_counts" =>
        Map.get(resource_filter_summary, "resource_filter_spacecraft_counts") || %{},
      "source_resource_filter_candidate_ids_by_spacecraft" =>
        Map.get(resource_filter_summary, "candidate_ids_by_spacecraft") || %{},
      "source_resource_filter_resource_counts" =>
        Map.get(resource_filter_summary, "resource_filter_resource_counts") || %{},
      "source_resource_filter_candidate_ids_by_resource" =>
        Map.get(resource_filter_summary, "candidate_ids_by_resource") || %{},
      "source_resource_filter_blocking_dimension_counts" =>
        Map.get(resource_filter_summary, "resource_filter_blocking_dimension_counts") || %{},
      "source_resource_filter_candidate_ids_by_blocking_dimension" =>
        Map.get(resource_filter_summary, "candidate_ids_by_blocking_dimension") || %{},
      "source_resource_filter_direction_counts" =>
        Map.get(resource_filter_summary, "direction_counts") || %{},
      "source_resource_filter_directions" => Map.get(resource_filter_summary, "directions") || [],
      "source_resource_filter_candidate_ids_by_direction" =>
        Map.get(resource_filter_summary, "candidate_ids_by_direction") || %{},
      "source_resource_filter_direction_routing" =>
        Map.get(resource_filter_summary, "direction_routing") || %{},
      "source_resource_filter_trust_boundary_status" =>
        Map.get(resource_filter_summary, "trust_boundary_status"),
      "source_resource_filter_branch_local_resource_filter_pressure" =>
        resource_filter_branch_local_resource_filter_pressure?(resource_filter_summary),
      "source_resource_filter_branch_local_candidate_suppression_pressure" =>
        resource_filter_branch_local_candidate_suppression_pressure?(resource_filter_summary),
      "source_resource_filter_branch_local_invalid_resource_summary_pressure" =>
        resource_filter_branch_local_invalid_resource_summary_pressure?(resource_filter_summary),
      "source_resource_filter_branch_local_resource_blocking_pressure" =>
        resource_filter_branch_local_resource_blocking_pressure?(resource_filter_summary),
      "source_resource_projection_report_count" => Map.get(resource_projection_summary, "count"),
      "source_resource_projection_row_count" => Map.get(resource_projection_summary, "row_count"),
      "source_resource_projection_projected_resource_count" =>
        Map.get(resource_projection_summary, "projected_resource_count"),
      "source_resource_projection_invalid_activity_input_count" =>
        Map.get(resource_projection_summary, "invalid_activity_input_count"),
      "source_resource_projection_invalid_resource_summary_input_count" =>
        Map.get(resource_projection_summary, "invalid_resource_summary_input_count"),
      "source_resource_projection_resource_pressure_status_counts" =>
        Map.get(resource_projection_summary, "resource_pressure_status_counts") || %{},
      "source_resource_projection_resource_pressure_type_counts" =>
        Map.get(resource_projection_summary, "resource_pressure_type_counts") || %{},
      "source_resource_projection_resource_pressure_direction_counts" =>
        Map.get(resource_projection_summary, "resource_pressure_direction_counts") || %{},
      "source_resource_projection_resource_pressure_activity_ids_by_status" =>
        Map.get(resource_projection_summary, "resource_pressure_activity_ids_by_status") || %{},
      "source_resource_projection_resource_pressure_activity_ids_by_type" =>
        Map.get(resource_projection_summary, "resource_pressure_activity_ids_by_type") || %{},
      "source_resource_projection_resource_pressure_activity_ids_by_direction" =>
        Map.get(resource_projection_summary, "resource_pressure_activity_ids_by_direction") ||
          %{},
      "source_resource_projection_trust_boundary_status" =>
        Map.get(resource_projection_summary, "trust_boundary_status"),
      "source_quality_gate_report_count" => Map.get(quality_gate_summary, "count"),
      "source_quality_gate_row_count" => Map.get(quality_gate_summary, "row_count"),
      "source_quality_gate_gate_count" => Map.get(quality_gate_summary, "gate_count"),
      "source_quality_gate_passed_gate_count" =>
        Map.get(quality_gate_summary, "passed_gate_count"),
      "source_quality_gate_review_gate_count" =>
        Map.get(quality_gate_summary, "review_gate_count"),
      "source_quality_gate_analysis_gate_count" =>
        Map.get(quality_gate_summary, "analysis_gate_count"),
      "source_quality_gate_blocked_gate_count" =>
        Map.get(quality_gate_summary, "blocked_gate_count"),
      "source_quality_gate_readiness_level_counts" =>
        Map.get(quality_gate_summary, "readiness_level_counts") || %{},
      "source_quality_gate_import_classification_counts" =>
        Map.get(quality_gate_summary, "import_classification_counts") || %{},
      "source_quality_gate_status_counts" =>
        Map.get(quality_gate_summary, "status_counts") || %{},
      "source_quality_gate_gate_status_counts" =>
        Map.get(quality_gate_summary, "gate_status_counts") || %{},
      "source_quality_gate_gate_classification_counts" =>
        Map.get(quality_gate_summary, "gate_classification_counts") || %{},
      "source_quality_gate_ready_for_import_count" =>
        Map.get(quality_gate_summary, "ready_for_import_count"),
      "source_quality_gate_import_status_counts" =>
        Map.get(quality_gate_summary, "import_status_counts") || %{},
      "source_quality_gate_cadence_import_status_counts" =>
        Map.get(quality_gate_summary, "cadence_import_status_counts") || %{},
      "source_quality_gate_trust_boundary_status" =>
        Map.get(quality_gate_summary, "trust_boundary_status"),
      "source_quality_gate_resource_availability_pressure_count" =>
        Map.get(quality_gate_summary, "resource_availability_pressure_count"),
      "source_quality_gate_resource_availability_reason_counts" =>
        Map.get(quality_gate_summary, "resource_availability_reason_counts") || %{},
      "source_quality_gate_resource_availability_reason_ids" =>
        quality_gate_summary
        |> list_values("resource_availability_reason_ids")
        |> stable_id_keys(),
      "source_quality_gate_branch_local_review_pressure" =>
        quality_gate_branch_local_review_pressure?(quality_gate_summary),
      "source_quality_gate_branch_local_import_pressure" =>
        quality_gate_branch_local_import_pressure?(quality_gate_summary),
      "source_quality_gate_branch_local_resource_pressure" =>
        quality_gate_branch_local_resource_pressure?(quality_gate_summary),
      "source_operational_readiness_report_count" =>
        Map.get(operational_readiness_summary, "count"),
      "source_operational_readiness_row_count" =>
        Map.get(operational_readiness_summary, "row_count"),
      "source_operational_readiness_gate_count" =>
        Map.get(operational_readiness_summary, "gate_count"),
      "source_operational_readiness_passed_gate_count" =>
        Map.get(operational_readiness_summary, "passed_gate_count"),
      "source_operational_readiness_review_gate_count" =>
        Map.get(operational_readiness_summary, "review_gate_count"),
      "source_operational_readiness_analysis_gate_count" =>
        Map.get(operational_readiness_summary, "analysis_gate_count"),
      "source_operational_readiness_blocked_gate_count" =>
        Map.get(operational_readiness_summary, "blocked_gate_count"),
      "source_operational_readiness_readiness_level_counts" =>
        Map.get(operational_readiness_summary, "readiness_level_counts") || %{},
      "source_operational_readiness_import_classification_counts" =>
        Map.get(operational_readiness_summary, "import_classification_counts") || %{},
      "source_operational_readiness_status_counts" =>
        Map.get(operational_readiness_summary, "status_counts") || %{},
      "source_operational_readiness_trust_boundary_status" =>
        Map.get(operational_readiness_summary, "trust_boundary_status"),
      "source_operational_readiness_resource_availability_pressure_count" =>
        Map.get(operational_readiness_summary, "resource_availability_pressure_count"),
      "source_operational_readiness_resource_availability_reason_counts" =>
        Map.get(operational_readiness_summary, "resource_availability_reason_counts") || %{},
      "source_operational_readiness_resource_availability_reason_ids" =>
        operational_readiness_summary
        |> list_values("resource_availability_reason_ids")
        |> stable_id_keys(),
      "source_operational_readiness_branch_local_review_pressure" =>
        operational_readiness_branch_local_review_pressure?(operational_readiness_summary),
      "source_operational_readiness_branch_local_import_pressure" =>
        operational_readiness_branch_local_import_pressure?(operational_readiness_summary),
      "source_operational_readiness_branch_local_resource_pressure" =>
        operational_readiness_branch_local_resource_pressure?(operational_readiness_summary),
      "source_timeline_activity_precondition_report_count" =>
        Map.get(timeline_activity_precondition_summary, "count"),
      "source_timeline_activity_precondition_row_count" =>
        Map.get(timeline_activity_precondition_summary, "row_count"),
      "source_timeline_activity_precondition_status_counts" =>
        Map.get(timeline_activity_precondition_summary, "precondition_status_counts") || %{},
      "source_timeline_activity_precondition_blocked_precondition_count" =>
        Map.get(timeline_activity_precondition_summary, "blocked_precondition_count"),
      "source_timeline_activity_precondition_review_precondition_count" =>
        Map.get(timeline_activity_precondition_summary, "review_precondition_count"),
      "source_timeline_activity_precondition_blocked_precondition_type_counts" =>
        Map.get(timeline_activity_precondition_summary, "blocked_precondition_type_counts") ||
          %{},
      "source_timeline_activity_precondition_review_precondition_type_counts" =>
        Map.get(timeline_activity_precondition_summary, "review_precondition_type_counts") ||
          %{},
      "source_timeline_activity_precondition_invalid_activity_input_count" =>
        Map.get(timeline_activity_precondition_summary, "invalid_activity_input_count"),
      "source_timeline_activity_precondition_invalid_activity_input_reason_counts" =>
        Map.get(timeline_activity_precondition_summary, "invalid_activity_input_reason_counts") ||
          %{},
      "source_timeline_activity_precondition_dependency_activity_id_counts" =>
        Map.get(timeline_activity_precondition_summary, "dependency_activity_id_counts") || %{},
      "source_timeline_activity_precondition_dependency_timeline_id_counts" =>
        Map.get(timeline_activity_precondition_summary, "dependency_timeline_id_counts") || %{},
      "source_timeline_activity_precondition_exclusive_with_activity_id_counts" =>
        Map.get(timeline_activity_precondition_summary, "exclusive_with_activity_id_counts") ||
          %{},
      "source_timeline_activity_precondition_exclusive_with_timeline_id_counts" =>
        Map.get(timeline_activity_precondition_summary, "exclusive_with_timeline_id_counts") ||
          %{},
      "source_timeline_activity_precondition_duplicate_dependency_activity_id_counts" =>
        Map.get(
          timeline_activity_precondition_summary,
          "duplicate_dependency_activity_id_counts"
        ) || %{},
      "source_timeline_activity_precondition_duplicate_dependency_timeline_id_counts" =>
        Map.get(
          timeline_activity_precondition_summary,
          "duplicate_dependency_timeline_id_counts"
        ) || %{},
      "source_timeline_activity_precondition_duplicate_exclusivity_activity_id_counts" =>
        Map.get(
          timeline_activity_precondition_summary,
          "duplicate_exclusivity_activity_id_counts"
        ) || %{},
      "source_timeline_activity_precondition_duplicate_exclusivity_timeline_id_counts" =>
        Map.get(
          timeline_activity_precondition_summary,
          "duplicate_exclusivity_timeline_id_counts"
        ) || %{},
      "source_timeline_activity_precondition_allow_overlap_counts" =>
        Map.get(timeline_activity_precondition_summary, "allow_overlap_counts") || %{},
      "source_timeline_activity_precondition_trust_boundary_status" =>
        Map.get(timeline_activity_precondition_summary, "trust_boundary_status"),
      "source_timeline_activity_lifecycle_report_count" =>
        Map.get(timeline_activity_lifecycle_summary, "count"),
      "source_timeline_activity_lifecycle_row_count" =>
        Map.get(timeline_activity_lifecycle_summary, "row_count"),
      "source_timeline_activity_lifecycle_review_required_count" =>
        Map.get(timeline_activity_lifecycle_summary, "review_required_count"),
      "source_timeline_activity_lifecycle_invalid_activity_input_count" =>
        Map.get(timeline_activity_lifecycle_summary, "invalid_activity_input_count"),
      "source_timeline_activity_lifecycle_transition_decision_counts" =>
        Map.get(timeline_activity_lifecycle_summary, "transition_decision_counts") || %{},
      "source_timeline_activity_lifecycle_status_transition_decision_counts" =>
        Map.get(timeline_activity_lifecycle_summary, "status_transition_decision_counts") || %{},
      "source_timeline_activity_lifecycle_approval_transition_decision_counts" =>
        Map.get(timeline_activity_lifecycle_summary, "approval_transition_decision_counts") ||
          %{},
      "source_timeline_activity_lifecycle_required_operator_action_counts" =>
        Map.get(timeline_activity_lifecycle_summary, "required_operator_action_counts") || %{},
      "source_timeline_activity_lifecycle_import_action_counts" =>
        Map.get(timeline_activity_lifecycle_summary, "import_action_counts") || %{},
      "source_timeline_activity_lifecycle_planned_status_category_counts" =>
        Map.get(timeline_activity_lifecycle_summary, "planned_status_category_counts") || %{},
      "source_timeline_activity_lifecycle_realized_status_category_counts" =>
        Map.get(timeline_activity_lifecycle_summary, "realized_status_category_counts") || %{},
      "source_timeline_activity_lifecycle_planned_approval_category_counts" =>
        Map.get(timeline_activity_lifecycle_summary, "planned_approval_category_counts") || %{},
      "source_timeline_activity_lifecycle_realized_approval_category_counts" =>
        Map.get(timeline_activity_lifecycle_summary, "realized_approval_category_counts") || %{},
      "source_timeline_activity_lifecycle_status_transition_category_counts" =>
        Map.get(timeline_activity_lifecycle_summary, "status_transition_category_counts") || %{},
      "source_timeline_activity_lifecycle_approval_transition_category_counts" =>
        Map.get(timeline_activity_lifecycle_summary, "approval_transition_category_counts") ||
          %{},
      "source_timeline_activity_lifecycle_protection_decision_counts" =>
        Map.get(timeline_activity_lifecycle_summary, "protection_decision_counts") || %{},
      "source_timeline_activity_lifecycle_protection_category_counts" =>
        Map.get(timeline_activity_lifecycle_summary, "protection_category_counts") || %{},
      "source_timeline_activity_lifecycle_action_routing" =>
        Map.get(timeline_activity_lifecycle_summary, "action_routing") || %{},
      "source_timeline_activity_lifecycle_trust_boundary_status" =>
        Map.get(timeline_activity_lifecycle_summary, "trust_boundary_status"),
      "source_timeline_lifecycle_state_report_count" =>
        Map.get(timeline_lifecycle_state_summary, "count"),
      "source_timeline_lifecycle_state_row_count" =>
        Map.get(timeline_lifecycle_state_summary, "row_count"),
      "source_timeline_lifecycle_state_planned_activity_count" =>
        Map.get(timeline_lifecycle_state_summary, "planned_activity_count"),
      "source_timeline_lifecycle_state_realized_activity_count" =>
        Map.get(timeline_lifecycle_state_summary, "realized_activity_count"),
      "source_timeline_lifecycle_state_recordable_count" =>
        Map.get(timeline_lifecycle_state_summary, "recordable_count"),
      "source_timeline_lifecycle_state_preserved_count" =>
        Map.get(timeline_lifecycle_state_summary, "preserved_count"),
      "source_timeline_lifecycle_state_review_required_count" =>
        Map.get(timeline_lifecycle_state_summary, "review_required_count"),
      "source_timeline_lifecycle_state_duplicate_timeline_identity_count" =>
        Map.get(timeline_lifecycle_state_summary, "duplicate_timeline_identity_count"),
      "source_timeline_lifecycle_state_invalid_activity_input_count" =>
        Map.get(timeline_lifecycle_state_summary, "invalid_activity_input_count"),
      "source_timeline_lifecycle_state_transition_decision_counts" =>
        Map.get(timeline_lifecycle_state_summary, "transition_decision_counts") || %{},
      "source_timeline_lifecycle_state_required_operator_action_counts" =>
        Map.get(timeline_lifecycle_state_summary, "required_operator_action_counts") || %{},
      "source_timeline_lifecycle_state_import_action_counts" =>
        Map.get(timeline_lifecycle_state_summary, "import_action_counts") || %{},
      "source_timeline_lifecycle_state_preserved_timeline_ids" =>
        Map.get(timeline_lifecycle_state_summary, "preserved_timeline_ids") || [],
      "source_timeline_lifecycle_state_preserved_timeline_keys" =>
        timeline_lifecycle_state_summary
        |> list_values("preserved_timeline_ids")
        |> Enum.join("|")
        |> normalize_optional_string(),
      "source_timeline_lifecycle_state_review_timeline_ids" =>
        Map.get(timeline_lifecycle_state_summary, "review_timeline_ids") || [],
      "source_timeline_lifecycle_state_review_timeline_keys" =>
        timeline_lifecycle_state_summary
        |> list_values("review_timeline_ids")
        |> Enum.join("|")
        |> normalize_optional_string(),
      "source_timeline_lifecycle_state_review_activity_ids" =>
        Map.get(timeline_lifecycle_state_summary, "review_activity_ids") || [],
      "source_timeline_lifecycle_state_review_activity_keys" =>
        timeline_lifecycle_state_summary
        |> list_values("review_activity_ids")
        |> Enum.join("|")
        |> normalize_optional_string(),
      "source_timeline_lifecycle_state_review_timeline_ids_by_required_operator_action" =>
        Map.get(
          timeline_lifecycle_state_summary,
          "review_timeline_ids_by_required_operator_action"
        ) || %{},
      "source_timeline_lifecycle_state_trust_boundary_status" =>
        Map.get(timeline_lifecycle_state_summary, "trust_boundary_status"),
      "source_objective_satisfaction_report_count" =>
        Map.get(objective_satisfaction_summary, "count"),
      "source_objective_satisfaction_gap_row_count" =>
        Map.get(objective_satisfaction_summary, "gap_row_count"),
      "source_objective_satisfaction_downlink_gap_row_count" =>
        Map.get(objective_satisfaction_summary, "downlink_gap_row_count"),
      "source_objective_satisfaction_target_gap_row_count" =>
        Map.get(objective_satisfaction_summary, "target_gap_row_count"),
      "source_objective_satisfaction_collection_latency_gap_row_count" =>
        Map.get(objective_satisfaction_summary, "collection_latency_gap_row_count"),
      "source_objective_satisfaction_status_counts" =>
        Map.get(objective_satisfaction_summary, "status_counts") || %{},
      "source_objective_satisfaction_objective_type_counts" =>
        Map.get(objective_satisfaction_summary, "objective_type_counts") || %{},
      "source_objective_satisfaction_ground_station_counts" =>
        Map.get(objective_satisfaction_summary, "ground_station_counts") || %{},
      "source_objective_satisfaction_target_counts" =>
        Map.get(objective_satisfaction_summary, "target_counts") || %{},
      "source_objective_satisfaction_collection_counts" =>
        Map.get(objective_satisfaction_summary, "collection_counts") || %{},
      "source_objective_satisfaction_source_activity_id_counts" =>
        Map.get(objective_satisfaction_summary, "source_activity_id_counts") || %{},
      "source_objective_satisfaction_trust_boundary_status" =>
        Map.get(objective_satisfaction_summary, "trust_boundary_status"),
      "source_objective_tradeoff_report_count" => Map.get(objective_tradeoff_summary, "count"),
      "source_objective_tradeoff_row_count" => Map.get(objective_tradeoff_summary, "row_count"),
      "source_objective_tradeoff_downlink_gap_row_count" =>
        Map.get(objective_tradeoff_summary, "downlink_gap_row_count"),
      "source_objective_tradeoff_target_gap_row_count" =>
        Map.get(objective_tradeoff_summary, "target_gap_row_count"),
      "source_objective_tradeoff_collection_latency_gap_row_count" =>
        Map.get(objective_tradeoff_summary, "collection_latency_gap_row_count"),
      "source_objective_tradeoff_ground_station_counts" =>
        Map.get(objective_tradeoff_summary, "ground_station_counts") || %{},
      "source_objective_tradeoff_target_counts" =>
        Map.get(objective_tradeoff_summary, "target_counts") || %{},
      "source_objective_tradeoff_collection_counts" =>
        Map.get(objective_tradeoff_summary, "collection_counts") || %{},
      "source_objective_tradeoff_source_activity_id_counts" =>
        Map.get(objective_tradeoff_summary, "source_activity_id_counts") || %{},
      "source_objective_tradeoff_trust_boundary_status" =>
        Map.get(objective_tradeoff_summary, "trust_boundary_status"),
      "source_score_term_report_count" => Map.get(score_term_summary, "count"),
      "source_score_term_row_count" => Map.get(score_term_summary, "row_count"),
      "source_score_term_downlink_gap_row_count" =>
        Map.get(score_term_summary, "downlink_gap_row_count"),
      "source_score_term_target_gap_row_count" =>
        Map.get(score_term_summary, "target_gap_row_count"),
      "source_score_term_collection_latency_gap_row_count" =>
        Map.get(score_term_summary, "collection_latency_gap_row_count"),
      "source_score_term_term_key_counts" =>
        Map.get(score_term_summary, "term_key_counts") || %{},
      "source_score_term_ground_station_counts" =>
        Map.get(score_term_summary, "ground_station_counts") || %{},
      "source_score_term_target_counts" => Map.get(score_term_summary, "target_counts") || %{},
      "source_score_term_collection_counts" =>
        Map.get(score_term_summary, "collection_counts") || %{},
      "source_score_term_source_activity_id_counts" =>
        Map.get(score_term_summary, "source_activity_id_counts") || %{},
      "source_score_term_trust_boundary_status" =>
        Map.get(score_term_summary, "trust_boundary_status"),
      "source_score_term_branch_local_score_term_pressure" =>
        map_size(Map.get(score_term_summary, "term_key_counts") || %{}) > 0,
      "source_score_term_branch_local_downlink_gap_pressure" =>
        positive_integer_observation?(score_term_summary, "downlink_gap_row_count"),
      "source_score_term_branch_local_target_gap_pressure" =>
        positive_integer_observation?(score_term_summary, "target_gap_row_count"),
      "source_score_term_branch_local_collection_latency_gap_pressure" =>
        positive_integer_observation?(score_term_summary, "collection_latency_gap_row_count"),
      "source_score_term_branch_local_routing_pressure" =>
        score_term_routing_pressure?(score_term_summary),
      "source_objective_gap_branch_local_objective_gap_pressure" =>
        objective_gap_branch_local_objective_gap_pressure?(
          objective_satisfaction_summary,
          objective_tradeoff_summary,
          score_term_summary
        ),
      "source_objective_gap_branch_local_downlink_gap_pressure" =>
        objective_gap_branch_local_gap_pressure?(
          [
            objective_satisfaction_summary,
            objective_tradeoff_summary,
            score_term_summary
          ],
          "downlink_gap_row_count"
        ),
      "source_objective_gap_branch_local_target_gap_pressure" =>
        objective_gap_branch_local_gap_pressure?(
          [
            objective_satisfaction_summary,
            objective_tradeoff_summary,
            score_term_summary
          ],
          "target_gap_row_count"
        ),
      "source_objective_gap_branch_local_collection_latency_gap_pressure" =>
        objective_gap_branch_local_gap_pressure?(
          [
            objective_satisfaction_summary,
            objective_tradeoff_summary,
            score_term_summary
          ],
          "collection_latency_gap_row_count"
        ),
      "source_objective_gap_branch_local_objective_status_pressure" =>
        objective_gap_branch_local_objective_status_pressure?(objective_satisfaction_summary),
      "source_objective_gap_branch_local_score_term_pressure" =>
        objective_gap_branch_local_score_term_pressure?(score_term_summary),
      "source_objective_gap_branch_local_routing_pressure" =>
        objective_gap_branch_local_routing_pressure?([
          objective_satisfaction_summary,
          objective_tradeoff_summary,
          score_term_summary
        ]),
      "source_timeline_transition_application_report_count" =>
        Map.get(timeline_transition_summary, "count"),
      "source_timeline_transition_application_row_count" =>
        Map.get(timeline_transition_summary, "row_count"),
      "source_timeline_transition_application_application_count" =>
        Map.get(timeline_transition_summary, "application_count"),
      "source_timeline_transition_application_selected_activity_count" =>
        Map.get(timeline_transition_summary, "selected_activity_count"),
      "source_timeline_transition_application_selected_integrity_review_count" =>
        Map.get(timeline_transition_summary, "selected_timeline_integrity_review_count"),
      "source_timeline_transition_application_selected_integrity_issue_count" =>
        Map.get(timeline_transition_summary, "selected_timeline_integrity_issue_count"),
      "source_timeline_transition_application_selected_integrity_issue_type_counts" =>
        Map.get(timeline_transition_summary, "selected_timeline_integrity_issue_type_counts") ||
          %{},
      "source_timeline_transition_application_review_required_count" =>
        Map.get(timeline_transition_summary, "review_required_count"),
      "source_timeline_transition_application_status_counts" =>
        Map.get(timeline_transition_summary, "application_status_counts") || %{},
      "source_timeline_transition_application_required_operator_action_counts" =>
        Map.get(timeline_transition_summary, "required_operator_action_counts") || %{},
      "source_timeline_transition_application_trust_boundary_status" =>
        Map.get(timeline_transition_summary, "trust_boundary_status")
    }
    |> compact_validation_map()
  end

  defp normalize_optional_string(value) when value in [nil, ""], do: nil
  defp normalize_optional_string(value), do: to_string(value)

  defp compact_validation_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> value in [nil, %{}, []] end)
    |> Map.new()
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp map_field(map, key) do
    case Map.get(map, key) do
      value when is_map(value) -> value
      _value -> %{}
    end
  end

  defp map_rows(map, key) do
    case Map.get(map, key) do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp optional_row_id_keys(rows, key) when is_list(rows) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.reject(&is_nil/1)
    |> optional_stable_id_keys()
  end

  defp count_rows_by_value(rows, key) when is_list(rows) do
    rows
    |> Enum.map(&(Map.get(&1, key) || "unknown"))
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp candidate_filter_provenance_rows(rows, provenance_key) when is_list(rows) do
    Enum.flat_map(rows, fn row ->
      case get_in(row, ["activity_context", "provenance", provenance_key]) do
        %{} = provenance ->
          [%{"candidate_id" => Map.get(row, "candidate_id"), "provenance" => provenance}]

        _provenance ->
          []
      end
    end)
  end

  defp candidate_filter_candidate_id_keys(rows) when is_list(rows) do
    rows
    |> Enum.map(&Map.get(&1, "candidate_id"))
    |> Enum.reject(&is_nil/1)
    |> optional_stable_id_keys()
  end

  defp candidate_filter_provenance_keys(rows, field) when is_list(rows) do
    rows
    |> Enum.flat_map(fn row ->
      case get_in(row, ["provenance", field]) do
        values when is_list(values) -> values
        value when is_binary(value) -> [value]
        _value -> []
      end
    end)
    |> optional_stable_id_keys()
  end

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _values -> []
    end
  end

  defp stable_id_keys(values) when is_list(values) do
    values
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.join("|")
  end

  defp optional_stable_id_keys([]), do: nil
  defp optional_stable_id_keys(values), do: stable_id_keys(values)

  defp positive_number?(value), do: is_number(value) and value > 0.0

  defp candidate_refresh_source_report_row_count(%{} = source_reports) do
    source_reports
    |> Map.values()
    |> Enum.map(&integer_observation_value(Map.get(&1, "row_count")))
    |> Enum.reject(&is_nil/1)
    |> Enum.sum()
  end

  defp operational_readiness_branch_local_review_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "review_gate_count") or
      positive_integer_observation?(summary, "blocked_gate_count") or
      positive_integer_observation?(summary, "review_required_count")
  end

  defp operational_readiness_branch_local_import_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "manifest_review_required_count") or
      positive_integer_observation?(summary, "missing_import_count") or
      positive_integer_observation?(summary, "blocked_import_count") or
      positive_integer_observation?(summary, "invalid_cadence_import_count") or
      positive_integer_observation?(summary, "import_ineligible_count")
  end

  defp operational_readiness_branch_local_resource_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "resource_availability_pressure_count") or
      map_size(Map.get(summary, "resource_availability_reason_counts") || %{}) > 0
  end

  defp quality_gate_branch_local_review_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "review_gate_count") or
      positive_integer_observation?(summary, "blocked_gate_count") or
      map_size(Map.get(summary, "readiness_level_counts") || %{}) > 0 or
      map_size(Map.get(summary, "import_classification_counts") || %{}) > 0 or
      map_size(Map.get(summary, "status_counts") || %{}) > 0 or
      map_size(Map.get(summary, "analysis_mode_counts") || %{}) > 0 or
      map_size(Map.get(summary, "gate_status_counts") || %{}) > 0 or
      map_size(Map.get(summary, "gate_classification_counts") || %{}) > 0
  end

  defp quality_gate_branch_local_import_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "manifest_review_required_count") or
      positive_integer_observation?(summary, "missing_import_count") or
      positive_integer_observation?(summary, "blocked_import_count") or
      positive_integer_observation?(summary, "invalid_cadence_import_count") or
      map_size(Map.get(summary, "import_status_counts") || %{}) > 0 or
      map_size(Map.get(summary, "cadence_import_status_counts") || %{}) > 0
  end

  defp quality_gate_branch_local_resource_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "resource_availability_pressure_count") or
      map_size(Map.get(summary, "resource_availability_reason_counts") || %{}) > 0 or
      list_values(summary, "resource_availability_reason_ids") != [] or
      list_values(summary, "station_availability_reason_ids") != [] or
      map_size(Map.get(summary, "station_availability_reason_counts") || %{}) > 0 or
      list_values(summary, "unavailable_resource_reason_ids") != [] or
      map_size(Map.get(summary, "resource_blocking_dimension_counts") || %{}) > 0 or
      map_size(Map.get(summary, "blocked_contact_ids_by_blocking_dimension") || %{}) > 0 or
      map_size(Map.get(summary, "blocked_contact_ids_by_spacecraft_id") || %{}) > 0 or
      map_size(Map.get(summary, "blocked_contact_ids_by_status") || %{}) > 0
  end

  defp constraint_branch_local_constraint_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "downlink_gap_row_count") or
      map_size(Map.get(summary, "status_counts") || %{}) > 0 or
      constraint_branch_local_resource_margin_pressure?(summary) or
      constraint_branch_local_routing_pressure?(summary)
  end

  defp constraint_branch_local_resource_margin_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "resource_margin_row_count") or
      map_size(Map.get(summary, "constraint_resource_counts") || %{}) > 0 or
      map_size(Map.get(summary, "constraint_spacecraft_counts") || %{}) > 0
  end

  defp constraint_branch_local_routing_pressure?(%{} = summary) do
    map_size(Map.get(summary, "ground_station_counts") || %{}) > 0 or
      map_size(Map.get(summary, "constraint_metric_counts") || %{}) > 0 or
      map_size(Map.get(summary, "constraint_id_counts") || %{}) > 0 or
      map_size(Map.get(summary, "source_activity_id_counts") || %{}) > 0 or
      map_size(Map.get(summary, "constraint_resource_counts") || %{}) > 0 or
      map_size(Map.get(summary, "constraint_spacecraft_counts") || %{}) > 0
  end

  defp candidate_rejection_branch_local_rejection_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "rejected_count") or
      positive_integer_observation?(summary, "reviewable_count") or
      positive_integer_observation?(summary, "invalid_candidate_input_count") or
      map_size(Map.get(summary, "rejection_reason_counts") || %{}) > 0 or
      map_size(Map.get(summary, "required_operator_action_counts") || %{}) > 0 or
      map_size(Map.get(summary, "candidate_rejection_candidate_id_counts") || %{}) > 0 or
      map_size(Map.get(summary, "candidate_rejection_ground_station_counts") || %{}) > 0
  end

  defp candidate_rejection_branch_local_review_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "reviewable_count") or
      map_size(Map.get(summary, "required_operator_action_counts") || %{}) > 0
  end

  defp candidate_rejection_branch_local_invalid_input_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "invalid_candidate_input_count") or
      positive_integer_observation?(
        Map.get(summary, "rejection_reason_counts") || %{},
        "invalid_candidate_input"
      )
  end

  defp freshness_branch_local_stale_pressure?(%{} = summary) do
    positive_integer_observation?(Map.get(summary, "status_counts") || %{}, "stale") or
      positive_integer_observation?(summary, "stale_reason_count") or
      list_values(summary, "stale_reasons") != [] or
      map_size(Map.get(summary, "stale_reason_counts") || %{}) > 0
  end

  defp freshness_branch_local_unknown_pressure?(%{} = summary) do
    positive_integer_observation?(Map.get(summary, "status_counts") || %{}, "unknown") or
      positive_integer_observation?(summary, "unknown_reason_count") or
      list_values(summary, "unknown_reasons") != [] or
      map_size(Map.get(summary, "unknown_reason_counts") || %{}) > 0
  end

  defp freshness_branch_local_freshness_pressure?(%{} = summary) do
    freshness_branch_local_stale_pressure?(summary) or
      freshness_branch_local_unknown_pressure?(summary)
  end

  defp refresh_budget_branch_local_budget_pressure?(%{} = summary) do
    refresh_budget_branch_local_dropped_candidate_pressure?(summary) or
      refresh_budget_branch_local_invalid_limit_pressure?(summary) or
      refresh_budget_branch_local_candidate_limit_applied?(summary)
  end

  defp refresh_budget_branch_local_dropped_candidate_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "dropped_candidate_count") or
      list_values(summary, "dropped_candidate_ids") != []
  end

  defp refresh_budget_branch_local_invalid_limit_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "invalid_candidate_limit_policy_count") or
      map_size(Map.get(summary, "invalid_candidate_limit_policy_reason_counts") || %{}) > 0
  end

  defp refresh_budget_branch_local_candidate_limit_applied?(%{} = summary) do
    input_candidate_count =
      integer_observation_value(Map.get(summary, "input_candidate_count")) || 0

    kept_candidate_count =
      integer_observation_value(Map.get(summary, "kept_candidate_count")) || 0

    refresh_budget_branch_local_dropped_candidate_pressure?(summary) or
      (input_candidate_count > 0 and kept_candidate_count < input_candidate_count)
  end

  defp station_calendar_branch_local_station_calendar_pressure?(%{} = summary) do
    station_calendar_branch_local_affected_contact_pressure?(summary) or
      station_calendar_branch_local_provider_contention_pressure?(summary) or
      station_calendar_branch_local_station_availability_pressure?(summary)
  end

  defp station_calendar_branch_local_affected_contact_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "affected_contact_count") or
      list_values(summary, "affected_contact_ids") != [] or
      map_size(Map.get(summary, "affected_contact_ground_station_counts") || %{}) > 0 or
      map_size(Map.get(summary, "direction_counts") || %{}) > 0
  end

  defp station_calendar_branch_local_provider_contention_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "provider_calendar_contention_group_count") or
      list_values(summary, "provider_calendar_contention_group_ids") != [] or
      list_values(summary, "provider_calendar_contention_source_entry_ids") != [] or
      list_values(summary, "provider_calendar_contention_provider_entry_ids") != [] or
      map_size(Map.get(summary, "provider_calendar_contention_provider_counts") || %{}) > 0 or
      map_size(Map.get(summary, "provider_calendar_contention_ground_station_counts") || %{}) >
        0 or
      map_size(Map.get(summary, "provider_calendar_contention_direction_counts") || %{}) > 0
  end

  defp station_calendar_branch_local_station_availability_pressure?(%{} = summary) do
    minimum_provider_contention_capacity_fraction =
      numeric_observation_value(
        Map.get(summary, "provider_calendar_contention_minimum_capacity_fraction")
      ) || 0.0

    map_size(Map.get(summary, "station_calendar_status_counts") || %{}) > 0 or
      map_size(Map.get(summary, "affected_contact_availability_counts") || %{}) > 0 or
      list_values(summary, "station_capacity_fractions") != [] or
      minimum_provider_contention_capacity_fraction > 0.0
  end

  defp contact_filter_branch_local_contact_filter_pressure?(%{} = summary) do
    contact_filter_branch_local_candidate_suppression_pressure?(summary) or
      contact_filter_branch_local_invalid_contact_input_pressure?(summary) or
      contact_filter_branch_local_station_suppression_pressure?(summary)
  end

  defp contact_filter_branch_local_candidate_suppression_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "suppressed_candidate_count") or
      map_size(Map.get(summary, "suppressed_reason_counts") || %{}) > 0 or
      map_size(Map.get(summary, "contact_ids_by_suppressed_reason") || %{}) > 0 or
      map_size(Map.get(summary, "direction_counts") || %{}) > 0 or
      list_values(summary, "directions") != [] or
      map_size(Map.get(summary, "contact_ids_by_direction") || %{}) > 0 or
      map_size(Map.get(summary, "direction_routing") || %{}) > 0
  end

  defp contact_filter_branch_local_invalid_contact_input_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "invalid_contact_input_count") or
      list_values(summary, "invalid_contact_input_ids") != []
  end

  defp contact_filter_branch_local_station_suppression_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "station_suppression_count") or
      Enum.any?(
        [
          "station_suppression_ground_station_counts",
          "station_suppression_availability_counts",
          "station_suppression_status_counts",
          "station_suppression_contact_ids_by_ground_station",
          "station_suppression_contact_ids_by_availability",
          "station_suppression_contact_ids_by_status",
          "station_suppression_station_calendar_entry_ids_by_ground_station",
          "station_suppression_station_calendar_entry_ids_by_availability",
          "station_suppression_station_calendar_entry_ids_by_status",
          "station_suppression_station_calendar_provider_entry_ids_by_ground_station",
          "station_suppression_station_calendar_provider_entry_ids_by_availability",
          "station_suppression_station_calendar_provider_entry_ids_by_status",
          "station_suppression_station_reservation_ids_by_ground_station",
          "station_suppression_station_reservation_ids_by_availability",
          "station_suppression_station_reservation_ids_by_status"
        ],
        &(map_size(Map.get(summary, &1) || %{}) > 0)
      )
  end

  defp link_capacity_branch_local_link_capacity_pressure?(%{} = summary) do
    link_capacity_branch_local_capacity_adjusted_throughput_pressure?(summary) or
      link_capacity_branch_local_downlink_shortfall_pressure?(summary) or
      link_capacity_branch_local_actual_throughput_pressure?(summary) or
      map_size(Map.get(summary, "ground_station_counts") || %{}) > 0 or
      map_size(Map.get(summary, "direction_counts") || %{}) > 0 or
      list_values(summary, "directions") != [] or
      map_size(Map.get(summary, "spacecraft_counts") || %{}) > 0 or
      map_size(Map.get(summary, "contact_ids_by_direction") || %{}) > 0 or
      map_size(Map.get(summary, "source_window_ids_by_direction") || %{}) > 0 or
      map_size(Map.get(summary, "station_calendar_entry_ids_by_direction") || %{}) > 0 or
      map_size(Map.get(summary, "station_calendar_provider_entry_ids_by_direction") || %{}) >
        0 or
      map_size(Map.get(summary, "direction_routing") || %{}) > 0 or
      map_size(Map.get(summary, "contact_ids_by_ground_station") || %{}) > 0 or
      map_size(Map.get(summary, "source_window_ids_by_ground_station") || %{}) > 0 or
      map_size(Map.get(summary, "station_calendar_entry_ids_by_ground_station") || %{}) > 0 or
      map_size(Map.get(summary, "station_calendar_provider_entry_ids_by_ground_station") || %{}) >
        0 or
      map_size(Map.get(summary, "contact_ids_by_spacecraft") || %{}) > 0 or
      map_size(Map.get(summary, "source_window_ids_by_spacecraft") || %{}) > 0 or
      map_size(Map.get(summary, "station_calendar_entry_ids_by_spacecraft") || %{}) > 0 or
      map_size(Map.get(summary, "station_calendar_provider_entry_ids_by_spacecraft") || %{}) >
        0 or
      map_size(Map.get(summary, "selected_contact_id_counts") || %{}) > 0 or
      list_values(summary, "selected_contact_ids") != [] or
      list_values(summary, "selected_source_window_ids") != [] or
      list_values(summary, "selected_station_calendar_entry_ids") != [] or
      list_values(summary, "selected_station_calendar_provider_entry_ids") != []
  end

  defp link_capacity_branch_local_capacity_adjusted_throughput_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "capacity_adjusted_throughput_row_count") or
      positive_number?(Map.get(summary, "capacity_adjusted_throughput_mb_total")) or
      positive_number?(Map.get(summary, "selected_capacity_adjusted_throughput_mb_total")) or
      positive_number?(Map.get(summary, "unused_capacity_adjusted_throughput_mb_total")) or
      map_size(Map.get(summary, "capacity_adjusted_throughput_mb_by_ground_station") || %{}) >
        0 or
      map_size(
        Map.get(summary, "selected_capacity_adjusted_throughput_mb_by_ground_station") || %{}
      ) > 0 or
      map_size(
        Map.get(summary, "unused_capacity_adjusted_throughput_mb_by_ground_station") || %{}
      ) > 0 or
      map_size(Map.get(summary, "capacity_adjusted_throughput_mb_by_direction") || %{}) > 0 or
      map_size(Map.get(summary, "selected_capacity_adjusted_throughput_mb_by_direction") || %{}) >
        0 or
      map_size(Map.get(summary, "unused_capacity_adjusted_throughput_mb_by_direction") || %{}) >
        0
  end

  defp link_capacity_branch_local_downlink_shortfall_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "selected_shortfall_row_count") or
      positive_integer_observation?(summary, "actual_shortfall_row_count") or
      map_size(Map.get(summary, "downlink_requirement_status_counts") || %{}) > 0 or
      map_size(Map.get(summary, "contact_ids_by_requirement_status") || %{}) > 0 or
      map_size(Map.get(summary, "source_window_ids_by_requirement_status") || %{}) > 0 or
      map_size(Map.get(summary, "station_calendar_entry_ids_by_requirement_status") || %{}) >
        0 or
      map_size(
        Map.get(summary, "station_calendar_provider_entry_ids_by_requirement_status") || %{}
      ) > 0
  end

  defp link_capacity_branch_local_actual_throughput_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "actual_throughput_row_count") or
      map_size(Map.get(summary, "actual_throughput_contact_id_counts") || %{}) > 0 or
      list_values(summary, "actual_throughput_contact_ids") != [] or
      list_values(summary, "actual_throughput_source_window_ids") != [] or
      list_values(summary, "actual_throughput_station_calendar_entry_ids") != [] or
      list_values(summary, "actual_throughput_station_calendar_provider_entry_ids") != [] or
      link_capacity_actual_requirement_status_pressure?(
        summary,
        "contact_ids_by_requirement_status"
      ) or
      link_capacity_actual_requirement_status_pressure?(
        summary,
        "source_window_ids_by_requirement_status"
      ) or
      link_capacity_actual_requirement_status_pressure?(
        summary,
        "station_calendar_entry_ids_by_requirement_status"
      ) or
      link_capacity_actual_requirement_status_pressure?(
        summary,
        "station_calendar_provider_entry_ids_by_requirement_status"
      )
  end

  defp link_capacity_actual_requirement_status_pressure?(%{} = summary, key) do
    summary
    |> Map.get(key, %{})
    |> Enum.any?(fn {status, values} ->
      String.starts_with?(to_string(status), "actual_") and List.wrap(values) != []
    end)
  end

  defp resource_filter_branch_local_resource_filter_pressure?(%{} = summary) do
    resource_filter_branch_local_candidate_suppression_pressure?(summary) or
      resource_filter_branch_local_invalid_resource_summary_pressure?(summary) or
      resource_filter_branch_local_resource_blocking_pressure?(summary)
  end

  defp resource_filter_branch_local_candidate_suppression_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "suppressed_candidate_count") or
      map_size(Map.get(summary, "suppressed_reason_counts") || %{}) > 0 or
      map_size(Map.get(summary, "candidate_ids_by_spacecraft") || %{}) > 0 or
      map_size(Map.get(summary, "candidate_ids_by_resource") || %{}) > 0 or
      map_size(Map.get(summary, "candidate_ids_by_blocking_dimension") || %{}) > 0 or
      map_size(Map.get(summary, "candidate_ids_by_suppressed_reason") || %{}) > 0 or
      map_size(Map.get(summary, "direction_counts") || %{}) > 0 or
      list_values(summary, "directions") != [] or
      map_size(Map.get(summary, "candidate_ids_by_direction") || %{}) > 0 or
      map_size(Map.get(summary, "direction_routing") || %{}) > 0
  end

  defp resource_filter_branch_local_invalid_resource_summary_pressure?(%{} = summary) do
    positive_integer_observation?(summary, "invalid_resource_summary_input_count") or
      list_values(summary, "invalid_resource_summary_input_ids") != []
  end

  defp resource_filter_branch_local_resource_blocking_pressure?(%{} = summary) do
    map_size(Map.get(summary, "resource_filter_spacecraft_counts") || %{}) > 0 or
      map_size(Map.get(summary, "resource_filter_resource_counts") || %{}) > 0 or
      map_size(Map.get(summary, "resource_filter_blocking_dimension_counts") || %{}) > 0 or
      map_size(Map.get(summary, "candidate_ids_by_spacecraft") || %{}) > 0 or
      map_size(Map.get(summary, "candidate_ids_by_resource") || %{}) > 0 or
      map_size(Map.get(summary, "candidate_ids_by_blocking_dimension") || %{}) > 0
  end

  defp score_term_routing_pressure?(%{} = summary) do
    map_size(Map.get(summary, "ground_station_counts") || %{}) > 0 or
      map_size(Map.get(summary, "target_counts") || %{}) > 0 or
      map_size(Map.get(summary, "collection_counts") || %{}) > 0 or
      map_size(Map.get(summary, "source_activity_id_counts") || %{}) > 0
  end

  defp objective_gap_branch_local_objective_gap_pressure?(
         %{} = satisfaction_summary,
         %{} = tradeoff_summary,
         %{} = score_term_summary
       ) do
    objective_gap_branch_local_gap_pressure?([satisfaction_summary], "gap_row_count") or
      objective_gap_branch_local_gap_pressure?(
        [tradeoff_summary, score_term_summary],
        "downlink_gap_row_count"
      ) or
      objective_gap_branch_local_gap_pressure?(
        [tradeoff_summary, score_term_summary],
        "target_gap_row_count"
      ) or
      objective_gap_branch_local_gap_pressure?(
        [tradeoff_summary, score_term_summary],
        "collection_latency_gap_row_count"
      ) or
      objective_gap_branch_local_objective_status_pressure?(satisfaction_summary) or
      objective_gap_branch_local_score_term_pressure?(score_term_summary) or
      objective_gap_branch_local_routing_pressure?([
        satisfaction_summary,
        tradeoff_summary,
        score_term_summary
      ])
  end

  defp objective_gap_branch_local_gap_pressure?(summaries, key) when is_list(summaries) do
    Enum.any?(summaries, &positive_integer_observation?(&1, key))
  end

  defp objective_gap_branch_local_objective_status_pressure?(%{} = summary) do
    map_size(Map.get(summary, "status_counts") || %{}) > 0 or
      map_size(Map.get(summary, "objective_type_counts") || %{}) > 0
  end

  defp objective_gap_branch_local_score_term_pressure?(%{} = summary) do
    map_size(Map.get(summary, "term_key_counts") || %{}) > 0
  end

  defp objective_gap_branch_local_routing_pressure?(summaries) when is_list(summaries) do
    Enum.any?(summaries, fn summary ->
      map_size(Map.get(summary, "ground_station_counts") || %{}) > 0 or
        map_size(Map.get(summary, "target_counts") || %{}) > 0 or
        map_size(Map.get(summary, "collection_counts") || %{}) > 0 or
        map_size(Map.get(summary, "source_activity_id_counts") || %{}) > 0
    end)
  end

  defp positive_integer_observation?(%{} = summary, key) do
    case integer_observation_value(Map.get(summary, key)) do
      value when is_integer(value) -> value > 0
      _value -> false
    end
  end

  defp integer_observation_value(value) when is_integer(value), do: value
  defp integer_observation_value(value) when is_float(value), do: trunc(value)

  defp integer_observation_value(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {integer, ""} -> integer
      _parse_error -> nil
    end
  end

  defp integer_observation_value(_value), do: nil

  defp numeric_observation_value(value) when is_integer(value), do: value * 1.0
  defp numeric_observation_value(value) when is_float(value), do: value

  defp numeric_observation_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _parse_error -> nil
    end
  end

  defp numeric_observation_value(_value), do: nil

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), stringify_keys(value)}
      {key, value} when is_binary(key) -> {key, stringify_keys(value)}
      {key, value} -> {key, stringify_keys(value)}
    end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
