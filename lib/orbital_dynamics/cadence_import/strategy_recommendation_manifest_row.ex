defmodule OrbitalDynamics.CadenceImport.StrategyRecommendationManifestRow do
  @moduledoc false

  def build(row, rank, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:strategy_recommendation:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_strategy_recommendation",
      "import_status" => adapter_import_status(callbacks, import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(callbacks, row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "recommended_branch_id" => row["recommended_branch_id"] || row["branch_id"],
      "ranked_branch_ids" => row["ranked_branch_ids"],
      "tradeoff_count" => row["tradeoff_count"],
      "risk_count" => row["risk_count"],
      "risk_types" => row["risk_types"],
      "activity_ids" => row["activity_ids"],
      "scenario_ids" => row["scenario_ids"],
      "ground_station_ids" => row["ground_station_ids"],
      "spacecraft_ids" => row["spacecraft_ids"],
      "target_ids" => row["target_ids"],
      "collection_ids" => row["collection_ids"],
      "product_ids" => row["product_ids"],
      "payload_ids" => row["payload_ids"],
      "instrument_ids" => row["instrument_ids"],
      "objective_ids" => row["objective_ids"],
      "objective_types" => row["objective_types"],
      "feedback_sources" => row["feedback_sources"],
      "feedback_scopes" => row["feedback_scopes"],
      "source_activity_ids" => row["source_activity_ids"],
      "missed_downlink_activity_ids" => row["missed_downlink_activity_ids"],
      "directions" => row["directions"],
      "source_window_ids" => row["source_window_ids"],
      "source_window_types" => row["source_window_types"],
      "station_calendar_entry_ids" => row["station_calendar_entry_ids"],
      "station_calendar_provider_ids" => row["station_calendar_provider_ids"],
      "station_calendar_provider_entry_ids" => row["station_calendar_provider_entry_ids"],
      "station_calendar_directions" => row["station_calendar_directions"],
      "resource_pressure_statuses" => row["resource_pressure_statuses"],
      "resource_pressure_types" => row["resource_pressure_types"],
      "first_resource_pressure_kinds" => row["first_resource_pressure_kinds"],
      "operational_readiness_report_ids" => row["operational_readiness_report_ids"],
      "operational_readiness_source_artifact_types" =>
        row["operational_readiness_source_artifact_types"],
      "operational_readiness_source_artifact_ids" =>
        row["operational_readiness_source_artifact_ids"],
      "operational_readiness_levels" => row["operational_readiness_levels"],
      "operational_readiness_import_classifications" =>
        row["operational_readiness_import_classifications"],
      "operational_readiness_statuses" => row["operational_readiness_statuses"],
      "operational_readiness_gate_ids" => row["operational_readiness_gate_ids"],
      "operational_readiness_gate_statuses" => row["operational_readiness_gate_statuses"],
      "operational_readiness_gate_classifications" =>
        row["operational_readiness_gate_classifications"],
      "operational_readiness_required_operator_actions" =>
        row["operational_readiness_required_operator_actions"],
      "operational_readiness_feedback_sources" => row["operational_readiness_feedback_sources"],
      "operational_readiness_feedback_scopes" => row["operational_readiness_feedback_scopes"],
      "operational_readiness_feedback_keys" => row["operational_readiness_feedback_keys"],
      "operational_readiness_trust_boundaries" => row["operational_readiness_trust_boundaries"],
      "quality_gate_report_ids" => row["quality_gate_report_ids"],
      "quality_gate_source_artifact_types" => row["quality_gate_source_artifact_types"],
      "quality_gate_source_artifact_ids" => row["quality_gate_source_artifact_ids"],
      "quality_gate_source_readiness_report_ids" =>
        row["quality_gate_source_readiness_report_ids"],
      "quality_gate_readiness_levels" => row["quality_gate_readiness_levels"],
      "quality_gate_import_classifications" => row["quality_gate_import_classifications"],
      "quality_gate_pressure_statuses" => row["quality_gate_pressure_statuses"],
      "quality_gate_ids" => row["quality_gate_ids"],
      "quality_gate_statuses" => row["quality_gate_statuses"],
      "quality_gate_classifications" => row["quality_gate_classifications"],
      "quality_gate_required_operator_actions" => row["quality_gate_required_operator_actions"],
      "quality_gate_feedback_sources" => row["quality_gate_feedback_sources"],
      "quality_gate_feedback_scopes" => row["quality_gate_feedback_scopes"],
      "quality_gate_feedback_keys" => row["quality_gate_feedback_keys"],
      "quality_gate_trust_boundaries" => row["quality_gate_trust_boundaries"],
      "quality_gate_resource_availability_reason_ids" =>
        row["quality_gate_resource_availability_reason_ids"],
      "quality_gate_unavailable_resource_reason_ids" =>
        row["quality_gate_unavailable_resource_reason_ids"],
      "candidate_rejection_candidate_ids" => row["candidate_rejection_candidate_ids"],
      "candidate_rejection_activity_ids" => row["candidate_rejection_activity_ids"],
      "candidate_rejection_activity_types" => row["candidate_rejection_activity_types"],
      "candidate_rejection_scenario_ids" => row["candidate_rejection_scenario_ids"],
      "candidate_rejection_ground_station_ids" => row["candidate_rejection_ground_station_ids"],
      "candidate_rejection_source_window_ids" => row["candidate_rejection_source_window_ids"],
      "candidate_rejection_source_window_types" => row["candidate_rejection_source_window_types"],
      "candidate_rejection_statuses" => row["candidate_rejection_statuses"],
      "candidate_rejection_primary_reasons" => row["candidate_rejection_primary_reasons"],
      "candidate_rejection_reason_ids" => row["candidate_rejection_reason_ids"],
      "candidate_rejection_violated_constraints" =>
        row["candidate_rejection_violated_constraints"],
      "candidate_rejection_required_margin_values" =>
        row["candidate_rejection_required_margin_values"],
      "candidate_rejection_actual_margin_values" =>
        row["candidate_rejection_actual_margin_values"],
      "candidate_rejection_required_operator_actions" =>
        row["candidate_rejection_required_operator_actions"],
      "candidate_rejection_feedback_sources" => row["candidate_rejection_feedback_sources"],
      "candidate_rejection_feedback_scopes" => row["candidate_rejection_feedback_scopes"],
      "candidate_rejection_feedback_keys" => row["candidate_rejection_feedback_keys"],
      "candidate_rejection_trust_boundaries" => row["candidate_rejection_trust_boundaries"],
      "provider_counteroffer_ids" => row["provider_counteroffer_ids"],
      "provider_counteroffer_statuses" => row["provider_counteroffer_statuses"],
      "provider_counteroffer_negotiation_states" =>
        row["provider_counteroffer_negotiation_states"],
      "provider_counteroffer_reason_codes" => row["provider_counteroffer_reason_codes"],
      "provider_counteroffer_cost_deltas" => row["provider_counteroffer_cost_deltas"],
      "provider_counteroffer_lock_deadline_values_s" =>
        row["provider_counteroffer_lock_deadline_values_s"],
      "provider_counteroffer_starts_at_values_s" =>
        row["provider_counteroffer_starts_at_values_s"],
      "provider_counteroffer_ends_at_values_s" => row["provider_counteroffer_ends_at_values_s"],
      "provider_counteroffer_start_delta_values_s" =>
        row["provider_counteroffer_start_delta_values_s"],
      "provider_counteroffer_end_delta_values_s" =>
        row["provider_counteroffer_end_delta_values_s"],
      "provider_counteroffer_duration_delta_values_s" =>
        row["provider_counteroffer_duration_delta_values_s"],
      "provider_counteroffer_plan_impact_statuses" =>
        row["provider_counteroffer_plan_impact_statuses"],
      "provider_counteroffer_affected_station_calendar_entry_ids" =>
        row["provider_counteroffer_affected_station_calendar_entry_ids"],
      "provider_counteroffer_affected_provider_entry_ids" =>
        row["provider_counteroffer_affected_provider_entry_ids"],
      "provider_counteroffer_impact_counteroffer_ids" =>
        row["provider_counteroffer_impact_counteroffer_ids"],
      "provider_counteroffer_required_operator_actions" =>
        row["provider_counteroffer_required_operator_actions"],
      "provider_counteroffer_feedback_sources" => row["provider_counteroffer_feedback_sources"],
      "provider_counteroffer_feedback_scopes" => row["provider_counteroffer_feedback_scopes"],
      "provider_counteroffer_feedback_keys" => row["provider_counteroffer_feedback_keys"],
      "provider_counteroffer_trust_boundaries" => row["provider_counteroffer_trust_boundaries"],
      "approval_requirement_count" => row["approval_requirement_count"],
      "branch_event_count" => row["branch_event_count"],
      "branch_event_types" => row["branch_event_types"],
      "branch_event_trust_boundary_status_counts" =>
        row["branch_event_trust_boundary_status_counts"],
      "combined_source_branch_ids" => row["combined_source_branch_ids"],
      "branch_ground_station_ids" => row["branch_ground_station_ids"],
      "branch_scenario_ids" => row["branch_scenario_ids"],
      "branch_target_ids" => row["branch_target_ids"],
      "branch_collection_ids" => row["branch_collection_ids"],
      "branch_product_ids" => row["branch_product_ids"],
      "branch_payload_ids" => row["branch_payload_ids"],
      "branch_instrument_ids" => row["branch_instrument_ids"],
      "branch_objective_ids" => row["branch_objective_ids"],
      "branch_objective_types" => row["branch_objective_types"],
      "branch_objective_statuses" => row["branch_objective_statuses"],
      "branch_source_objective_statuses" => row["branch_source_objective_statuses"],
      "branch_feedback_sources" => row["branch_feedback_sources"],
      "branch_feedback_scopes" => row["branch_feedback_scopes"],
      "branch_contact_results" => row["branch_contact_results"],
      "branch_realized_statuses" => row["branch_realized_statuses"],
      "branch_transition_types" => row["branch_transition_types"],
      "branch_transition_categories" => row["branch_transition_categories"],
      "branch_transition_reasons" => row["branch_transition_reasons"],
      "branch_requires_operator_review" => row["branch_requires_operator_review"],
      "branch_requires_operator_review_count" => row["branch_requires_operator_review_count"],
      "branch_missed_downlink_activity_ids" => row["branch_missed_downlink_activity_ids"],
      "branch_maneuver_execution_uncertainty_activity_ids" =>
        row["branch_maneuver_execution_uncertainty_activity_ids"],
      "branch_maneuver_execution_uncertainty_timeline_ids" =>
        row["branch_maneuver_execution_uncertainty_timeline_ids"],
      "branch_maneuver_execution_uncertainty_maneuver_ids" =>
        row["branch_maneuver_execution_uncertainty_maneuver_ids"],
      "branch_maneuver_execution_uncertainty_statuses" =>
        row["branch_maneuver_execution_uncertainty_statuses"],
      "branch_maneuver_execution_uncertainty_sources" =>
        row["branch_maneuver_execution_uncertainty_sources"],
      "branch_maneuver_execution_uncertainty_max_timing_3sigma_s" =>
        row["branch_maneuver_execution_uncertainty_max_timing_3sigma_s"],
      "branch_maneuver_execution_uncertainty_max_delta_v_3sigma_magnitude_km_s" =>
        row["branch_maneuver_execution_uncertainty_max_delta_v_3sigma_magnitude_km_s"],
      "branch_timeline_integrity_activity_ids" => row["branch_timeline_integrity_activity_ids"],
      "branch_timeline_integrity_timeline_ids" => row["branch_timeline_integrity_timeline_ids"],
      "branch_missing_dependency_activity_ids" => row["branch_missing_dependency_activity_ids"],
      "branch_missing_dependency_timeline_ids" => row["branch_missing_dependency_timeline_ids"],
      "branch_dependency_cycle_activity_ids" => row["branch_dependency_cycle_activity_ids"],
      "branch_dependency_cycle_timeline_ids" => row["branch_dependency_cycle_timeline_ids"],
      "branch_dependency_order_violation_activity_ids" =>
        row["branch_dependency_order_violation_activity_ids"],
      "branch_dependency_order_violation_timeline_ids" =>
        row["branch_dependency_order_violation_timeline_ids"],
      "branch_exclusivity_violation_activity_ids" =>
        row["branch_exclusivity_violation_activity_ids"],
      "branch_exclusivity_violation_timeline_ids" =>
        row["branch_exclusivity_violation_timeline_ids"],
      "branch_exclusivity_violation_groups" => row["branch_exclusivity_violation_groups"],
      "branch_source_activity_ids" => row["branch_source_activity_ids"],
      "branch_source_window_ids" => row["branch_source_window_ids"],
      "branch_source_window_count" => row["branch_source_window_count"],
      "branch_source_window_bounds" => row["branch_source_window_bounds"],
      "branch_source_window_bound_count" => row["branch_source_window_bound_count"],
      "branch_untimed_source_window_ids" => row["branch_untimed_source_window_ids"],
      "branch_untimed_source_window_count" => row["branch_untimed_source_window_count"],
      "branch_partially_timed_source_window_ids" =>
        row["branch_partially_timed_source_window_ids"],
      "branch_partially_timed_source_window_count" =>
        row["branch_partially_timed_source_window_count"],
      "branch_source_window_timing_coverage_status" =>
        row["branch_source_window_timing_coverage_status"],
      "branch_earliest_starts_at_s" => row["branch_earliest_starts_at_s"],
      "branch_latest_ends_at_s" => row["branch_latest_ends_at_s"],
      "branch_directions" => row["branch_directions"],
      "branch_station_availabilities" => row["branch_station_availabilities"],
      "branch_station_contention_statuses" => row["branch_station_contention_statuses"],
      "branch_station_calendar_entry_ids" => row["branch_station_calendar_entry_ids"],
      "branch_station_calendar_provider_ids" => row["branch_station_calendar_provider_ids"],
      "branch_station_calendar_provider_entry_ids" =>
        row["branch_station_calendar_provider_entry_ids"],
      "branch_station_calendar_directions" => row["branch_station_calendar_directions"],
      "branch_station_calendar_statuses" => row["branch_station_calendar_statuses"],
      "branch_station_calendar_trust_boundary_statuses" =>
        row["branch_station_calendar_trust_boundary_statuses"],
      "branch_station_reservation_ids" => row["branch_station_reservation_ids"],
      "branch_station_reserved_by" => row["branch_station_reserved_by"],
      "branch_station_reservation_statuses" => row["branch_station_reservation_statuses"],
      "branch_station_reservation_match_statuses" =>
        row["branch_station_reservation_match_statuses"],
      "branch_image_quality_min_score" => row["branch_image_quality_min_score"],
      "branch_image_quality_statuses" => row["branch_image_quality_statuses"],
      "branch_image_quality_sources" => row["branch_image_quality_sources"],
      "branch_cloud_cover_max_fraction" => row["branch_cloud_cover_max_fraction"],
      "branch_blur_max_score" => row["branch_blur_max_score"],
      "branch_max_latency_s" => row["branch_max_latency_s"],
      "branch_planned_latency_s" => row["branch_planned_latency_s"],
      "branch_required_contacts" => row["branch_required_contacts"],
      "branch_planned_contacts" => row["branch_planned_contacts"],
      "branch_required_downlink_mb" => row["branch_required_downlink_mb"],
      "branch_planned_downlink_mb" => row["branch_planned_downlink_mb"],
      "capacity_pack_group_ids" => row["capacity_pack_group_ids"],
      "capacity_pack_statuses" => row["capacity_pack_statuses"],
      "capacity_pack_min_capacity_fraction" => row["capacity_pack_min_capacity_fraction"],
      "capacity_pack_max_used_fraction" => row["capacity_pack_max_used_fraction"],
      "capacity_pack_max_required_capacity_fraction" =>
        row["capacity_pack_max_required_capacity_fraction"],
      "capacity_pack_total_required_capacity_fraction" =>
        row["capacity_pack_total_required_capacity_fraction"],
      "capacity_pack_required_capacity_sources" => row["capacity_pack_required_capacity_sources"],
      "operational_feedback_trust_boundary_status" =>
        row["operational_feedback_trust_boundary_status"],
      "operational_feedback_trust_boundary" => row["operational_feedback_trust_boundary"],
      "operational_feedback_trust_boundaries" => row["operational_feedback_trust_boundaries"],
      "operational_feedback_field_trust_boundaries" =>
        row["operational_feedback_field_trust_boundaries"],
      "operational_feedback_input_keys" => row["operational_feedback_input_keys"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_recommendation" => row["source_recommendation"],
      "source_operational_feedback" => row["source_operational_feedback"],
      "source_operational_feedback_provenance" => row["source_operational_feedback_provenance"],
      "source_review_row" => row
    }
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.validation_refresh_context_keys())
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.approval_boundary_context_keys())
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.provider_reservation_request_context_keys()
      )
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.capacity_pack_context_keys())
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.contact_contention_resolution_context_keys()
      )
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.contact_contention_context_keys())
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.station_reservation_conflict_context_keys()
      )
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.station_reservation_hold_import_readiness_context_keys()
      )
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.relay_data_path_context_keys())
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.link_capacity_context_keys())
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.contact_intent_context_keys())
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.contact_allocation_context_keys())
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.contact_filter_context_keys())
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.resource_filter_context_keys())
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.resource_projection_context_keys())
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.station_calendar_context_keys())
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.score_term_context_keys())
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.objective_satisfaction_context_keys()
      )
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.objective_tradeoff_context_keys())
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.resource_margin_context_keys())
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.maneuver_execution_uncertainty_context_keys()
      )
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.timeline_integrity_context_keys())
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.execution_success_feedback_context_keys()
      )
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.operational_feedback_context_keys())
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.timeline_activity_precondition_context_keys()
      )
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.timeline_activity_lifecycle_state_context_keys()
      )
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.timeline_dependency_impact_context_keys()
      )
    )
    |> Map.merge(
      Map.take(row, OrbitalDynamics.RecommendationRiskContext.timeline_publication_context_keys())
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.timeline_lifecycle_state_context_keys()
      )
    )
    |> Map.merge(
      Map.take(
        row,
        OrbitalDynamics.RecommendationRiskContext.timeline_preservation_context_keys()
      )
    )
    |> Map.merge(Map.take(row, branch_timeline_evidence_fields(callbacks)))
    |> Map.merge(Map.take(row, branch_readiness_quality_gate_fields(callbacks)))
    |> Map.merge(Map.take(row, branch_contact_allocation_fields(callbacks)))
    |> compact_map(callbacks)
  end

  defp source_review_action(callbacks, row),
    do: invoke(callbacks, :source_review_action, [row])

  defp adapter_import_status(callbacks, status, approval_status),
    do: invoke(callbacks, :adapter_import_status, [status, approval_status])

  defp branch_timeline_evidence_fields(callbacks),
    do: invoke(callbacks, :branch_timeline_evidence_fields, [])

  defp branch_readiness_quality_gate_fields(callbacks),
    do: invoke(callbacks, :branch_readiness_quality_gate_fields, [])

  defp branch_contact_allocation_fields(callbacks),
    do: invoke(callbacks, :branch_contact_allocation_fields, [])

  defp compact_map(value, callbacks), do: invoke(callbacks, :compact_map, [value])

  defp invoke(callbacks, name, args), do: apply(Keyword.fetch!(callbacks, name), args)
end
