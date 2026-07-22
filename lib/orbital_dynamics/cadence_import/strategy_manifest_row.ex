defmodule OrbitalDynamics.CadenceImport.StrategyManifestRow do
  @moduledoc false

  def build(row, recommendation, rank, operational_feedback_context, callbacks)
      when is_list(callbacks) do
    branch_id = row["branch_id"]
    selected? = Map.get(row, "selected", false)
    approval_status = Map.get(row, "approval_status") || recommendation["approval_status"]

    %{
      "id" => "cadence_import:strategy_branch:#{branch_id || rank}",
      "rank" => rank,
      "import_action" =>
        if(selected?,
          do: "import_strategy_recommendation",
          else: "review_strategy_branch_alternative"
        ),
      "import_status" => strategy_import_status(selected?, approval_status),
      "import_side" => "source",
      "source_review_row_id" => Map.get(row, "id") || "branch_comparison:#{branch_id || rank}",
      "source_review_type" => "strategy_branch_comparison",
      "source_review_action" =>
        if(selected?, do: "review_strategy_recommendation", else: "review_branch_comparison"),
      "subject_id" => branch_id,
      "branch_id" => branch_id,
      "recommended_branch_id" => recommendation["recommended_branch_id"],
      "approval_status" => approval_status,
      "required_operator_action" =>
        if(selected?, do: "review_strategy_recommendation", else: "review_branch_comparison"),
      "cadence_import_status" => "not_applicable",
      "has_cadence_import" => false,
      "selected" => selected?,
      "score" => row["score"],
      "score_delta_from_recommended" => row["score_delta_from_recommended"],
      "raw_score" => row["raw_score"],
      "branch_probability" => row["branch_probability"],
      "expected_score" => row["expected_score"],
      "risk_count" => row["risk_count"],
      "risk_types" => row["risk_types"],
      "high_risk_types" => row["high_risk_types"],
      "approval_requirement_count" => row["approval_requirement_count"],
      "repair_delta_count" => row["repair_delta_count"],
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
      "branch_actual_downlink_completion_ratio" => row["branch_actual_downlink_completion_ratio"],
      "capacity_pack_group_ids" => row["capacity_pack_group_ids"],
      "capacity_pack_statuses" => row["capacity_pack_statuses"],
      "capacity_pack_min_capacity_fraction" => row["capacity_pack_min_capacity_fraction"],
      "capacity_pack_max_used_fraction" => row["capacity_pack_max_used_fraction"],
      "capacity_pack_max_required_capacity_fraction" =>
        row["capacity_pack_max_required_capacity_fraction"],
      "capacity_pack_total_required_capacity_fraction" =>
        row["capacity_pack_total_required_capacity_fraction"],
      "capacity_pack_required_capacity_sources" => row["capacity_pack_required_capacity_sources"],
      "capacity_pack_contact_ids_by_direction" => row["capacity_pack_contact_ids_by_direction"],
      "capacity_pack_selected_contact_ids_by_direction" =>
        row["capacity_pack_selected_contact_ids_by_direction"],
      "capacity_pack_deferred_contact_ids_by_direction" =>
        row["capacity_pack_deferred_contact_ids_by_direction"],
      "capacity_pack_required_capacity_fraction_by_direction" =>
        row["capacity_pack_required_capacity_fraction_by_direction"],
      "capacity_pack_selected_required_capacity_fraction_by_direction" =>
        row["capacity_pack_selected_required_capacity_fraction_by_direction"],
      "capacity_pack_deferred_required_capacity_fraction_by_direction" =>
        row["capacity_pack_deferred_required_capacity_fraction_by_direction"],
      "target_branch_base_id" => row["target_branch_base_id"],
      "target_branch_identity" => row["target_branch_identity"],
      "priority_commitment_required_target_count" =>
        row["priority_commitment_required_target_count"],
      "priority_commitment_satisfied_target_count" =>
        row["priority_commitment_satisfied_target_count"],
      "priority_commitment_missed_target_count" => row["priority_commitment_missed_target_count"],
      "priority_commitment_required_target_ids" => row["priority_commitment_required_target_ids"],
      "priority_commitment_satisfied_target_ids" =>
        row["priority_commitment_satisfied_target_ids"],
      "priority_commitment_missed_target_ids" => row["priority_commitment_missed_target_ids"],
      "priority_commitment_required_observation_count" =>
        row["priority_commitment_required_observation_count"],
      "priority_commitment_planned_observation_count" =>
        row["priority_commitment_planned_observation_count"],
      "priority_commitment_missing_observation_count" =>
        row["priority_commitment_missing_observation_count"],
      "priority_commitment_ratio" => row["priority_commitment_ratio"],
      "downlink_completion_required_contacts" => row["downlink_completion_required_contacts"],
      "downlink_completion_planned_contacts" => row["downlink_completion_planned_contacts"],
      "downlink_completion_required_downlink_mb" =>
        row["downlink_completion_required_downlink_mb"],
      "downlink_completion_planned_downlink_mb" => row["downlink_completion_planned_downlink_mb"],
      "downlink_completion_ratio" => row["downlink_completion_ratio"],
      "coverage_observed_target_count" => row["coverage_observed_target_count"],
      "revisit_count" => row["revisit_count"],
      "collection_latency_ratio" => row["collection_latency_ratio"],
      "collection_latency_objective_count" => row["collection_latency_objective_count"],
      "collection_latency_observation_count" => row["collection_latency_observation_count"],
      "collection_latency_satisfied_observation_count" =>
        row["collection_latency_satisfied_observation_count"],
      "collection_latency_unsatisfied_observation_count" =>
        row["collection_latency_unsatisfied_observation_count"],
      "feedback_score_adjustment" => row["feedback_score_adjustment"],
      "contact_success_factor" => row["contact_success_factor"],
      "contact_success_factor_source" => row["contact_success_factor_source"],
      "contact_success_factor_activity_source" => row["contact_success_factor_activity_source"],
      "observation_success_factor" => row["observation_success_factor"],
      "observation_success_factor_source" => row["observation_success_factor_source"],
      "observation_success_factor_activity_source" =>
        row["observation_success_factor_activity_source"],
      "maneuver_success_factor" => row["maneuver_success_factor"],
      "maneuver_success_factor_source" => row["maneuver_success_factor_source"],
      "command_success_factor" => row["command_success_factor"],
      "command_success_factor_source" => row["command_success_factor_source"],
      "station_throughput_factor" => row["station_throughput_factor"],
      "station_throughput_factor_source" => row["station_throughput_factor_source"],
      "station_throughput_factor_activity_source" =>
        row["station_throughput_factor_activity_source"],
      "feedback_risk_types" => row["feedback_risk_types"],
      "fuel_margin" => row["fuel_margin"],
      "thermal_margin_c" => row["thermal_margin_c"],
      "power_margin" => row["power_margin"],
      "storage_margin" => row["storage_margin"],
      "downlink_capacity_margin" => row["downlink_capacity_margin"],
      "spacecraft_availability" => row["spacecraft_availability"],
      "payload_availability" => row["payload_availability"],
      "antenna_availability" => row["antenna_availability"],
      "resource_score_adjustment" => row["resource_score_adjustment"],
      "fuel_preservation_mode" => row["fuel_preservation_mode"],
      "resource_risk_types" => row["resource_risk_types"],
      "resource_pressure_statuses" => row["resource_pressure_statuses"],
      "resource_pressure_types" => row["resource_pressure_types"],
      "projected_storage_remaining_mb" => row["projected_storage_remaining_mb"],
      "projected_downlink_remaining_mb" => row["projected_downlink_remaining_mb"],
      "first_resource_pressure_kinds" => row["first_resource_pressure_kinds"],
      "first_resource_pressure_activity_id" => row["first_resource_pressure_activity_id"],
      "first_resource_pressure_activity_type" => row["first_resource_pressure_activity_type"],
      "first_resource_pressure_kind" => row["first_resource_pressure_kind"],
      "first_resource_pressure_starts_at_s" => row["first_resource_pressure_starts_at_s"],
      "first_resource_pressure_direction" => row["first_resource_pressure_direction"],
      "first_resource_pressure_ground_station_id" =>
        row["first_resource_pressure_ground_station_id"],
      "first_resource_pressure_station_calendar_entry_id" =>
        row["first_resource_pressure_station_calendar_entry_id"],
      "first_resource_pressure_station_calendar_provider_id" =>
        row["first_resource_pressure_station_calendar_provider_id"],
      "first_resource_pressure_station_calendar_provider_entry_id" =>
        row["first_resource_pressure_station_calendar_provider_entry_id"],
      "first_resource_pressure_station_calendar_directions" =>
        row["first_resource_pressure_station_calendar_directions"],
      "first_resource_pressure_capacity_fraction" =>
        row["first_resource_pressure_capacity_fraction"],
      "first_resource_pressure_source_window_id" =>
        row["first_resource_pressure_source_window_id"],
      "first_resource_pressure_source_window_type" =>
        row["first_resource_pressure_source_window_type"],
      "first_resource_pressure_source_window" => row["first_resource_pressure_source_window"],
      "source_window_id" =>
        row["source_window_id"] || row["first_resource_pressure_source_window_id"],
      "source_window_type" =>
        row["source_window_type"] || row["first_resource_pressure_source_window_type"],
      "source_window" => row["source_window"] || row["first_resource_pressure_source_window"],
      "repair_score" => row["repair_score"],
      "repair_activity_score" => row["repair_activity_score"],
      "repair_schedule_churn_penalty" => row["repair_schedule_churn_penalty"],
      "repair_schedule_move_penalty" => row["repair_schedule_move_penalty"],
      "repair_score_term_keys" => row["repair_score_term_keys"],
      "repair_link_selected_estimated_throughput_mb" =>
        row["repair_link_selected_estimated_throughput_mb"],
      "repair_link_selected_capacity_adjusted_throughput_mb" =>
        row["repair_link_selected_capacity_adjusted_throughput_mb"],
      "repair_link_required_downlink_mb" => row["repair_link_required_downlink_mb"],
      "repair_link_selected_downlink_shortfall_mb" =>
        row["repair_link_selected_downlink_shortfall_mb"],
      "repair_link_downlink_requirement_status" => row["repair_link_downlink_requirement_status"],
      "repair_link_actual_throughput_mb" => row["repair_link_actual_throughput_mb"],
      "repair_link_actual_downlink_completion_ratio" =>
        row["repair_link_actual_downlink_completion_ratio"],
      "repair_link_actual_downlink_shortfall_mb" =>
        row["repair_link_actual_downlink_shortfall_mb"],
      "repair_link_actual_downlink_requirement_status" =>
        row["repair_link_actual_downlink_requirement_status"],
      "repair_constraint_count" => row["repair_constraint_count"],
      "repair_constraint_row_count" => row["repair_constraint_row_count"],
      "repair_constraint_status" => row["repair_constraint_status"],
      "repair_constraint_pass_count" => row["repair_constraint_pass_count"],
      "repair_constraint_warning_count" => row["repair_constraint_warning_count"],
      "repair_constraint_fail_count" => row["repair_constraint_fail_count"],
      "repair_constraint_failed_ids" => row["repair_constraint_failed_ids"],
      "repair_constraint_warning_ids" => row["repair_constraint_warning_ids"],
      "source_branch_comparison" => row,
      "source_recommendation" => recommendation
    }
    |> OrbitalDynamics.CadenceImport.StrategyRecommendationContext.merge(
      if(selected?,
        do:
          OrbitalDynamics.CadenceImport.StrategyRecommendationContext.risk(
            recommendation,
            stringify_keys: stringify_keys(callbacks)
          ),
        else: %{}
      )
    )
    |> OrbitalDynamics.CadenceImport.StrategyRecommendationContext.merge(
      if(selected?,
        do:
          OrbitalDynamics.CadenceImport.StrategyRecommendationContext.resource_pressure(
            recommendation,
            stringify_keys: stringify_keys(callbacks)
          ),
        else: %{}
      )
    )
    |> OrbitalDynamics.CadenceImport.StrategyRecommendationContext.merge(
      if(selected?,
        do:
          OrbitalDynamics.CadenceImport.StrategyRecommendationContext.readiness_quality_gate(
            recommendation,
            stringify_keys: stringify_keys(callbacks)
          ),
        else: %{}
      )
    )
    |> Map.merge(Map.take(row, branch_timeline_evidence_fields(callbacks)))
    |> Map.merge(Map.take(row, branch_readiness_quality_gate_fields(callbacks)))
    |> Map.merge(Map.take(row, branch_contact_allocation_fields(callbacks)))
    |> Map.merge(operational_feedback_context)
    |> compact_map(callbacks)
  end

  defp strategy_import_status(false, _approval_status), do: "not_applicable"
  defp strategy_import_status(true, "auto_approvable"), do: "ready_for_import"
  defp strategy_import_status(true, "not_required"), do: "ready_for_import"
  defp strategy_import_status(true, _approval_status), do: "review_required_before_import"

  defp branch_timeline_evidence_fields(callbacks),
    do: invoke(callbacks, :branch_timeline_evidence_fields, [])

  defp branch_readiness_quality_gate_fields(callbacks),
    do: invoke(callbacks, :branch_readiness_quality_gate_fields, [])

  defp branch_contact_allocation_fields(callbacks),
    do: invoke(callbacks, :branch_contact_allocation_fields, [])

  defp stringify_keys(callbacks), do: Keyword.fetch!(callbacks, :stringify_keys)

  defp compact_map(value, callbacks), do: invoke(callbacks, :compact_map, [value])

  defp invoke(callbacks, name, args), do: apply(Keyword.fetch!(callbacks, name), args)
end
