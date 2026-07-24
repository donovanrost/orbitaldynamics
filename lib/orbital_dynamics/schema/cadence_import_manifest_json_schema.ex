defmodule OrbitalDynamics.Schema.CadenceImportManifestJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    CommonJsonSchema,
    ContactAllocationCapabilityContext,
    LazyProviderResolver
  }

  def row(opts) do
    capability = Keyword.fetch!(opts, :capability)
    readiness_capability = Keyword.fetch!(opts, :readiness_capability)
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    schema = LazyProviderResolver.resolver(Keyword.fetch!(opts, :schema_providers))
    properties = LazyProviderResolver.resolver(Keyword.fetch!(opts, :property_providers))

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["id", "rank", "import_action", "import_status"],
      "properties" =>
        %{
          "id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "rank" => %{"type" => "integer"},
          "subject_id" => %{"type" => "string"},
          "activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "activity_type" => %{"type" => "string"},
          "target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
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
          "source_review_row_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "source_review_type" => %{
            "type" => "string",
            "enum" => capability.source_review_types
          },
          "source_review_action" => %{"type" => "string"},
          "source_review_queue" => %{"type" => "string"},
          "source_review_queue_key" => %{"type" => "string"},
          "source_review_row" => schema.(:cadence_source_review_row_json_schema),
          "source_operational_timeline" => schema.(:operational_timeline_row_json_schema),
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
          "source_quality_gate_row" => schema.(:quality_gate_report_row_json_schema),
          "source_quality_gate_report" =>
            schema.(:quality_gate_source_report_evidence_json_schema),
          "source_refresh_budget_report" => schema.(:source_evidence_json_schema),
          "source_operational_readiness_gate" => schema.(:operational_readiness_gate_json_schema),
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
          "import_action" => %{
            "type" => "string",
            "enum" => capability.import_actions
          },
          "import_status" => %{
            "type" => "string",
            "enum" => capability.import_statuses
          },
          "cadence_import_status" => schema.(:cadence_import_status_json_schema),
          "source_cadence_import_status" => schema.(:cadence_import_status_json_schema),
          "replacement_cadence_import_status" => schema.(:cadence_import_status_json_schema),
          "cadence_import_type" => %{"type" => "string"},
          "cadence_import_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "cadence_import_contract" => %{"type" => "string"},
          "has_cadence_import" => %{"type" => "boolean"},
          "approval_status" => %{"type" => "string"},
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
          "provider_reservation_request_contact_ids" => schema.(:stable_id_array_schema),
          "provider_reservation_request_source_activity_ids" => schema.(:stable_id_array_schema),
          "provider_reservation_request_ground_station_ids" => schema.(:stable_id_array_schema),
          "provider_reservation_request_directions" => schema.(:string_array_schema),
          "provider_reservation_request_station_reservation_ids" =>
            schema.(:stable_id_array_schema),
          "provider_reservation_request_station_reserved_by" => schema.(:string_array_schema),
          "provider_reservation_request_station_reservation_statuses" =>
            schema.(:string_array_schema),
          "provider_reservation_request_station_reservation_match_statuses" =>
            schema.(:string_array_schema),
          "provider_reservation_request_statuses" => schema.(:string_array_schema),
          "provider_reservation_request_row_scopes" => schema.(:string_array_schema),
          "provider_reservation_request_required_operator_actions" =>
            schema.(:string_array_schema),
          "provider_reservation_request_assumption_maps" => %{
            "type" => "array",
            "items" => %{"type" => "object", "additionalProperties" => true}
          },
          "provider_reservation_request_feedback_sources" => schema.(:string_array_schema),
          "provider_reservation_request_feedback_scopes" => schema.(:string_array_schema),
          "provider_reservation_request_trust_boundaries" => schema.(:string_array_schema),
          "provider_reservation_request_station_reservation_expiration_statuses" =>
            schema.(:string_array_schema),
          "capacity_pack_risk_contact_ids" => schema.(:stable_id_array_schema),
          "capacity_pack_risk_source_activity_ids" => schema.(:stable_id_array_schema),
          "capacity_pack_risk_ground_station_ids" => schema.(:stable_id_array_schema),
          "capacity_pack_risk_group_ids" => schema.(:stable_id_array_schema),
          "capacity_pack_risk_statuses" => schema.(:string_array_schema),
          "capacity_pack_risk_capacity_fraction_values" => CommonJsonSchema.probability_array(),
          "capacity_pack_risk_used_fraction_values" => CommonJsonSchema.probability_array(),
          "capacity_pack_risk_unused_fraction_values" => CommonJsonSchema.probability_array(),
          "capacity_pack_risk_required_capacity_fraction_values" =>
            CommonJsonSchema.probability_array(),
          "capacity_pack_risk_required_capacity_fraction_sources" =>
            schema.(:string_array_schema),
          "capacity_pack_risk_derivation_reasons" => schema.(:string_array_schema),
          "capacity_pack_risk_feedback_sources" => schema.(:string_array_schema),
          "capacity_pack_risk_feedback_scopes" => schema.(:string_array_schema),
          "capacity_pack_risk_trust_boundaries" => schema.(:string_array_schema),
          "contact_contention_resolution_pressure_risk_types" => schema.(:string_array_schema),
          "contact_contention_resolution_pressure_contact_ids" =>
            schema.(:stable_id_array_schema),
          "contact_contention_resolution_pressure_selected_contact_ids" =>
            schema.(:stable_id_array_schema),
          "contact_contention_resolution_pressure_scenario_ids" =>
            schema.(:stable_id_array_schema),
          "contact_contention_resolution_pressure_spacecraft_ids" =>
            schema.(:stable_id_array_schema),
          "contact_contention_resolution_pressure_ground_station_ids" =>
            schema.(:stable_id_array_schema),
          "contact_contention_resolution_pressure_source_activity_ids" =>
            schema.(:stable_id_array_schema),
          "contact_contention_resolution_pressure_source_window_ids" =>
            schema.(:stable_id_array_schema),
          "station_reservation_conflict_contact_ids" => schema.(:stable_id_array_schema),
          "station_reservation_conflict_source_activity_ids" => schema.(:stable_id_array_schema),
          "station_reservation_conflict_ground_station_ids" => schema.(:stable_id_array_schema),
          "station_reservation_conflict_reservation_ids" => schema.(:stable_id_array_schema),
          "station_reservation_conflict_reserved_by" => schema.(:string_array_schema),
          "station_reservation_conflict_statuses" => schema.(:string_array_schema),
          "station_reservation_conflict_match_statuses" => schema.(:string_array_schema),
          "station_reservation_conflict_expires_at_values_s" => schema.(:number_array_schema),
          "station_reservation_conflict_expiration_statuses" => schema.(:string_array_schema),
          "station_reservation_conflict_derivation_reasons" => schema.(:string_array_schema),
          "station_reservation_conflict_feedback_sources" => schema.(:string_array_schema),
          "station_reservation_conflict_feedback_scopes" => schema.(:string_array_schema),
          "station_reservation_conflict_trust_boundaries" => schema.(:string_array_schema),
          "station_reservation_hold_import_statuses" => schema.(:string_array_schema),
          "station_reservation_hold_import_readiness_summary_models" =>
            schema.(:string_array_schema),
          "station_reservation_hold_import_readiness_sources" => schema.(:string_array_schema),
          "station_reservation_hold_import_readiness_source_artifact_types" =>
            schema.(:string_array_schema),
          "station_reservation_hold_import_readiness_statuses" => schema.(:string_array_schema),
          "station_reservation_hold_import_classifications" => schema.(:string_array_schema),
          "station_reservation_hold_count_values" => schema.(:non_negative_integer_array_schema),
          "station_reservation_hold_ids" => schema.(:stable_id_array_schema),
          "station_reservation_hold_ids_by_import_status" => %{
            "type" => "array",
            "items" => schema.(:stable_id_array_map_schema)
          },
          "station_reservation_hold_ids_by_required_import_action" => %{
            "type" => "array",
            "items" => schema.(:stable_id_array_map_schema)
          },
          "station_reservation_hold_ids_by_direction" => %{
            "type" => "array",
            "items" => schema.(:stable_id_array_map_schema)
          },
          "station_reservation_hold_ids_by_direction_and_ground_station_id" => %{
            "type" => "array",
            "items" => schema.(:stable_id_array_map_schema)
          },
          "station_reservation_hold_contact_ids" => schema.(:stable_id_array_schema),
          "station_reservation_hold_contact_ids_by_import_status" => %{
            "type" => "array",
            "items" => schema.(:stable_id_array_map_schema)
          },
          "station_reservation_hold_contact_ids_by_expiration_status" => %{
            "type" => "array",
            "items" => schema.(:stable_id_array_map_schema)
          },
          "station_reservation_hold_contact_ids_by_direction" => %{
            "type" => "array",
            "items" => schema.(:stable_id_array_map_schema)
          },
          "station_reservation_hold_contact_ids_by_direction_and_ground_station_id" => %{
            "type" => "array",
            "items" => schema.(:stable_id_array_map_schema)
          },
          "station_reservation_hold_import_status_count_maps" => %{
            "type" => "array",
            "items" => schema.(:non_negative_integer_count_map_schema)
          },
          "station_reservation_hold_required_import_action_count_maps" => %{
            "type" => "array",
            "items" => schema.(:non_negative_integer_count_map_schema)
          },
          "station_reservation_hold_import_execution_boundaries" => schema.(:string_array_schema),
          "station_reservation_hold_provider_write_values" => schema.(:string_array_schema),
          "station_reservation_hold_cadence_write_values" => schema.(:string_array_schema),
          "station_reservation_hold_reservation_acceptance_values" =>
            schema.(:string_array_schema),
          "station_reservation_hold_feedback_sources" => schema.(:string_array_schema),
          "station_reservation_hold_feedback_scopes" => schema.(:string_array_schema),
          "station_reservation_hold_trust_boundaries" => schema.(:string_array_schema),
          "source_station_reservation_hold_import_readiness_summaries" => %{
            "type" => "array",
            "items" =>
              schema.(:station_reservation_hold_import_readiness_summary_source_json_schema)
          },
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
            CommonJsonSchema.probability_array(),
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
          "required_operator_action" => %{"type" => "string"},
          "repair_action" => %{"type" => "string"},
          "source_delta" => schema.(:source_evidence_json_schema),
          "import_side" => %{"type" => "string"},
          "timeline_link" => schema.(:timeline_link_json_schema),
          "source_timeline_identity" => schema.(:timeline_identity_json_schema),
          "replacement_timeline_identity" => schema.(:timeline_identity_json_schema),
          "import_activity_context" => schema.(:activity_context_json_schema),
          "source_activity_context" => schema.(:activity_context_json_schema),
          "realized_activity_context" => schema.(:activity_context_json_schema),
          "replacement_activity_context" => schema.(:activity_context_json_schema),
          "contention_group_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "station_calendar_entry_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "station_calendar_provider_id" => %{
            "type" => "string",
            "pattern" => stable_id_pattern
          },
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
          "station_reservation_expires_at_s" => schema.(:number_or_number_array_schema),
          "trust_boundary" => %{"type" => "string"},
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
          "selected_contact_id" => %{"type" => "string"},
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
          "pack_status" => %{"type" => "string"},
          "source_timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "replacement_activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "replacement_timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
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
          "selected_activity_source" => %{"type" => "string"},
          "selected_activity" => %{"type" => "object", "additionalProperties" => true},
          "selected_timeline_integrity_status" => %{"type" => "string"},
          "selected_timeline_integrity_issue_count" => %{"type" => "integer", "minimum" => 0},
          "selected_timeline_integrity_issue_types" => %{
            "type" => "array",
            "items" => %{
              "type" => "string",
              "enum" => OrbitalDynamics.Timeline.capabilities().timeline_integrity_issue_types
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
          "attitude_confidence" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0}
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
          OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.cadence_import_context_properties()
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

  @enum_count_fields [
    "import_action_counts",
    "import_status_counts",
    "cadence_import_status_counts",
    "source_review_type_counts"
  ]

  @non_negative_count_map_fields [
    "source_review_action_counts",
    "source_review_queue_counts"
  ]

  @readiness_scalar_fields [
    "source_readiness_report_id",
    "readiness_level",
    "import_classification",
    "status"
  ]

  @review_import_count_map_fields [
    "calendar_entry_trust_boundary_status_counts",
    "station_reservation_match_status_counts",
    "station_reservation_status_counts",
    "station_reserved_by_counts",
    "station_reservation_expiration_status_counts",
    "resource_blocking_dimension_counts",
    "gate_status_counts",
    "gate_classification_counts",
    "required_capacity_fraction_source_counts",
    "capacity_pack_status_counts",
    "provider_reservation_request_status_counts",
    "reduced_capacity_pack_status_counts",
    "station_pressure_contact_counts_by_ground_station_id",
    "station_pressure_contact_counts_by_availability",
    "station_pressure_contact_counts_by_precedence_availability",
    "station_pressure_contact_counts_by_precedence_rank",
    "station_pressure_contact_counts_by_status"
  ]

  @review_import_scalar_count_fields [
    "station_reservation_declared_expiration_contact_count",
    "station_reservation_missing_expiration_contact_count",
    "station_pressure_contact_count",
    "station_pressure_review_contact_count",
    "provider_reservation_candidate_contact_count",
    "provider_reservation_request_contact_count",
    "provider_reservation_review_contact_count",
    "provider_reservation_no_request_contact_count",
    "gate_count",
    "passed_gate_count",
    "review_gate_count",
    "analysis_gate_count",
    "blocked_gate_count"
  ]

  @capacity_fraction_fields [
    "capacity_pack_required_capacity_fraction",
    "capacity_pack_selected_required_capacity_fraction",
    "capacity_pack_deferred_required_capacity_fraction"
  ]

  @capacity_fraction_map_fields [
    "capacity_pack_required_capacity_fraction_by_status",
    "capacity_pack_required_capacity_fraction_by_ground_station_id",
    "capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
    "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"
  ]

  @stable_id_array_fields [
    "station_reservation_ids",
    "station_pressure_contact_ids",
    "station_pressure_review_contact_ids",
    "capacity_pack_group_ids",
    "provider_reservation_request_contact_ids",
    "provider_reservation_review_contact_ids",
    "provider_reservation_no_request_contact_ids",
    "passed_gate_ids",
    "review_required_gate_ids",
    "analysis_only_gate_ids",
    "blocked_gate_ids",
    "reduced_capacity_packed_contact_ids",
    "reduced_capacity_deferred_contact_ids"
  ]

  @stable_id_array_map_fields [
    "station_reservation_contact_ids_by_expiration_status",
    "station_reservation_ids_by_expiration_status",
    "station_reservation_contact_ids_by_match_status",
    "station_reservation_contact_ids_by_status",
    "station_reservation_contact_ids_by_reserved_by",
    "station_reservation_ids_by_match_status",
    "station_reservation_ids_by_status",
    "station_reservation_ids_by_reserved_by",
    "resource_blocked_contact_ids_by_blocking_dimension",
    "resource_blocked_contact_ids_by_spacecraft_id",
    "capacity_pack_contact_ids_by_status",
    "capacity_pack_contact_ids_by_ground_station_id",
    "capacity_pack_selected_contact_ids_by_ground_station_id",
    "capacity_pack_deferred_contact_ids_by_ground_station_id",
    "required_capacity_fraction_contact_ids_by_source",
    "provider_reservation_request_contact_ids_by_ground_station_id",
    "provider_reservation_review_contact_ids_by_ground_station_id",
    "provider_reservation_no_request_contact_ids_by_direction",
    "provider_reservation_request_contact_ids_by_direction",
    "provider_reservation_review_contact_ids_by_direction",
    "reservation_conflict_contact_ids_by_direction",
    "provider_reservation_request_contact_ids_by_match_status",
    "provider_reservation_review_contact_ids_by_match_status",
    "provider_reservation_request_ids_by_match_status",
    "provider_reservation_review_ids_by_match_status",
    "gate_ids_by_status",
    "gate_ids_by_classification",
    "quality_gate_row_ids_by_status",
    "quality_gate_row_ids_by_classification",
    "capacity_pack_group_ids_by_status",
    "station_pressure_contact_ids_by_ground_station_id",
    "station_pressure_contact_ids_by_availability",
    "station_pressure_contact_ids_by_precedence_availability",
    "station_pressure_contact_ids_by_precedence_rank",
    "station_pressure_contact_ids_by_status",
    "station_pressure_contact_ids_by_direction"
  ]

  @provider_reservation_match_status_route_fields [
    "provider_reservation_request_contact_ids_by_match_status",
    "provider_reservation_review_contact_ids_by_match_status",
    "provider_reservation_request_ids_by_match_status",
    "provider_reservation_review_ids_by_match_status"
  ]
  @provider_reservation_request_match_status_route_fields [
    "provider_reservation_request_contact_ids_by_match_status",
    "provider_reservation_request_ids_by_match_status"
  ]

  @correlated_station_pressure_id_map_fields [
    "station_pressure_contact_ids_by_ground_station_id",
    "station_pressure_contact_ids_by_availability",
    "station_pressure_contact_ids_by_precedence_availability",
    "station_pressure_contact_ids_by_precedence_rank",
    "station_pressure_contact_ids_by_status",
    "station_pressure_contact_ids_by_direction"
  ]
  @canonical_id_map_fields @correlated_station_pressure_id_map_fields ++
                             [
                               "capacity_pack_contact_ids_by_status",
                               "capacity_pack_group_ids_by_status",
                               "required_capacity_fraction_contact_ids_by_source",
                               "station_reservation_contact_ids_by_match_status",
                               "station_reservation_contact_ids_by_expiration_status",
                               "station_reservation_contact_ids_by_status",
                               "station_reservation_contact_ids_by_reserved_by",
                               "station_reservation_ids_by_expiration_status",
                               "station_reservation_ids_by_match_status",
                               "station_reservation_ids_by_status",
                               "station_reservation_ids_by_reserved_by",
                               "provider_reservation_no_request_contact_ids_by_direction",
                               "provider_reservation_request_contact_ids_by_ground_station_id",
                               "provider_reservation_request_contact_ids_by_direction",
                               "provider_reservation_request_contact_ids_by_match_status",
                               "provider_reservation_review_contact_ids_by_ground_station_id",
                               "provider_reservation_review_contact_ids_by_direction",
                               "provider_reservation_review_contact_ids_by_match_status",
                               "provider_reservation_request_ids_by_match_status",
                               "provider_reservation_review_ids_by_match_status"
                             ]

  @nested_stable_id_array_map_fields [
    "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id",
    "provider_reservation_request_contact_ids_by_direction_and_ground_station_id",
    "provider_reservation_review_contact_ids_by_direction_and_ground_station_id",
    "reservation_conflict_contact_ids_by_direction_and_ground_station_id",
    "station_pressure_contact_ids_by_direction_and_ground_station_id"
  ]

  @string_array_fields [
    "station_reserved_bys",
    "station_reservation_statuses"
  ]

  @base_fields [
    "source_artifact_type",
    "model",
    "model_limits",
    "rows"
  ]

  def property_field?(field, scalar_count_fields) do
    field in @base_fields or field in scalar_count_fields or field in @enum_count_fields or
      field in @non_negative_count_map_fields or field in @readiness_scalar_fields or
      field in @review_import_count_map_fields or field in @review_import_scalar_count_fields or
      field in @capacity_fraction_fields or field in @capacity_fraction_map_fields or
      field in @stable_id_array_fields or field in @stable_id_array_map_fields or
      field in @nested_stable_id_array_map_fields or field in @string_array_fields or
      field in [
        "station_reservation_expires_at_s",
        "earliest_station_reservation_expires_at_s"
      ]
  end

  def property_opts("source_readiness_report_id", deps) do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(field, deps)
      when field in ["readiness_level", "import_classification", "status"] do
    [readiness_capability: fetch_dep!(deps, :readiness_capability)]
  end

  def property_opts(field, deps)
      when field in @stable_id_array_fields or field in @stable_id_array_map_fields or
             field in @nested_stable_id_array_map_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts("source_artifact_type", deps) do
    [capability: fetch_dep!(deps, :capability)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts("rows", deps) do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts(field, deps) when field in @enum_count_fields do
    [capability: fetch_dep!(deps, :capability)]
  end

  def property_opts(field, deps) do
    scalar_count_fields = fetch_dep!(deps, :scalar_count_fields)

    if field in scalar_count_fields do
      [scalar_count_fields: scalar_count_fields]
    else
      []
    end
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property("source_readiness_report_id", opts) do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def property("readiness_level", opts) do
    %{
      "type" => "string",
      "enum" => Keyword.fetch!(opts, :readiness_capability).readiness_levels
    }
  end

  def property("import_classification", opts) do
    %{
      "type" => "string",
      "enum" => Keyword.fetch!(opts, :readiness_capability).import_classifications
    }
  end

  def property("status", opts) do
    %{
      "type" => "string",
      "enum" => Keyword.fetch!(opts, :readiness_capability).gate_statuses
    }
  end

  def property("provider_reservation_request_status_counts", _opts) do
    ContactAllocationCapabilityContext.contact_allocation_provider_reservation_request_statuses()
    |> CommonJsonSchema.enum_count_map()
  end

  def property(field, _opts) when field in @review_import_count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, _opts) when field in @review_import_scalar_count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, _opts) when field in @capacity_fraction_fields do
    %{"type" => "number", "minimum" => 0.0}
  end

  def property(field, _opts) when field in @capacity_fraction_map_fields do
    CommonJsonSchema.non_negative_number_map()
  end

  def property("earliest_station_reservation_expires_at_s", _opts) do
    %{"type" => "number"}
  end

  def property("station_reservation_expires_at_s", _opts) do
    CommonJsonSchema.number_array()
    |> Map.put("uniqueItems", true)
  end

  def property(field, opts)
      when field in [
             "station_pressure_contact_ids",
             "station_pressure_review_contact_ids",
             "station_reservation_ids",
             "capacity_pack_group_ids",
             "provider_reservation_no_request_contact_ids",
             "provider_reservation_request_contact_ids",
             "provider_reservation_review_contact_ids"
           ] do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
    |> Map.put("uniqueItems", true)
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, opts) when field in @provider_reservation_match_status_route_fields do
    all_match_statuses =
      ContactAllocationCapabilityContext.contact_allocation_capabilities()
      |> Map.fetch!(:station_reservation_match_statuses)

    match_statuses =
      if field in @provider_reservation_request_match_status_route_fields,
        do: Enum.filter(all_match_statuses, &(&1 in ["matched", "owner_matched"])),
        else: all_match_statuses

    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.enum_stable_id_array_map(match_statuses)
    |> Map.update!("additionalProperties", &Map.put(&1, "uniqueItems", true))
  end

  def property(field, opts) when field in @canonical_id_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
    |> Map.update!("additionalProperties", &Map.put(&1, "uniqueItems", true))
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def property(field, opts)
      when field in [
             "station_pressure_contact_ids_by_direction_and_ground_station_id",
             "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id",
             "provider_reservation_request_contact_ids_by_direction_and_ground_station_id",
             "provider_reservation_review_contact_ids_by_direction_and_ground_station_id"
           ] do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.nested_stable_id_array_map()
    |> Map.update!("additionalProperties", fn id_map_schema ->
      Map.update!(id_map_schema, "additionalProperties", &Map.put(&1, "uniqueItems", true))
    end)
  end

  def property(field, opts) when field in @nested_stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.nested_stable_id_array_map()
  end

  def property(field, _opts) when field in @string_array_fields do
    CommonJsonSchema.string_array()
    |> Map.put("uniqueItems", true)
  end

  def property("source_artifact_type", opts) do
    capability = Keyword.fetch!(opts, :capability)

    %{
      "type" => "string",
      "enum" => capability.supported_sources
    }
  end

  def property("model", _opts) do
    %{
      "type" => "string",
      "const" => "artifact_only_cadence_import_manifest"
    }
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{
        "type" => "string",
        "enum" => model_limits
      }
    }
  end

  def property("rows", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property(field, _opts) when field in @non_negative_count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, opts) when field in @enum_count_fields do
    opts
    |> Keyword.fetch!(:capability)
    |> enum_count_values(field)
    |> CommonJsonSchema.enum_count_map()
  end

  def property(field, opts) do
    scalar_count_fields = Keyword.fetch!(opts, :scalar_count_fields)

    if field in scalar_count_fields do
      %{"type" => "integer", "minimum" => 0}
    else
      raise ArgumentError, "unknown Cadence import manifest JSON Schema property: #{field}"
    end
  end

  defp enum_count_values(capability, "import_action_counts"), do: capability.import_actions

  defp enum_count_values(capability, "import_status_counts"), do: capability.import_statuses

  defp enum_count_values(capability, "cadence_import_status_counts"),
    do: capability.cadence_import_statuses

  defp enum_count_values(capability, "source_review_type_counts"),
    do: capability.source_review_types

  defp fetch_dep!(deps, key), do: Keyword.fetch!(deps, key)
end
