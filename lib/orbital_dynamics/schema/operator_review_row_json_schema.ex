defmodule OrbitalDynamics.Schema.OperatorReviewRowJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.LazyProviderResolver

  def row(opts) do
    operator_review_capability = Keyword.fetch!(opts, :operator_review_capability)
    readiness_capability = Keyword.fetch!(opts, :readiness_capability)
    timeline_capability = Keyword.fetch!(opts, :timeline_capability)
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    schema = LazyProviderResolver.resolver(Keyword.fetch!(opts, :schema_providers))
    properties = LazyProviderResolver.resolver(Keyword.fetch!(opts, :property_providers))

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "id",
        "rank",
        "review_type",
        "source",
        "subject_id",
        "action",
        "required_operator_action",
        "reason"
      ],
      "properties" =>
        %{
          "id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "rank" => %{"type" => "integer"},
          "review_type" => %{
            "type" => "string",
            "enum" => operator_review_capability.review_types
          },
          "source" => %{"type" => "string"},
          "subject_id" => %{"type" => "string"},
          "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "timeline_id" => %{"type" => "string"},
          "diff_status" => %{"type" => "string"},
          "status_transition" => schema.(:lifecycle_transition_json_schema),
          "approval_transition" => schema.(:lifecycle_transition_json_schema),
          "contact_id" => %{"type" => "string"},
          "activity_id" => %{"type" => "string"},
          "activity_type" => %{"type" => "string"},
          "spacecraft_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "window_type" => %{"type" => "string"},
          "status" => %{"type" => "string"},
          "locked" => %{"type" => "boolean"},
          "maneuver_id" => %{"type" => "string"},
          "maneuver_type" => %{"type" => "string"},
          "epoch_s" => %{"type" => "number"},
          "epoch_scale" => %{"type" => "string"},
          "frame" => %{"type" => "string"},
          "delta_v_km_s" => schema.(:numeric_triplet_schema),
          "delta_v_magnitude_km_s" => %{"type" => "number"},
          "maneuver_model" => %{"type" => "string"},
          "source_activity_id" => %{"type" => "string"},
          "source_activity_type" => %{"type" => "string"},
          "replacement_activity_id" => %{"type" => "string"},
          "replacement_activity_type" => %{"type" => "string"},
          "planned_timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "source_starts_at_s" => %{"type" => "number"},
          "source_ends_at_s" => %{"type" => "number"},
          "source_approval_status" => %{"type" => "string"},
          "source_protection_category" => %{"type" => "string"},
          "source_protection_decision" => schema.(:protection_decision_json_schema),
          "source_protection_reason" => %{"type" => "string"},
          "replacement_starts_at_s" => %{"type" => "number"},
          "replacement_ends_at_s" => %{"type" => "number"},
          "replacement_approval_status" => %{"type" => "string"},
          "replacement_protection_category" => %{"type" => "string"},
          "replacement_protection_decision" => schema.(:protection_decision_json_schema),
          "replacement_protection_reason" => %{"type" => "string"},
          "planned_activity" => %{"type" => "object"},
          "realized_activity" => %{"type" => "object"},
          "realized_activity_context" => schema.(:activity_context_json_schema),
          "realized_activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "realized_timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "realized_type" => %{"type" => "string"},
          "realized_provider" => %{"type" => "string"},
          "realized_adapter" => %{"type" => "string"},
          "realized_adapter_version" => %{"type" => "string"},
          "realized_external_id" => %{"type" => "string"},
          "realized_schema_contract" => %{"type" => "string"},
          "realized_received_at" => %{"type" => "string"},
          "realized_ingested_at" => %{"type" => "string"},
          "realized_trust_boundary" => %{"type" => "string"},
          "realized_provenance" => %{"type" => "object"},
          "realized_source" => %{"type" => "object"},
          "source_artifact_type" => %{"type" => "string"},
          "source_artifact_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "source_operational_timeline" => schema.(:operational_timeline_row_json_schema),
          "readiness_level" => %{
            "type" => "string",
            "enum" => readiness_capability.readiness_levels
          },
          "import_classification" => %{
            "type" => "string",
            "enum" => readiness_capability.import_classifications
          },
          "operational_readiness_status" => %{
            "type" => "string",
            "enum" => readiness_capability.gate_statuses
          },
          "readiness_gate_id" => %{"type" => "string"},
          "readiness_gate_status" => %{
            "type" => "string",
            "enum" => readiness_capability.gate_statuses
          },
          "readiness_gate_classification" => %{
            "type" => "string",
            "enum" => readiness_capability.import_classifications
          },
          "readiness_gate_reason" => %{"type" => "string"},
          "analysis_mode" => %{
            "type" => "string",
            "enum" => readiness_capability.analysis_modes
          },
          "analysis_mode_source" => %{"type" => "string"},
          "gate_count" => %{"type" => "integer", "minimum" => 0},
          "passed_gate_count" => %{"type" => "integer", "minimum" => 0},
          "review_gate_count" => %{"type" => "integer", "minimum" => 0},
          "analysis_gate_count" => %{"type" => "integer", "minimum" => 0},
          "blocked_gate_count" => %{"type" => "integer", "minimum" => 0},
          "gates" => %{
            "type" => "array",
            "items" => schema.(:operational_readiness_gate_json_schema)
          },
          "evidence" => schema.(:operational_readiness_evidence_json_schema),
          "source_operational_readiness_gate" => schema.(:operational_readiness_gate_json_schema),
          "source_quality_gate_row" => schema.(:quality_gate_report_row_json_schema),
          "source_operational_readiness_report" =>
            schema.(:operational_readiness_source_report_evidence_json_schema),
          "source_quality_gate_report" =>
            schema.(:quality_gate_source_report_evidence_json_schema),
          "feedback_kind" => %{"type" => "string"},
          "direction" => %{"type" => "string"},
          "branch_id" => %{"type" => "string"},
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
          "station_reservation_conflict_contact_ids" => schema.(:stable_id_array_schema),
          "station_reservation_conflict_source_activity_ids" => schema.(:stable_id_array_schema),
          "station_reservation_conflict_ground_station_ids" => schema.(:stable_id_array_schema),
          "station_reservation_conflict_reservation_ids" => schema.(:stable_id_array_schema),
          "station_reservation_conflict_reserved_by" => schema.(:string_array_schema),
          "station_reservation_conflict_statuses" => schema.(:string_array_schema),
          "station_reservation_conflict_match_statuses" => schema.(:string_array_schema),
          "station_reservation_conflict_expires_at_values_s" => schema.(:number_array_schema),
          "station_reservation_conflict_expiration_statuses" => schema.(:string_array_schema),
          "station_reservation_hold_expiration_statuses" => schema.(:string_array_schema),
          "contact_allocation_pressure_risk_types" => schema.(:string_array_schema),
          "contact_allocation_pressure_contact_ids" => schema.(:stable_id_array_schema),
          "contact_allocation_pressure_scenario_ids" => schema.(:stable_id_array_schema),
          "contact_allocation_pressure_spacecraft_ids" => schema.(:stable_id_array_schema),
          "contact_allocation_pressure_ground_station_ids" => schema.(:stable_id_array_schema),
          "contact_allocation_pressure_source_activity_ids" => schema.(:stable_id_array_schema),
          "contact_allocation_pressure_source_window_ids" => schema.(:stable_id_array_schema),
          "contact_allocation_pressure_required_contact_values" => schema.(:number_array_schema),
          "contact_allocation_pressure_planned_contact_values" => schema.(:number_array_schema),
          "contact_allocation_pressure_required_downlink_values_mb" =>
            schema.(:number_array_schema),
          "contact_allocation_pressure_planned_downlink_values_mb" =>
            schema.(:number_array_schema),
          "contact_allocation_pressure_start_values_s" => schema.(:number_array_schema),
          "contact_allocation_pressure_end_values_s" => schema.(:number_array_schema),
          "contact_allocation_pressure_realized_statuses" => schema.(:string_array_schema),
          "contact_allocation_pressure_contact_results" => schema.(:string_array_schema),
          "contact_allocation_pressure_allocation_statuses" => schema.(:string_array_schema),
          "contact_allocation_pressure_effective_allocation_statuses" =>
            schema.(:string_array_schema),
          "contact_allocation_pressure_allocation_reasons" => schema.(:string_array_schema),
          "contact_allocation_pressure_review_statuses" => schema.(:string_array_schema),
          "contact_allocation_pressure_approval_statuses" => schema.(:string_array_schema),
          "contact_allocation_pressure_policy_classifications" => schema.(:string_array_schema),
          "contact_allocation_pressure_policy_bundle_ids" => schema.(:stable_id_array_schema),
          "contact_allocation_pressure_station_reservation_ids" =>
            schema.(:stable_id_array_schema),
          "contact_allocation_pressure_station_reserved_by" => schema.(:string_array_schema),
          "contact_allocation_pressure_station_reservation_statuses" =>
            schema.(:string_array_schema),
          "contact_allocation_pressure_station_reservation_match_statuses" =>
            schema.(:string_array_schema),
          "contact_allocation_pressure_station_calendar_entry_ids" =>
            schema.(:stable_id_array_schema),
          "contact_allocation_pressure_station_calendar_entry_statuses" =>
            schema.(:string_array_schema),
          "contact_allocation_pressure_station_calendar_directions" =>
            schema.(:string_array_schema),
          "contact_allocation_pressure_downlink_demand_sources" => schema.(:string_array_schema),
          "contact_allocation_pressure_downlink_completion_sources" =>
            schema.(:string_array_schema),
          "contact_allocation_pressure_feedback_sources" => schema.(:string_array_schema),
          "contact_allocation_pressure_feedback_scopes" => schema.(:string_array_schema),
          "contact_allocation_pressure_trust_boundaries" => schema.(:string_array_schema),
          "contact_allocation_pressure_derivation_reasons" => schema.(:string_array_schema),
          "contact_intent_pressure_risk_types" => schema.(:string_array_schema),
          "contact_intent_pressure_contact_ids" => schema.(:stable_id_array_schema),
          "contact_intent_pressure_source_activity_ids" => schema.(:stable_id_array_schema),
          "contact_intent_pressure_ground_station_ids" => schema.(:stable_id_array_schema),
          "contact_intent_pressure_required_contact_values" => schema.(:number_array_schema),
          "contact_intent_pressure_planned_contact_values" => schema.(:number_array_schema),
          "contact_intent_pressure_required_downlink_values_mb" => schema.(:number_array_schema),
          "contact_intent_pressure_planned_downlink_values_mb" => schema.(:number_array_schema),
          "contact_intent_pressure_start_values_s" => schema.(:number_array_schema),
          "contact_intent_pressure_end_values_s" => schema.(:number_array_schema),
          "contact_intent_pressure_source_window_ids" => schema.(:stable_id_array_schema),
          "contact_intent_pressure_timeline_ids" => schema.(:stable_id_array_schema),
          "contact_intent_pressure_approval_statuses" => schema.(:string_array_schema),
          "contact_intent_pressure_required_operator_actions" => schema.(:string_array_schema),
          "contact_intent_pressure_cadence_import_statuses" => schema.(:string_array_schema),
          "contact_intent_pressure_gate_statuses" => schema.(:string_array_schema),
          "contact_intent_pressure_policy_classifications" => schema.(:string_array_schema),
          "contact_intent_pressure_policy_bundle_ids" => schema.(:stable_id_array_schema),
          "contact_intent_pressure_invalid_cadence_import_values" =>
            schema.(:boolean_array_schema),
          "contact_intent_pressure_invalid_cadence_import_reasons" =>
            schema.(:string_array_schema),
          "contact_intent_pressure_invalid_activity_input_values" =>
            schema.(:boolean_array_schema),
          "contact_intent_pressure_invalid_activity_input_reasons" =>
            schema.(:string_array_schema),
          "contact_intent_pressure_station_availabilities" => schema.(:string_array_schema),
          "contact_intent_pressure_station_contention_statuses" => schema.(:string_array_schema),
          "contact_intent_pressure_station_calendar_entry_ids" =>
            schema.(:stable_id_array_schema),
          "contact_intent_pressure_station_calendar_provider_ids" =>
            schema.(:stable_id_array_schema),
          "contact_intent_pressure_station_calendar_provider_entry_ids" =>
            schema.(:stable_id_array_schema),
          "contact_intent_pressure_station_calendar_directions" => schema.(:string_array_schema),
          "contact_intent_pressure_station_calendar_statuses" => schema.(:string_array_schema),
          "contact_intent_pressure_station_calendar_trust_boundary_statuses" =>
            schema.(:string_array_schema),
          "contact_intent_pressure_station_reservation_ids" => schema.(:stable_id_array_schema),
          "contact_intent_pressure_station_reserved_by" => schema.(:string_array_schema),
          "contact_intent_pressure_station_reservation_statuses" => schema.(:string_array_schema),
          "contact_intent_pressure_station_reservation_match_statuses" =>
            schema.(:string_array_schema),
          "contact_intent_pressure_feedback_sources" => schema.(:string_array_schema),
          "contact_intent_pressure_feedback_scopes" => schema.(:string_array_schema),
          "contact_intent_pressure_trust_boundaries" => schema.(:string_array_schema),
          "contact_intent_pressure_derivation_reasons" => schema.(:string_array_schema),
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
          "station_calendar_pressure_feedback_sources" => schema.(:string_array_schema),
          "station_calendar_pressure_feedback_scopes" => schema.(:string_array_schema),
          "station_calendar_pressure_trust_boundaries" => schema.(:string_array_schema),
          "station_calendar_pressure_derivation_reasons" => schema.(:string_array_schema),
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
          "ground_station_id" => %{"type" => "string"},
          "target_id" => %{"type" => "string"},
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
          "candidate_diff_changed_fields" => schema.(:string_array_schema),
          "candidate_diff_changed_field_count" => %{"type" => "integer", "minimum" => 0},
          "contact_count" => %{"type" => "integer", "minimum" => 0},
          "contact_ids" => schema.(:string_array_schema),
          "scenario_ids" => schema.(:string_array_schema),
          "activity_count" => %{"type" => "integer", "minimum" => 0},
          "effective_activity_count" => %{"type" => "integer", "minimum" => 0},
          "ignored_activity_count" => %{"type" => "integer", "minimum" => 0},
          "ignored_activity_ids" => schema.(:stable_id_array_schema),
          "dependency_activity_ids" => schema.(:stable_id_array_schema),
          "dependency_timeline_ids" => schema.(:stable_id_array_schema),
          "exclusive_with_activity_ids" => schema.(:stable_id_array_schema),
          "exclusive_with_timeline_ids" => schema.(:stable_id_array_schema),
          "match_strategy" => %{"type" => "string"},
          "source_window_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "source_window_ids" => schema.(:string_array_schema),
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
          "station_availability" => %{"type" => "string"},
          "station_calendar_entry_id" => %{"type" => "string"},
          "station_calendar_provider_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "station_calendar_provider_entry_id" => %{
            "type" => "string",
            "pattern" => stable_id_pattern
          },
          "first_resource_pressure_station_calendar_provider_id" => %{
            "type" => "string",
            "pattern" => stable_id_pattern
          },
          "first_resource_pressure_station_calendar_provider_entry_id" => %{
            "type" => "string",
            "pattern" => stable_id_pattern
          },
          "station_calendar_directions" => schema.(:string_array_schema),
          "station_calendar_status" => %{"type" => "string"},
          "station_calendar_overlap_count" => %{"type" => "integer", "minimum" => 0},
          "station_calendar_overlap_entry_ids" => schema.(:stable_id_array_schema),
          "station_calendar_overlap_availabilities" => schema.(:string_array_schema),
          "station_calendar_entry_ambiguous" => %{"type" => "boolean"},
          "station_calendar_ambiguous_entry_count" => %{"type" => "integer", "minimum" => 0},
          "station_calendar_ambiguous_entry_ids" => schema.(:stable_id_array_schema),
          "station_calendar_reservation_overlap_count" => %{"type" => "integer", "minimum" => 0},
          "station_calendar_reservation_ids" => schema.(:stable_id_array_schema),
          "station_calendar_reserved_by" => schema.(:string_array_schema),
          "station_calendar_reservation_statuses" => schema.(:string_array_schema),
          "station_calendar_reservation_expires_at_s" => schema.(:number_array_schema),
          "station_calendar_trust_boundary_status" => %{"type" => "string"},
          "trust_boundary" => %{"type" => "string"},
          "capacity_fraction" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
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
          "capacity_packed_contact_ids" => schema.(:string_array_schema),
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
          "capacity_fraction_min" => schema.(:probability_json_schema),
          "capacity_fraction_max" => schema.(:probability_json_schema),
          "estimated_throughput_mb" => %{"type" => "number"},
          "selected_contact_count" => %{"type" => "integer", "minimum" => 0},
          "selected_contact_ids" => schema.(:string_array_schema),
          "selected_estimated_throughput_mb" => %{"type" => "number"},
          "capacity_adjusted_throughput_mb" => %{"type" => "number"},
          "selected_capacity_adjusted_throughput_mb" => %{"type" => "number"},
          "observation_count" => %{"type" => "integer", "minimum" => 0},
          "downlink_count" => %{"type" => "integer", "minimum" => 0},
          "estimated_storage_produced_mb" => %{"type" => "number"},
          "estimated_downlink_mb" => %{"type" => "number"},
          "starting_storage_used_mb" => %{"type" => "number"},
          "projected_storage_used_mb" => %{"type" => "number"},
          "storage_capacity_mb" => %{"type" => "number"},
          "starting_storage_margin" => %{"type" => "number"},
          "projected_storage_margin" => %{"type" => "number"},
          "projected_storage_remaining_mb" => %{"type" => "number"},
          "downlink_capacity_mb" => %{"type" => "number"},
          "starting_downlink_margin" => %{"type" => "number"},
          "projected_downlink_margin" => %{"type" => "number"},
          "projected_downlink_remaining_mb" => %{"type" => "number"},
          "resource_source_quality" => %{"type" => "string"},
          "resource_flow_count" => %{"type" => "integer", "minimum" => 0},
          "peak_storage_overflow_mb" => %{"type" => "number"},
          "peak_downlink_shortfall_mb" => %{"type" => "number"},
          "peak_unused_downlink_capacity_mb" => %{"type" => "number"},
          "projected_storage_overflow_mb" => %{"type" => "number"},
          "projected_downlink_shortfall_mb" => %{"type" => "number"},
          "projected_battery_overuse_wh" => %{"type" => "number"},
          "first_resource_pressure_activity_id" => %{
            "type" => "string",
            "pattern" => stable_id_pattern
          },
          "first_resource_pressure_activity_type" => %{"type" => "string"},
          "first_resource_pressure_kind" => %{"type" => "string"},
          "first_resource_pressure_starts_at_s" => %{"type" => "number"},
          "fuel_margin" => %{"type" => "number"},
          "power_margin" => %{"type" => "number"},
          "payload_available" => %{"type" => "boolean"},
          "antenna_available" => %{"type" => "boolean"},
          "resource_trust_boundary_status" => %{"type" => "string"},
          "storage_limited_downlinked_mb" => %{"type" => "number"},
          "unused_downlink_capacity_mb" => %{"type" => "number"},
          "warnings" => schema.(:string_array_schema),
          "station_contention_status" => %{"type" => "string"},
          "station_reservation_id" => %{"type" => "string"},
          "station_reservation_expires_at_s" => schema.(:number_or_number_array_schema),
          "station_reserved_by" => %{"type" => "string"},
          "station_reservation_status" => %{"type" => "string"},
          "cadence_import_status" => %{"type" => "string"},
          "cadence_import_type" => %{"type" => "string"},
          "operator_action_reason" => %{"type" => "string"},
          "execution_boundary" => %{"type" => "string"},
          "source_window_type" => %{"type" => "string"},
          "has_source_window" => %{"type" => "boolean"},
          "has_cadence_import" => %{"type" => "boolean"},
          "action" => %{"type" => "string"},
          "required_operator_action" => %{"type" => "string"},
          "approval_status" => %{"type" => "string"},
          "approval_requirements" => %{
            "type" => "array",
            "items" => schema.(:approval_requirement_json_schema)
          },
          "approval_rule_matches" => %{
            "type" => "array",
            "items" => schema.(:policy_decision_rule_match_json_schema)
          },
          "planned_operator_action" => %{"type" => "string"},
          "planned_operator_action_reason" => %{"type" => "string"},
          "planned_protection_category" => %{"type" => "string"},
          "planned_protection_decision" => %{"type" => "string"},
          "planned_protection_reason" => %{"type" => "string"},
          "review_queue" => %{"type" => "string"},
          "review_queue_key" => %{"type" => "string"},
          "repair_action" => %{"type" => "string"},
          "protection_category" => %{
            "type" => "string",
            "enum" => [
              "preserved_locked_or_approved",
              "preserved_executed",
              "changed_locked_or_approved",
              "changed_executed"
            ]
          },
          "protection_decision" => %{"type" => "string", "enum" => ["preserved", "changed"]},
          "requirement_type" => %{"type" => "string"},
          "policy_bundle_id" => %{"type" => "string"},
          "rule_id" => %{"type" => "string"},
          "risk_type" => %{"type" => "string"},
          "dimension" => %{"type" => "string"},
          "left_rank" => %{"type" => ["integer", "null"]},
          "right_rank" => %{"type" => ["integer", "null"]},
          "rank_delta" => %{"type" => ["integer", "null"]},
          "left_value" => %{"type" => ["number", "null"]},
          "right_value" => %{"type" => ["number", "null"]},
          "value_delta" => %{"type" => ["number", "null"]},
          "severity" => %{"type" => "string"},
          "reason" => %{"type" => "string"},
          "baseline" => %{"type" => "number"},
          "recommended" => %{"type" => "number"},
          "delta" => %{"type" => "number"},
          "repair_score" => %{"type" => "number"},
          "repair_activity_score" => %{"type" => "number"},
          "repair_schedule_churn_penalty" => %{"type" => "number"},
          "repair_schedule_move_penalty" => %{"type" => "number"},
          "repair_score_term_keys" => schema.(:string_array_schema),
          "repair_link_selected_estimated_throughput_mb" => %{"type" => "number"},
          "repair_link_selected_capacity_adjusted_throughput_mb" => %{"type" => "number"},
          "repair_link_actual_throughput_mb" => %{"type" => "number"},
          "repair_link_actual_downlink_completion_ratio" => %{
            "type" => "number",
            "minimum" => 0,
            "maximum" => 1
          },
          "repair_link_actual_downlink_shortfall_mb" => %{"type" => "number"},
          "repair_link_actual_downlink_requirement_status" => %{"type" => "string"},
          "starts_at_s" => %{"type" => "number"},
          "ends_at_s" => %{"type" => "number"},
          "contention_window_s" => %{"type" => "number"},
          "total_contact_duration_s" => %{"type" => "number"},
          "overlap_duration_s" => %{"type" => "number"},
          "max_concurrent_contacts" => %{"type" => "integer", "minimum" => 0},
          "overlap_contact_pair_count" => %{"type" => "integer", "minimum" => 0},
          "planned_status" => %{"type" => "string"},
          "realized_status" => %{"type" => "string"},
          "feedback_status" => %{"type" => "string"},
          "planned_starts_at_s" => %{"type" => "number"},
          "planned_ends_at_s" => %{"type" => "number"},
          "actual_starts_at_s" => %{"type" => "number"},
          "actual_ends_at_s" => %{"type" => "number"},
          "start_delta_s" => %{"type" => "number"},
          "end_delta_s" => %{"type" => "number"},
          "planned_estimated_throughput_mb" => %{"type" => "number"},
          "actual_throughput_mb" => %{"type" => "number"},
          "actual_data_rate_throughput_derivation" =>
            schema.(:actual_data_rate_throughput_derivation_json_schema),
          "throughput_delta_mb" => %{"type" => "number"},
          "throughput_completion_fraction" => %{
            "type" => "number",
            "minimum" => 0.0,
            "maximum" => 1.0
          },
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
          "planned_blur_score" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
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
          "contact_success" => %{"type" => "boolean"},
          "command_success" => %{"type" => "boolean"},
          "command_result" => %{"type" => "string"},
          "completed_fraction" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
          "requires_operator_review" => %{"type" => "boolean"},
          "changed_fields" => schema.(:string_array_schema),
          "value" => %{"type" => "number"},
          "escalation_level" => %{"type" => "string"},
          "escalation_queue" => %{"type" => "string"},
          "escalation_role" => %{"type" => "string"},
          "required_authority" => %{"type" => "string"},
          "sla_s" => %{"type" => "number"},
          "selected_contact_id" => %{"type" => "string"},
          "deferred_contact_ids" => schema.(:string_array_schema),
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
          "priority_fields_without_numeric_evidence" => schema.(:string_array_schema),
          "candidate_diff" => %{"type" => "object"},
          "source_requirement" => schema.(:source_evidence_json_schema),
          "source_risk" => %{"type" => "object"},
          "source_recommendation" => %{"type" => "object"},
          "source_tradeoff" => %{"type" => "object"},
          "source_branch_comparison" => schema.(:branch_comparison_source_row_json_schema),
          "source_ranking_comparison" => schema.(:source_evidence_json_schema),
          "source_feedback" => schema.(:source_evidence_json_schema),
          "source_contention_group" => schema.(:source_evidence_json_schema),
          "source_invalid_contact_input" => schema.(:source_evidence_json_schema),
          "source_command_window" => schema.(:source_evidence_json_schema),
          "source_maneuver_review" => schema.(:source_evidence_json_schema),
          "source_station_calendar_review" => schema.(:source_evidence_json_schema),
          "source_link_capacity" => schema.(:source_evidence_json_schema),
          "source_resource_projection" => schema.(:source_evidence_json_schema),
          "source_resource_projection_flow_summary" => schema.(:source_evidence_json_schema),
          "source_delta" => schema.(:source_evidence_json_schema),
          "source_policy_decision" => schema.(:policy_decision_evidence_json_schema),
          "source_policy_escalation" => schema.(:policy_escalation_json_schema),
          "source_contact_suppression" => schema.(:source_evidence_json_schema),
          "source_resource_suppression" => schema.(:source_evidence_json_schema),
          "source_timeline_diff" => schema.(:source_evidence_json_schema),
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
          "source_timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "source_timeline_application" =>
            schema.(:timeline_transition_application_row_json_schema),
          "source_timeline_integrity" => schema.(:operational_timeline_row_json_schema),
          "source_timeline_activity_state" =>
            schema.(:timeline_activity_state_source_json_schema),
          "source_timeline_lifecycle_state" =>
            schema.(:timeline_lifecycle_state_source_json_schema),
          "source_timeline_activity_precondition_summary" =>
            schema.(:timeline_activity_precondition_summary_source_json_schema),
          "source_timeline_preservation" => schema.(:timeline_preservation_source_json_schema),
          "timeline_identity" => schema.(:timeline_identity_json_schema),
          "timeline_link" => schema.(:timeline_link_json_schema),
          "source_activity_context" => schema.(:activity_context_json_schema),
          "replacement_activity_context" => schema.(:activity_context_json_schema),
          "source_timeline_identity" => schema.(:timeline_identity_json_schema),
          "replacement_timeline_identity" => schema.(:timeline_identity_json_schema),
          "source_timeline_protection" => schema.(:timeline_protection_summary_json_schema)
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
        |> Map.merge(properties.(:resource_projection_battery_handoff_json_schema_properties))
        |> Map.merge(properties.(:branch_scoped_downlink_context_json_schema_properties))
        |> Map.merge(properties.(:scoped_downlink_context_json_schema_properties))
    }
  end
end
