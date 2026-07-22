defmodule OrbitalDynamics.CampaignPlanner.BranchComparisonContext do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.PlanBranch
  alias __MODULE__.RiskFields
  alias __MODULE__.TimelineFields

  import __MODULE__.FieldValues

  def event_fields(branch), do: branch_comparison_event_fields(branch)

  def risk_fields(risk_indicators), do: RiskFields.fields(risk_indicators)

  defp branch_comparison_event_fields(%PlanBranch{events: events}) do
    event_types =
      events
      |> Enum.map(&Map.get(&1, "type"))
      |> Enum.map(&encode_value/1)
      |> Enum.filter(&(is_binary(&1) and &1 != ""))
      |> Enum.uniq()
      |> Enum.sort()

    source_branch_ids =
      events
      |> Enum.flat_map(fn event ->
        event
        |> Map.get("source_branch_ids", List.wrap(Map.get(event, "source_branch_id")))
        |> List.wrap()
      end)
      |> Enum.map(&encode_value/1)
      |> Enum.filter(&(is_binary(&1) and &1 != ""))
      |> Enum.uniq()
      |> Enum.sort()

    fields =
      %{
        "branch_event_count" => length(events),
        "branch_event_types" => event_types,
        "branch_event_trust_boundary_status_counts" =>
          branch_event_trust_boundary_status_counts(events),
        "branch_station_availabilities" => branch_event_station_availabilities(events),
        "branch_station_contention_statuses" =>
          branch_event_unique_values(events, ["station_contention_status", "contention_status"]),
        "branch_ground_station_ids" =>
          branch_event_unique_values(events, ["ground_station_id", "station_id"]),
        "branch_scenario_ids" => branch_event_unique_values(events, "scenario_id"),
        "branch_target_ids" => branch_event_unique_values(events, "target_id"),
        "branch_collection_ids" =>
          branch_event_unique_values(events, ["collection_id", "collection_ids"]),
        "branch_product_ids" => branch_event_unique_values(events, ["product_id", "product_ids"]),
        "branch_payload_ids" => branch_event_unique_values(events, ["payload_id", "payload_ids"]),
        "branch_instrument_ids" =>
          branch_event_unique_values(events, ["instrument_id", "instrument_ids"]),
        "branch_objective_ids" =>
          branch_event_unique_values(events, ["objective_id", "objective_ids"]),
        "branch_objective_types" => branch_event_unique_values(events, "objective_type"),
        "branch_objective_statuses" => branch_event_unique_values(events, "objective_status"),
        "branch_source_objective_statuses" =>
          branch_event_unique_values(events, "source_objective_status"),
        "branch_feedback_sources" => branch_event_unique_values(events, "feedback_source"),
        "branch_feedback_scopes" => branch_event_unique_values(events, "feedback_scope"),
        "branch_contact_results" => branch_event_unique_values(events, "contact_result"),
        "branch_contact_allocation_statuses" =>
          branch_event_unique_values(events, "allocation_status"),
        "branch_contact_allocation_effective_statuses" =>
          branch_event_unique_values(events, "effective_allocation_status"),
        "branch_contact_allocation_reasons" =>
          branch_event_unique_values(events, "allocation_reason"),
        "branch_contact_allocation_review_statuses" =>
          branch_event_unique_values(events, "review_status"),
        "branch_contact_allocation_approval_statuses" =>
          branch_event_unique_values(events, "approval_status"),
        "branch_contact_allocation_policy_classifications" =>
          branch_event_unique_values(events, "policy_classification"),
        "branch_realized_statuses" => branch_event_unique_values(events, "realized_status"),
        "branch_transition_types" => branch_event_transition_values(events, "transition_type"),
        "branch_transition_categories" =>
          branch_event_transition_values(events, "transition_category"),
        "branch_transition_reasons" =>
          branch_event_transition_values(events, "transition_reason"),
        "branch_requires_operator_review" => branch_event_requires_operator_review(events),
        "branch_requires_operator_review_count" => branch_event_operator_review_count(events),
        "branch_operational_readiness_levels" =>
          branch_operational_readiness_unique_values(events, "readiness_level"),
        "branch_operational_readiness_import_classifications" =>
          branch_operational_readiness_unique_values(events, "import_classification"),
        "branch_operational_readiness_statuses" =>
          branch_operational_readiness_unique_values(events, "operational_readiness_status"),
        "branch_operational_readiness_gate_ids" =>
          branch_operational_readiness_unique_values(events, "readiness_gate_id"),
        "branch_operational_readiness_gate_statuses" =>
          branch_operational_readiness_unique_values(events, "readiness_gate_status"),
        "branch_operational_readiness_gate_classifications" =>
          branch_operational_readiness_unique_values(events, "readiness_gate_classification"),
        "branch_operational_readiness_review_required_gate_ids" =>
          branch_operational_readiness_unique_values(events, "review_required_gate_ids"),
        "branch_operational_readiness_analysis_only_gate_ids" =>
          branch_operational_readiness_unique_values(events, "analysis_only_gate_ids"),
        "branch_operational_readiness_blocked_gate_ids" =>
          branch_operational_readiness_unique_values(events, "blocked_gate_ids"),
        "branch_operational_readiness_non_passed_gate_ids" =>
          branch_operational_readiness_unique_values(events, "non_passed_gate_ids"),
        "branch_missed_downlink_activity_ids" =>
          branch_event_unique_values(events, [
            "missed_downlink_activity_id",
            "missed_downlink_activity_ids"
          ]),
        "branch_maneuver_execution_uncertainty_activity_ids" =>
          branch_maneuver_execution_uncertainty_unique_values(events, "activity_id"),
        "branch_maneuver_execution_uncertainty_timeline_ids" =>
          branch_maneuver_execution_uncertainty_unique_values(events, "timeline_id"),
        "branch_maneuver_execution_uncertainty_maneuver_ids" =>
          branch_maneuver_execution_uncertainty_unique_values(events, "maneuver_id"),
        "branch_maneuver_execution_uncertainty_statuses" =>
          branch_maneuver_execution_uncertainty_unique_values(
            events,
            "execution_uncertainty_status"
          ),
        "branch_maneuver_execution_uncertainty_sources" =>
          branch_maneuver_execution_uncertainty_unique_values(
            events,
            "execution_uncertainty_source"
          ),
        "branch_maneuver_execution_uncertainty_max_timing_3sigma_s" =>
          branch_maneuver_execution_uncertainty_maximum_present(events, "timing_3sigma_s"),
        "branch_maneuver_execution_uncertainty_max_delta_v_3sigma_magnitude_km_s" =>
          branch_maneuver_execution_uncertainty_maximum_present(
            events,
            "delta_v_3sigma_magnitude_km_s"
          ),
        "branch_source_activity_ids" =>
          branch_event_unique_values(events, ["source_activity_id", "source_activity_ids"]),
        "branch_directions" => branch_event_unique_values(events, "direction"),
        "branch_station_calendar_entry_ids" =>
          branch_event_unique_values(events, [
            "station_calendar_entry_id",
            "station_calendar_entry_ids"
          ]),
        "branch_station_calendar_provider_ids" =>
          branch_event_unique_values(events, [
            "station_calendar_provider_id",
            "station_calendar_provider_ids"
          ]),
        "branch_station_calendar_provider_entry_ids" =>
          branch_event_unique_values(events, [
            "station_calendar_provider_entry_id",
            "station_calendar_provider_entry_ids"
          ]),
        "branch_station_calendar_directions" =>
          branch_event_unique_values(events, [
            "station_calendar_direction",
            "station_calendar_directions"
          ]),
        "branch_station_calendar_statuses" =>
          branch_event_unique_values(events, ["station_calendar_status", "calendar_status"]),
        "branch_station_calendar_trust_boundary_statuses" =>
          branch_event_unique_values(events, "station_calendar_trust_boundary_status"),
        "branch_station_reservation_ids" =>
          branch_event_unique_values(events, [
            "station_reservation_id",
            "reservation_id",
            "station_calendar_reservation_ids"
          ]),
        "branch_station_reserved_by" =>
          branch_event_unique_values(events, ["station_reserved_by", "reserved_by"]),
        "branch_station_reservation_statuses" =>
          branch_event_unique_values(events, [
            "station_reservation_status",
            "reservation_status"
          ]),
        "branch_station_reservation_match_statuses" =>
          branch_event_unique_values(events, [
            "station_reservation_match_status",
            "reservation_match_status"
          ]),
        "branch_station_reservation_expiration_statuses" =>
          branch_event_unique_values(events, [
            "station_reservation_expiration_status",
            "station_reservation_expiration_statuses"
          ]),
        "branch_station_reservation_conflict_contact_ids" =>
          branch_station_reservation_conflict_unique_values(events, [
            "contact_id",
            "source_activity_id",
            "source_activity_ids"
          ]),
        "branch_station_reservation_conflict_reservation_ids" =>
          branch_station_reservation_conflict_unique_values(events, [
            "station_reservation_id",
            "reservation_id"
          ]),
        "branch_station_reservation_conflict_match_statuses" =>
          branch_station_reservation_conflict_match_statuses(events, [
            "station_reservation_match_status",
            "reservation_match_status"
          ]),
        "branch_image_quality_min_score" => minimum_present(events, "image_quality_score"),
        "branch_image_quality_statuses" =>
          branch_event_unique_values(events, "image_quality_status"),
        "branch_image_quality_sources" =>
          branch_event_unique_values(events, "image_quality_source"),
        "branch_cloud_cover_max_fraction" => maximum_present(events, "cloud_cover_fraction"),
        "branch_blur_max_score" => maximum_present(events, "blur_score"),
        "branch_max_latency_s" => maximum_present(events, "max_latency_s"),
        "branch_planned_latency_s" => maximum_present(events, "planned_latency_s"),
        "branch_required_contacts" => maximum_present(events, "required_contacts"),
        "branch_planned_contacts" => maximum_present(events, "planned_contacts"),
        "branch_required_downlink_mb" => maximum_present(events, "required_downlink_mb"),
        "branch_planned_downlink_mb" => maximum_present(events, "planned_downlink_mb"),
        "branch_actual_downlink_completion_ratio" =>
          minimum_present(events, "actual_downlink_completion_ratio"),
        "capacity_pack_group_ids" => branch_event_unique_values(events, "capacity_pack_group_id"),
        "capacity_pack_statuses" => branch_event_unique_values(events, "capacity_pack_status"),
        "capacity_pack_min_capacity_fraction" =>
          minimum_present(events, "capacity_pack_capacity_fraction"),
        "capacity_pack_max_used_fraction" =>
          maximum_present(events, "capacity_pack_used_fraction"),
        "capacity_pack_max_required_capacity_fraction" =>
          maximum_present(events, "required_capacity_fraction"),
        "capacity_pack_total_required_capacity_fraction" =>
          sum_present(events, "required_capacity_fraction"),
        "capacity_pack_required_capacity_sources" =>
          branch_event_unique_values(events, "required_capacity_fraction_source"),
        "capacity_pack_contact_ids_by_direction" =>
          branch_event_merged_maps(events, "capacity_pack_contact_ids_by_direction"),
        "capacity_pack_selected_contact_ids_by_direction" =>
          branch_event_merged_maps(events, "capacity_pack_selected_contact_ids_by_direction"),
        "capacity_pack_deferred_contact_ids_by_direction" =>
          branch_event_merged_maps(events, "capacity_pack_deferred_contact_ids_by_direction"),
        "capacity_pack_required_capacity_fraction_by_direction" =>
          branch_event_merged_numeric_maps(
            events,
            "capacity_pack_required_capacity_fraction_by_direction"
          ),
        "capacity_pack_selected_required_capacity_fraction_by_direction" =>
          branch_event_merged_numeric_maps(
            events,
            "capacity_pack_selected_required_capacity_fraction_by_direction"
          ),
        "capacity_pack_deferred_required_capacity_fraction_by_direction" =>
          branch_event_merged_numeric_maps(
            events,
            "capacity_pack_deferred_required_capacity_fraction_by_direction"
          )
      }
      |> Map.merge(TimelineFields.fields(events))

    fields
    |> maybe_put_nonempty("branch_event_trust_boundary_status_counts")
    |> maybe_put_nonempty("branch_station_availabilities")
    |> maybe_put_nonempty("branch_station_contention_statuses")
    |> maybe_put_nonempty("branch_ground_station_ids")
    |> maybe_put_nonempty("branch_scenario_ids")
    |> maybe_put_nonempty("branch_target_ids")
    |> maybe_put_nonempty("branch_collection_ids")
    |> maybe_put_nonempty("branch_product_ids")
    |> maybe_put_nonempty("branch_payload_ids")
    |> maybe_put_nonempty("branch_instrument_ids")
    |> maybe_put_nonempty("branch_objective_ids")
    |> maybe_put_nonempty("branch_objective_types")
    |> maybe_put_nonempty("branch_objective_statuses")
    |> maybe_put_nonempty("branch_source_objective_statuses")
    |> maybe_put_nonempty("branch_feedback_sources")
    |> maybe_put_nonempty("branch_feedback_scopes")
    |> maybe_put_nonempty("branch_contact_results")
    |> maybe_put_nonempty("capacity_pack_contact_ids_by_direction")
    |> maybe_put_nonempty("capacity_pack_selected_contact_ids_by_direction")
    |> maybe_put_nonempty("capacity_pack_deferred_contact_ids_by_direction")
    |> maybe_put_nonempty("capacity_pack_required_capacity_fraction_by_direction")
    |> maybe_put_nonempty("capacity_pack_selected_required_capacity_fraction_by_direction")
    |> maybe_put_nonempty("capacity_pack_deferred_required_capacity_fraction_by_direction")
    |> maybe_put_nonempty("branch_contact_allocation_statuses")
    |> maybe_put_nonempty("branch_contact_allocation_effective_statuses")
    |> maybe_put_nonempty("branch_contact_allocation_reasons")
    |> maybe_put_nonempty("branch_contact_allocation_review_statuses")
    |> maybe_put_nonempty("branch_contact_allocation_approval_statuses")
    |> maybe_put_nonempty("branch_contact_allocation_policy_classifications")
    |> maybe_put_nonempty("branch_realized_statuses")
    |> maybe_put_nonempty("branch_transition_types")
    |> maybe_put_nonempty("branch_transition_categories")
    |> maybe_put_nonempty("branch_transition_reasons")
    |> maybe_put_nonempty("branch_requires_operator_review")
    |> maybe_put_nonempty("branch_requires_operator_review_count")
    |> maybe_put_nonempty("branch_operational_readiness_levels")
    |> maybe_put_nonempty("branch_operational_readiness_import_classifications")
    |> maybe_put_nonempty("branch_operational_readiness_statuses")
    |> maybe_put_nonempty("branch_operational_readiness_gate_ids")
    |> maybe_put_nonempty("branch_operational_readiness_gate_statuses")
    |> maybe_put_nonempty("branch_operational_readiness_gate_classifications")
    |> maybe_put_nonempty("branch_operational_readiness_review_required_gate_ids")
    |> maybe_put_nonempty("branch_operational_readiness_analysis_only_gate_ids")
    |> maybe_put_nonempty("branch_operational_readiness_blocked_gate_ids")
    |> maybe_put_nonempty("branch_operational_readiness_non_passed_gate_ids")
    |> maybe_put_nonempty("branch_missed_downlink_activity_ids")
    |> maybe_put_nonempty("branch_maneuver_execution_uncertainty_activity_ids")
    |> maybe_put_nonempty("branch_maneuver_execution_uncertainty_timeline_ids")
    |> maybe_put_nonempty("branch_maneuver_execution_uncertainty_maneuver_ids")
    |> maybe_put_nonempty("branch_maneuver_execution_uncertainty_statuses")
    |> maybe_put_nonempty("branch_maneuver_execution_uncertainty_sources")
    |> maybe_put_nonempty("branch_maneuver_execution_uncertainty_max_timing_3sigma_s")
    |> maybe_put_nonempty(
      "branch_maneuver_execution_uncertainty_max_delta_v_3sigma_magnitude_km_s"
    )
    |> maybe_put_nonempty("branch_timeline_integrity_activity_ids")
    |> maybe_put_nonempty("branch_timeline_integrity_timeline_ids")
    |> maybe_put_nonempty("branch_missing_dependency_activity_ids")
    |> maybe_put_nonempty("branch_missing_dependency_timeline_ids")
    |> maybe_put_nonempty("branch_dependency_cycle_activity_ids")
    |> maybe_put_nonempty("branch_dependency_cycle_timeline_ids")
    |> maybe_put_nonempty("branch_dependency_order_violation_activity_ids")
    |> maybe_put_nonempty("branch_dependency_order_violation_timeline_ids")
    |> maybe_put_nonempty("branch_exclusivity_violation_activity_ids")
    |> maybe_put_nonempty("branch_exclusivity_violation_timeline_ids")
    |> maybe_put_nonempty("branch_exclusivity_violation_groups")
    |> maybe_put_nonempty("branch_timeline_dependency_impact_activity_ids")
    |> maybe_put_nonempty("branch_timeline_dependency_impact_timeline_ids")
    |> maybe_put_nonempty("branch_timeline_dependency_impact_scopes")
    |> maybe_put_nonempty("branch_impacted_dependency_activity_ids")
    |> maybe_put_nonempty("branch_impacted_dependency_timeline_ids")
    |> maybe_put_nonempty("branch_impacted_exclusive_with_activity_ids")
    |> maybe_put_nonempty("branch_impacted_exclusive_with_timeline_ids")
    |> maybe_put_nonempty("branch_timeline_publication_ids")
    |> maybe_put_nonempty("branch_timeline_publication_statuses")
    |> maybe_put_nonempty("branch_timeline_publication_source_artifact_ids")
    |> maybe_put_nonempty("branch_timeline_publication_source_artifact_types")
    |> maybe_put_nonempty("branch_timeline_publication_downstream_invalidation_statuses")
    |> maybe_put_nonempty("branch_timeline_publication_invalidated_downstream_product_ids")
    |> maybe_put_nonempty("branch_timeline_publication_downstream_invalidation_reasons")
    |> maybe_put_nonempty("branch_timeline_publication_dependency_impact_statuses")
    |> maybe_put_nonempty("branch_timeline_publication_impacted_source_activity_ids")
    |> maybe_put_nonempty("branch_timeline_publication_impacted_source_timeline_ids")
    |> maybe_put_nonempty("branch_timeline_publication_dependent_activity_ids")
    |> maybe_put_nonempty("branch_timeline_publication_dependent_timeline_ids")
    |> maybe_put_nonempty("branch_timeline_publication_changed_fields")
    |> maybe_put_nonempty("branch_timeline_publication_changed_timeline_ids")
    |> maybe_put_nonempty("branch_timeline_publication_review_timeline_ids")
    |> maybe_put_nonempty("branch_timeline_lifecycle_state_statuses")
    |> maybe_put_nonempty("branch_timeline_lifecycle_state_review_timeline_ids")
    |> maybe_put_nonempty("branch_timeline_lifecycle_state_review_activity_ids")
    |> maybe_put_nonempty("branch_timeline_lifecycle_state_invalid_activity_input_ids")
    |> maybe_put_nonempty("branch_timeline_lifecycle_state_required_operator_actions")
    |> maybe_put_nonempty("branch_timeline_lifecycle_state_import_actions")
    |> maybe_put_nonempty("branch_timeline_activity_lifecycle_state_activity_ids")
    |> maybe_put_nonempty("branch_timeline_activity_lifecycle_state_timeline_ids")
    |> maybe_put_nonempty("branch_timeline_activity_lifecycle_state_transition_decisions")
    |> maybe_put_nonempty("branch_timeline_activity_lifecycle_state_required_operator_actions")
    |> maybe_put_nonempty("branch_timeline_activity_lifecycle_state_import_actions")
    |> maybe_put_nonempty(
      "branch_timeline_activity_lifecycle_state_invalid_activity_input_reasons"
    )
    |> maybe_put_nonempty("branch_timeline_activity_precondition_activity_ids")
    |> maybe_put_nonempty("branch_timeline_activity_precondition_timeline_ids")
    |> maybe_put_nonempty("branch_timeline_activity_precondition_statuses")
    |> maybe_put_nonempty("branch_timeline_activity_precondition_blocked_types")
    |> maybe_put_nonempty("branch_timeline_activity_precondition_review_types")
    |> maybe_put_nonempty("branch_timeline_activity_precondition_dependency_activity_ids")
    |> maybe_put_nonempty("branch_timeline_activity_precondition_dependency_timeline_ids")
    |> maybe_put_nonempty("branch_timeline_activity_precondition_exclusive_with_activity_ids")
    |> maybe_put_nonempty("branch_timeline_activity_precondition_exclusive_with_timeline_ids")
    |> maybe_put_nonempty(
      "branch_timeline_activity_precondition_duplicate_dependency_activity_ids"
    )
    |> maybe_put_nonempty(
      "branch_timeline_activity_precondition_duplicate_dependency_timeline_ids"
    )
    |> maybe_put_nonempty(
      "branch_timeline_activity_precondition_duplicate_exclusivity_activity_ids"
    )
    |> maybe_put_nonempty(
      "branch_timeline_activity_precondition_duplicate_exclusivity_timeline_ids"
    )
    |> maybe_put_nonempty("branch_timeline_activity_precondition_invalid_activity_input_reasons")
    |> maybe_put_nonempty("branch_timeline_preservation_activity_ids")
    |> maybe_put_nonempty("branch_timeline_preservation_timeline_ids")
    |> maybe_put_nonempty("branch_timeline_preservation_statuses")
    |> maybe_put_nonempty("branch_timeline_preservation_protection_decisions")
    |> maybe_put_nonempty("branch_timeline_preservation_protection_categories")
    |> maybe_put_nonempty("branch_timeline_preservation_protection_reasons")
    |> maybe_put_nonempty("branch_timeline_preservation_preserve_activity_ids")
    |> maybe_put_nonempty("branch_timeline_preservation_preserve_timeline_ids")
    |> maybe_put_nonempty("branch_timeline_preservation_review_change_activity_ids")
    |> maybe_put_nonempty("branch_timeline_preservation_review_change_timeline_ids")
    |> maybe_put_nonempty("branch_timeline_preservation_invalid_activity_input_reasons")
    |> maybe_put_nonempty("branch_source_activity_ids")
    |> maybe_put_nonempty("branch_directions")
    |> maybe_put_nonempty("branch_station_calendar_entry_ids")
    |> maybe_put_nonempty("branch_station_calendar_provider_ids")
    |> maybe_put_nonempty("branch_station_calendar_provider_entry_ids")
    |> maybe_put_nonempty("branch_station_calendar_directions")
    |> maybe_put_nonempty("branch_station_calendar_statuses")
    |> maybe_put_nonempty("branch_station_calendar_trust_boundary_statuses")
    |> maybe_put_nonempty("branch_station_reservation_ids")
    |> maybe_put_nonempty("branch_station_reserved_by")
    |> maybe_put_nonempty("branch_station_reservation_statuses")
    |> maybe_put_nonempty("branch_station_reservation_match_statuses")
    |> maybe_put_nonempty("branch_station_reservation_expiration_statuses")
    |> maybe_put_nonempty("branch_station_reservation_conflict_contact_ids")
    |> maybe_put_nonempty("branch_station_reservation_conflict_reservation_ids")
    |> maybe_put_nonempty("branch_station_reservation_conflict_match_statuses")
    |> maybe_put_nonempty("branch_image_quality_min_score")
    |> maybe_put_nonempty("branch_image_quality_statuses")
    |> maybe_put_nonempty("branch_image_quality_sources")
    |> maybe_put_nonempty("branch_cloud_cover_max_fraction")
    |> maybe_put_nonempty("branch_blur_max_score")
    |> maybe_put_nonempty("branch_max_latency_s")
    |> maybe_put_nonempty("branch_planned_latency_s")
    |> maybe_put_nonempty("branch_required_contacts")
    |> maybe_put_nonempty("branch_planned_contacts")
    |> maybe_put_nonempty("branch_required_downlink_mb")
    |> maybe_put_nonempty("branch_planned_downlink_mb")
    |> maybe_put_nonempty("branch_actual_downlink_completion_ratio")
    |> maybe_put_nonempty("capacity_pack_group_ids")
    |> maybe_put_nonempty("capacity_pack_statuses")
    |> maybe_put_nonempty("capacity_pack_min_capacity_fraction")
    |> maybe_put_nonempty("capacity_pack_max_used_fraction")
    |> maybe_put_nonempty("capacity_pack_max_required_capacity_fraction")
    |> maybe_put_nonempty("capacity_pack_total_required_capacity_fraction")
    |> maybe_put_nonempty("capacity_pack_required_capacity_sources")
    |> maybe_put_combined_source_branch_ids(source_branch_ids)
  end

  defp branch_maneuver_execution_uncertainty_unique_values(events, fields) do
    events
    |> branch_maneuver_execution_uncertainty_events()
    |> branch_event_unique_values(fields)
  end

  defp branch_maneuver_execution_uncertainty_maximum_present(events, field) do
    events
    |> branch_maneuver_execution_uncertainty_events()
    |> maximum_present(field)
  end

  defp branch_maneuver_execution_uncertainty_events(events) do
    Enum.filter(events, &(&1["type"] == "maneuver_execution_uncertainty_feedback"))
  end

  defp branch_operational_readiness_unique_values(events, fields) do
    events
    |> Enum.filter(&(&1["type"] == "operational_readiness_pressure"))
    |> branch_event_unique_values(fields)
  end
end
