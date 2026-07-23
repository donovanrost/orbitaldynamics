defmodule OrbitalDynamics.Schema.CadenceSourceReviewRowJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.LazyProviderResolver

  def row(opts) do
    cadence_capability = Keyword.fetch!(opts, :cadence_capability)
    readiness_capability = Keyword.fetch!(opts, :readiness_capability)
    timeline_capability = Keyword.fetch!(opts, :timeline_capability)
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    schema = LazyProviderResolver.resolver(Keyword.fetch!(opts, :schema_providers))
    properties = LazyProviderResolver.resolver(Keyword.fetch!(opts, :property_providers))

    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" =>
        %{
          "id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "review_type" => %{
            "type" => "string",
            "enum" => cadence_capability.source_review_types
          },
          "analysis_mode" => %{
            "type" => "string",
            "enum" => readiness_capability.analysis_modes
          },
          "analysis_mode_source" => %{"type" => "string"},
          "branch_event_count" => %{"type" => "integer", "minimum" => 0},
          "branch_event_types" => schema.(:string_array_schema),
          "branch_event_trust_boundary_status_counts" =>
            schema.(:branch_event_trust_boundary_status_counts_json_schema),
          "combined_source_branch_ids" => schema.(:stable_id_array_schema),
          "branch_ground_station_ids" => schema.(:stable_id_array_schema),
          "branch_directions" => schema.(:string_array_schema),
          "branch_station_availabilities" => schema.(:string_array_schema),
          "branch_station_contention_statuses" => schema.(:string_array_schema),
          "branch_station_calendar_entry_ids" => schema.(:stable_id_array_schema),
          "branch_station_calendar_provider_ids" => schema.(:stable_id_array_schema),
          "branch_station_calendar_provider_entry_ids" => schema.(:stable_id_array_schema),
          "branch_station_calendar_directions" => schema.(:string_array_schema),
          "branch_station_calendar_statuses" => schema.(:string_array_schema),
          "branch_station_calendar_trust_boundary_statuses" => schema.(:string_array_schema),
          "branch_station_reservation_ids" => schema.(:stable_id_array_schema),
          "branch_station_reserved_by" => schema.(:string_array_schema),
          "branch_station_reservation_statuses" => schema.(:string_array_schema),
          "branch_station_reservation_match_statuses" => schema.(:string_array_schema),
          "branch_station_reservation_conflict_contact_ids" => schema.(:stable_id_array_schema),
          "branch_station_reservation_conflict_reservation_ids" =>
            schema.(:stable_id_array_schema),
          "branch_station_reservation_conflict_match_statuses" => schema.(:string_array_schema),
          "branch_station_reservation_expiration_statuses" => schema.(:string_array_schema),
          "provider_reservation_request_station_reservation_expiration_statuses" =>
            schema.(:string_array_schema),
          "station_reservation_conflict_expiration_statuses" => schema.(:string_array_schema),
          "station_reservation_hold_expiration_statuses" => schema.(:string_array_schema),
          "station_calendar_pressure_risk_types" => schema.(:string_array_schema),
          "station_calendar_pressure_ground_station_ids" => schema.(:stable_id_array_schema),
          "station_calendar_pressure_start_values_s" => schema.(:number_array_schema),
          "station_calendar_pressure_end_values_s" => schema.(:number_array_schema),
          "station_calendar_pressure_capacity_fraction_values" =>
            OrbitalDynamics.Schema.CommonJsonSchema.probability_array(),
          "station_calendar_pressure_station_reservation_expiration_statuses" =>
            schema.(:string_array_schema),
          "station_calendar_pressure_station_reservation_expires_at_values_s" =>
            schema.(:number_array_schema),
          "station_calendar_pressure_station_reservation_ids" => schema.(:stable_id_array_schema),
          "station_calendar_pressure_station_reserved_by" => schema.(:string_array_schema),
          "station_calendar_pressure_station_reservation_statuses" =>
            schema.(:string_array_schema),
          "station_calendar_pressure_station_reservation_match_statuses" =>
            schema.(:string_array_schema),
          "station_calendar_pressure_station_calendar_entry_ids" =>
            schema.(:stable_id_array_schema),
          "station_calendar_pressure_station_calendar_provider_ids" =>
            schema.(:stable_id_array_schema),
          "station_calendar_pressure_station_calendar_provider_entry_ids" =>
            schema.(:stable_id_array_schema),
          "station_calendar_pressure_station_calendar_directions" =>
            schema.(:string_array_schema),
          "station_calendar_pressure_station_calendar_statuses" => schema.(:string_array_schema),
          "station_calendar_pressure_station_availabilities" => schema.(:string_array_schema),
          "station_calendar_pressure_station_contention_statuses" =>
            schema.(:string_array_schema),
          "station_calendar_pressure_station_calendar_overlap_count_values" =>
            schema.(:non_negative_integer_array_schema),
          "station_calendar_pressure_station_calendar_overlap_entry_ids" =>
            schema.(:stable_id_array_schema),
          "station_calendar_pressure_station_calendar_overlap_availabilities" =>
            schema.(:string_array_schema),
          "station_calendar_pressure_station_calendar_entry_ambiguous_values" =>
            schema.(:boolean_array_schema),
          "station_calendar_pressure_station_calendar_ambiguous_entry_count_values" =>
            schema.(:non_negative_integer_array_schema),
          "station_calendar_pressure_station_calendar_ambiguous_entry_ids" =>
            schema.(:stable_id_array_schema),
          "station_calendar_pressure_station_calendar_reservation_overlap_count_values" =>
            schema.(:non_negative_integer_array_schema),
          "station_calendar_pressure_station_calendar_reservation_ids" =>
            schema.(:stable_id_array_schema),
          "station_calendar_pressure_station_calendar_reserved_by" =>
            schema.(:string_array_schema),
          "station_calendar_pressure_station_calendar_reservation_statuses" =>
            schema.(:string_array_schema),
          "station_calendar_pressure_station_calendar_trust_boundary_statuses" =>
            schema.(:string_array_schema),
          "station_calendar_pressure_provider_calendar_contention_group_ids" =>
            schema.(:stable_id_array_schema),
          "station_calendar_pressure_provider_calendar_contention_statuses" =>
            schema.(:string_array_schema),
          "station_calendar_pressure_provider_calendar_contention_entry_ids" =>
            schema.(:stable_id_array_schema),
          "station_calendar_pressure_provider_calendar_contention_provider_ids" =>
            schema.(:stable_id_array_schema),
          "station_calendar_pressure_provider_calendar_contention_provider_entry_ids" =>
            schema.(:stable_id_array_schema),
          "station_calendar_pressure_provider_calendar_contention_availabilities" =>
            schema.(:string_array_schema),
          "station_calendar_pressure_provider_calendar_contention_directions" =>
            schema.(:string_array_schema),
          "station_calendar_pressure_provider_calendar_contention_reservation_ids" =>
            schema.(:stable_id_array_schema),
          "station_calendar_pressure_provider_calendar_contention_reserved_by" =>
            schema.(:string_array_schema),
          "station_calendar_pressure_provider_calendar_contention_reservation_statuses" =>
            schema.(:string_array_schema),
          "station_calendar_pressure_provider_calendar_contention_trust_boundary_statuses" =>
            schema.(:string_array_schema),
          "station_calendar_pressure_provider_calendar_contention_overlap_pairs" =>
            OrbitalDynamics.Schema.CommonJsonSchema.provider_calendar_contention_overlap_pair_array(
              stable_id_pattern
            ),
          "station_calendar_pressure_required_operator_actions" => schema.(:string_array_schema),
          "branch_image_quality_min_score" => %{
            "type" => "number",
            "minimum" => 0.0,
            "maximum" => 1.0
          },
          "branch_image_quality_statuses" => schema.(:string_array_schema),
          "branch_image_quality_sources" => schema.(:string_array_schema),
          "branch_cloud_cover_max_fraction" => %{
            "type" => "number",
            "minimum" => 0.0,
            "maximum" => 1.0
          },
          "branch_blur_max_score" => %{
            "type" => "number",
            "minimum" => 0.0,
            "maximum" => 1.0
          },
          "source_operational_timeline" => schema.(:operational_timeline_row_json_schema),
          "capacity_pack_group_ids" => schema.(:stable_id_array_schema),
          "capacity_pack_statuses" => schema.(:string_array_schema),
          "capacity_pack_min_capacity_fraction" => %{
            "type" => "number",
            "minimum" => 0.0,
            "maximum" => 1.0
          },
          "capacity_pack_max_used_fraction" => %{
            "type" => "number",
            "minimum" => 0.0,
            "maximum" => 1.0
          },
          "capacity_pack_max_required_capacity_fraction" => %{
            "type" => "number",
            "minimum" => 0.0,
            "maximum" => 1.0
          },
          "capacity_pack_total_required_capacity_fraction" => %{
            "type" => "number",
            "minimum" => 0.0
          },
          "capacity_pack_required_capacity_sources" => schema.(:string_array_schema),
          "capacity_fraction" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
          "capacity_fraction_min" => schema.(:probability_json_schema),
          "capacity_fraction_max" => schema.(:probability_json_schema),
          "used_capacity_fraction" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
          "unused_capacity_fraction" => %{
            "type" => "number",
            "minimum" => 0.0,
            "maximum" => 1.0
          },
          "default_required_capacity_fraction" => %{
            "type" => "number",
            "minimum" => 0.0,
            "maximum" => 1.0
          },
          "input_contact_ids" => schema.(:string_array_schema),
          "selected_contact_ids" => schema.(:string_array_schema),
          "capacity_packed_contact_ids" => schema.(:string_array_schema),
          "deferred_contact_ids" => schema.(:string_array_schema),
          "capacity_pack_contact_ids_by_direction" => schema.(:stable_id_array_map_schema),
          "capacity_pack_selected_contact_ids_by_direction" =>
            schema.(:stable_id_array_map_schema),
          "capacity_pack_deferred_contact_ids_by_direction" =>
            schema.(:stable_id_array_map_schema),
          "capacity_pack_required_capacity_fraction_by_direction" =>
            schema.(:non_negative_number_map_json_schema),
          "capacity_pack_selected_required_capacity_fraction_by_direction" =>
            schema.(:non_negative_number_map_json_schema),
          "capacity_pack_deferred_required_capacity_fraction_by_direction" =>
            schema.(:non_negative_number_map_json_schema),
          "capacity_requirement_rows" => %{
            "type" => "array",
            "items" => schema.(:contact_allocation_capacity_requirement_row_json_schema)
          },
          "pack_status" => %{"type" => "string"},
          "source_branch_comparison" => schema.(:branch_comparison_source_row_json_schema),
          "source_policy_decision" => schema.(:policy_decision_evidence_json_schema),
          "source_policy_escalation" => schema.(:policy_escalation_json_schema),
          "source_requirement" => schema.(:source_evidence_json_schema),
          "source_contact_suppression" => schema.(:source_evidence_json_schema),
          "source_resource_suppression" => schema.(:source_evidence_json_schema),
          "source_link_capacity" => schema.(:source_evidence_json_schema),
          "source_resource_projection" => schema.(:source_evidence_json_schema),
          "source_resource_projection_flow_summary" => schema.(:source_evidence_json_schema),
          "source_ranking_comparison" => schema.(:source_evidence_json_schema),
          "source_command_window" => schema.(:source_evidence_json_schema),
          "source_maneuver_review" => schema.(:source_evidence_json_schema),
          "source_timeline_diff" => schema.(:source_evidence_json_schema),
          "source_contention_group" => schema.(:source_evidence_json_schema),
          "source_invalid_contact_input" => schema.(:source_evidence_json_schema),
          "source_station_calendar_review" => schema.(:source_evidence_json_schema),
          "source_feedback" => schema.(:source_evidence_json_schema),
          "source_execution_report" => schema.(:source_execution_report_evidence_json_schema),
          "source_freshness_report" => schema.(:source_freshness_report_evidence_json_schema),
          "source_schema_validation_report" =>
            schema.(:source_schema_validation_report_evidence_json_schema),
          "source_operational_readiness_report" =>
            schema.(:operational_readiness_source_report_evidence_json_schema),
          "source_quality_gate_report" =>
            schema.(:quality_gate_source_report_evidence_json_schema),
          "source_refresh_budget_report" => schema.(:source_evidence_json_schema),
          "selected_activity_source" => %{"type" => "string"},
          "selected_activity" => %{"type" => "object", "additionalProperties" => true},
          "selected_timeline_integrity_status" => %{"type" => "string"},
          "selected_timeline_integrity_issue_count" => %{"type" => "integer", "minimum" => 0},
          "selected_timeline_integrity_issue_types" => %{
            "type" => "array",
            "items" => %{
              "type" => "string",
              "enum" => timeline_capability.timeline_integrity_issue_types
            }
          },
          "selected_timeline_integrity_issues" => %{
            "type" => "array",
            "items" => %{"type" => "object"}
          },
          "selected_missing_dependency_activity_ids" => schema.(:stable_id_array_schema),
          "selected_missing_dependency_timeline_ids" => schema.(:stable_id_array_schema),
          "selected_self_dependency_activity_ids" => schema.(:stable_id_array_schema),
          "selected_self_dependency_timeline_ids" => schema.(:stable_id_array_schema),
          "selected_duplicate_dependency_activity_ids" => schema.(:stable_id_array_schema),
          "selected_duplicate_dependency_timeline_ids" => schema.(:stable_id_array_schema),
          "selected_duplicate_exclusivity_activity_ids" => schema.(:stable_id_array_schema),
          "selected_duplicate_exclusivity_timeline_ids" => schema.(:stable_id_array_schema),
          "selected_dependency_cycle_activity_ids" => schema.(:stable_id_array_schema),
          "selected_dependency_cycle_timeline_ids" => schema.(:stable_id_array_schema),
          "selected_dependency_order_violation_activity_ids" => schema.(:stable_id_array_schema),
          "selected_dependency_order_violation_timeline_ids" => schema.(:stable_id_array_schema),
          "selected_exclusivity_violation_activity_ids" => schema.(:stable_id_array_schema),
          "selected_exclusivity_violation_timeline_ids" => schema.(:stable_id_array_schema),
          "selected_exclusivity_violation_group" => %{"type" => "string"},
          "source_timeline_diff_summary" => schema.(:timeline_diff_summary_source_json_schema),
          "source_timeline_transition_application_summary" =>
            schema.(:timeline_transition_application_summary_source_json_schema),
          "source_timeline_application" =>
            schema.(:timeline_transition_application_row_json_schema),
          "source_timeline_integrity" => schema.(:operational_timeline_row_json_schema),
          "source_timeline_protection" => schema.(:timeline_protection_summary_json_schema),
          "source_timeline_activity_state" =>
            schema.(:timeline_activity_state_source_json_schema),
          "source_timeline_lifecycle_state" =>
            schema.(:timeline_lifecycle_state_source_json_schema),
          "source_timeline_activity_precondition_summary" =>
            schema.(:timeline_activity_precondition_summary_source_json_schema),
          "source_timeline_preservation" => schema.(:timeline_preservation_source_json_schema),
          "source_candidate_rejection" => schema.(:candidate_rejection_source_json_schema),
          "timeline_link" => schema.(:timeline_link_json_schema),
          "source_timeline_identity" => schema.(:timeline_identity_json_schema),
          "replacement_timeline_identity" => schema.(:timeline_identity_json_schema),
          "source_delta" => schema.(:source_evidence_json_schema),
          "import_activity_context" => schema.(:activity_context_json_schema),
          "source_activity_context" => schema.(:activity_context_json_schema),
          "realized_activity_context" => schema.(:activity_context_json_schema),
          "replacement_activity_context" => schema.(:activity_context_json_schema),
          "source_target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "source_target" => %{"type" => "object", "additionalProperties" => true},
          "target_latitude_deg" => %{"type" => "number"},
          "target_longitude_deg" => %{"type" => "number"},
          "target_minimum_elevation_deg" => %{"type" => "number"},
          "target_priority" => %{"type" => "number"},
          "target_priority_source" => %{"type" => "string"},
          "target_priority_objective_ids" => schema.(:stable_id_array_schema),
          "target_priority_objective_type" => %{"type" => "string"},
          "semantic_change_details" => schema.(:semantic_change_details_json_schema),
          "changed_fields" => schema.(:string_array_schema),
          "candidate_diff_changed_fields" => schema.(:string_array_schema),
          "candidate_diff_changed_field_count" => %{"type" => "integer", "minimum" => 0},
          "source_window_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "source_window_type" => %{"type" => "string"},
          "source_window" => schema.(:candidate_activity_source_window_json_schema),
          "source_window_lineage" => schema.(:source_window_lineage_json_schema),
          "replacement_candidate_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "replacement_source_window_id" => %{
            "type" => "string",
            "pattern" => stable_id_pattern
          },
          "replacement_source_window_type" => %{"type" => "string"},
          "replacement_source_window" => schema.(:candidate_activity_source_window_json_schema),
          "replacement_source_window_lineage" => schema.(:source_window_lineage_json_schema),
          "throughput_completion_fraction" => %{
            "type" => "number",
            "minimum" => 0.0,
            "maximum" => 1.0
          },
          "completed_fraction" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
          "eclipse_overlap_fraction" => %{
            "type" => "number",
            "minimum" => 0.0,
            "maximum" => 1.0
          },
          "planned_eclipse_overlap_fraction" => %{
            "type" => "number",
            "minimum" => 0.0,
            "maximum" => 1.0
          },
          "realized_eclipse_overlap_fraction" => %{
            "type" => "number",
            "minimum" => 0.0,
            "maximum" => 1.0
          },
          "eclipse_overlap_s" => %{"type" => "number"},
          "planned_eclipse_overlap_s" => %{"type" => "number"},
          "realized_eclipse_overlap_s" => %{"type" => "number"},
          "lighting_condition" => %{"type" => "string"},
          "planned_lighting_condition" => %{"type" => "string"},
          "realized_lighting_condition" => %{"type" => "string"},
          "lighting_condition_match_status" => %{"type" => "string"},
          "lighting_condition_detail" => %{"type" => "string"},
          "lighting_condition_model" => %{"type" => "string"},
          "lighting_detail_model" => %{"type" => "string"},
          "lighting_confidence" => schema.(:number_or_string_json_schema),
          "bit_error_rate" => schema.(:probability_json_schema),
          "planned_bit_error_rate" => schema.(:probability_json_schema),
          "realized_bit_error_rate" => schema.(:probability_json_schema),
          "packet_loss_rate" => schema.(:probability_json_schema),
          "planned_packet_loss_rate" => schema.(:probability_json_schema),
          "realized_packet_loss_rate" => schema.(:probability_json_schema),
          "frame_loss_rate" => schema.(:probability_json_schema),
          "planned_frame_loss_rate" => schema.(:probability_json_schema),
          "realized_frame_loss_rate" => schema.(:probability_json_schema),
          "image_quality_score" => schema.(:probability_json_schema),
          "planned_image_quality_score" => schema.(:probability_json_schema),
          "realized_image_quality_score" => schema.(:probability_json_schema),
          "image_quality_score_delta" => %{"type" => "number"},
          "image_quality_status" => %{"type" => "string"},
          "planned_image_quality_status" => %{"type" => "string"},
          "realized_image_quality_status" => %{"type" => "string"},
          "image_quality_status_match_status" => %{"type" => "string"},
          "image_quality_source" => %{"type" => "string"},
          "cloud_cover_fraction" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
          "planned_cloud_cover_fraction" => %{
            "type" => "number",
            "minimum" => 0.0,
            "maximum" => 1.0
          },
          "realized_cloud_cover_fraction" => %{
            "type" => "number",
            "minimum" => 0.0,
            "maximum" => 1.0
          },
          "cloud_cover_fraction_delta" => %{"type" => "number"},
          "blur_score" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
          "planned_blur_score" => %{
            "type" => "number",
            "minimum" => 0.0,
            "maximum" => 1.0
          },
          "realized_blur_score" => %{
            "type" => "number",
            "minimum" => 0.0,
            "maximum" => 1.0
          },
          "blur_score_delta" => %{"type" => "number"},
          "attitude_target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "planned_attitude_target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "realized_attitude_target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "attitude_target_match_status" => %{"type" => "string"},
          "attitude_mode" => %{"type" => "string"},
          "planned_attitude_mode" => %{"type" => "string"},
          "realized_attitude_mode" => %{"type" => "string"},
          "attitude_mode_match_status" => %{"type" => "string"},
          "planned_roll_deg" => %{"type" => "number"},
          "realized_roll_deg" => %{"type" => "number"},
          "roll_delta_deg" => %{"type" => "number"},
          "planned_pitch_deg" => %{"type" => "number"},
          "realized_pitch_deg" => %{"type" => "number"},
          "pitch_delta_deg" => %{"type" => "number"},
          "planned_yaw_deg" => %{"type" => "number"},
          "realized_yaw_deg" => %{"type" => "number"},
          "yaw_delta_deg" => %{"type" => "number"},
          "attitude_error_deg" => %{"type" => "number"},
          "attitude_status" => %{"type" => "string"},
          "attitude_model" => %{"type" => "string"},
          "attitude_source" => %{"type" => "string"},
          "attitude_confidence" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
          "selected_priority" => %{"type" => "number"},
          "selected_priority_source" => %{"type" => "string"},
          "deferred_contact_priorities" => %{
            "type" => "array",
            "items" => schema.(:contact_contention_deferred_priority_json_schema)
          },
          "resolution_priority_fields" => schema.(:string_array_schema),
          "requested_priority_fields" => schema.(:string_array_schema),
          "priority_field_evidence_counts" =>
            schema.(:priority_field_evidence_counts_json_schema),
          "priority_fields_without_numeric_evidence_count" => %{
            "type" => "integer",
            "minimum" => 0
          },
          "priority_fields_without_numeric_evidence" => schema.(:string_array_schema)
        }
        |> Map.merge(properties.(:timeline_dependency_impact_handoff_json_schema_properties))
        |> Map.merge(properties.(:timeline_publication_handoff_json_schema_properties))
        |> Map.merge(properties.(:timeline_activity_precondition_handoff_json_schema_properties))
        |> Map.merge(properties.(:command_authority_handoff_json_schema_properties))
        |> Map.merge(properties.(:feedback_maneuver_handoff_json_schema_properties))
        |> Map.merge(properties.(:link_handoff_json_schema_properties))
        |> Map.merge(properties.(:thermal_handoff_json_schema_properties))
        |> Map.merge(properties.(:resource_availability_variance_json_schema_properties))
        |> Map.merge(
          OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.resource_context_properties(
            stable_id_pattern: stable_id_pattern
          )
        )
        |> Map.merge(
          OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.operator_training_context_properties()
        )
        |> Map.merge(
          OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.adapter_boundary_context_properties()
        )
        |> Map.merge(
          properties.(:cadence_import_operational_readiness_evidence_json_schema_properties)
        )
        |> Map.merge(properties.(:resource_projection_battery_handoff_json_schema_properties))
        |> Map.merge(
          properties.(:cadence_import_resource_projection_evidence_json_schema_properties)
        )
        |> Map.merge(properties.(:branch_scoped_downlink_context_json_schema_properties))
        |> Map.merge(properties.(:scoped_downlink_context_json_schema_properties))
    }
  end
end
