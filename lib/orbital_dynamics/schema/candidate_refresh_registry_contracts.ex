defmodule OrbitalDynamics.Schema.CandidateRefreshRegistryContracts do
  @moduledoc false

  @scoped_context_fields [
    "target_id",
    "target_ids",
    "collection_id",
    "collection_ids",
    "product_id",
    "product_ids",
    "payload_id",
    "payload_ids",
    "instrument_id",
    "instrument_ids",
    "objective_id",
    "objective_ids",
    "objective_type",
    "objective_types",
    "objective_status",
    "objective_statuses",
    "source_objective_status",
    "source_objective_statuses",
    "latency_objective",
    "max_latency_s",
    "planned_latency_s",
    "required_contacts",
    "planned_contacts",
    "required_downlink_mb",
    "planned_downlink_mb",
    "contact_result",
    "contact_results",
    "realized_status",
    "realized_statuses",
    "source_activity_id",
    "source_activity_ids",
    "missed_downlink_activity_id",
    "missed_downlink_activity_ids",
    "feedback_source",
    "feedback_sources",
    "feedback_scope",
    "feedback_scopes",
    "trust_boundary",
    "trust_boundaries",
    "derivation_reasons",
    "collection_latency_objective_ids",
    "collection_latency_objective_count",
    "collection_latency_objective_source",
    "collection_latency_objective_types",
    "candidate_downlink_mb",
    "downlink_completion_ratio",
    "selected_downlink_shortfall_mb",
    "downlink_requirement_status",
    "downlink_completion_source",
    "downlink_completion_sources"
  ]

  @publication_lineage_id_array_fields [
    "source_report_timeline_publication_ids",
    "source_report_timeline_publication_source_artifact_ids",
    "source_report_timeline_publication_supersedes_artifact_ids",
    "source_report_timeline_publication_downstream_product_ids",
    "source_report_timeline_publication_invalidated_downstream_product_ids",
    "source_report_timeline_publication_impacted_source_activity_ids",
    "source_report_timeline_publication_impacted_source_timeline_ids",
    "source_report_timeline_publication_dependent_activity_ids",
    "source_report_timeline_publication_dependent_timeline_ids",
    "source_report_timeline_publication_source_dependent_activity_ids",
    "source_report_timeline_publication_source_dependent_timeline_ids",
    "source_report_timeline_publication_replacement_dependent_activity_ids",
    "source_report_timeline_publication_replacement_dependent_timeline_ids",
    "source_report_operational_readiness_publication_ids",
    "source_report_operational_readiness_source_artifact_ids",
    "source_report_operational_readiness_supersedes_artifact_ids",
    "source_report_operational_readiness_downstream_product_ids",
    "source_report_operational_readiness_invalidated_downstream_product_ids",
    "source_report_quality_gate_publication_ids",
    "source_report_quality_gate_source_artifact_ids",
    "source_report_quality_gate_supersedes_artifact_ids",
    "source_report_quality_gate_downstream_product_ids",
    "source_report_quality_gate_invalidated_downstream_product_ids"
  ]

  @publication_lineage_count_map_fields [
    "source_report_timeline_publication_downstream_invalidation_reason_counts",
    "source_report_timeline_publication_source_artifact_type_counts",
    "source_report_operational_readiness_timeline_publication_source_artifact_type_counts",
    "source_report_quality_gate_timeline_publication_source_artifact_type_counts"
  ]

  @publication_lineage_stable_id_array_map_fields [
    "source_report_timeline_publication_invalidated_downstream_product_ids_by_reason"
  ]

  @resource_availability_count_fields [
    "source_report_operational_readiness_resource_availability_pressure_count",
    "source_report_quality_gate_resource_availability_pressure_count"
  ]

  @resource_availability_count_map_fields [
    "source_report_operational_readiness_resource_availability_reason_counts",
    "source_report_operational_readiness_station_availability_reason_counts",
    "source_report_operational_readiness_resource_blocking_dimension_counts",
    "source_report_quality_gate_resource_availability_reason_counts",
    "source_report_quality_gate_station_availability_reason_counts",
    "source_report_quality_gate_resource_blocking_dimension_counts"
  ]

  @resource_availability_string_array_fields [
    "source_report_operational_readiness_resource_availability_reason_ids",
    "source_report_operational_readiness_station_availability_reason_ids",
    "source_report_operational_readiness_unavailable_resource_reason_ids",
    "source_report_quality_gate_resource_availability_reason_ids",
    "source_report_quality_gate_station_availability_reason_ids",
    "source_report_quality_gate_unavailable_resource_reason_ids"
  ]

  def publication_lineage_id_array_fields, do: @publication_lineage_id_array_fields
  def publication_lineage_count_map_fields, do: @publication_lineage_count_map_fields

  def publication_lineage_stable_id_array_map_fields,
    do: @publication_lineage_stable_id_array_map_fields

  def contracts do
    %{
      "candidate_refresh.v1" => %{
        "schema_contract" => "candidate_refresh.v1",
        "artifact_family" => "candidate_refresh",
        "schema_version" => 1,
        "required_fields" => [
          "schema_version",
          "schema_contract",
          "artifact_type",
          "generated_at",
          "planner",
          "refresh_id",
          "study_id",
          "snapshot_id",
          "current_epoch_s",
          "remaining_horizon",
          "accepted_planning_state",
          "refreshed_windows",
          "candidate_activities",
          "contact_intents",
          "resource_summaries",
          "invalidated_candidates",
          "validation_records",
          "warnings",
          "assumptions",
          "provenance",
          "source_window_lineage"
        ],
        "nested_contracts" => [
          "candidate_activity.v1",
          "refreshed_window.v1",
          "invalidated_candidate.v1",
          "candidate_diff_report.v1",
          "candidate_rejection_report.v1",
          "freshness_report.v1",
          "contact_allocation_report.v1",
          "contact_filter_report.v1",
          "resource_filter_report.v1",
          "refresh_budget_report.v1",
          "candidate_refresh_execution.v1"
        ],
        "optional_fields" =>
          [
            "model_limits",
            "candidate_diff_report",
            "contact_allocation_report",
            "contact_filter_report",
            "freshness_report",
            "resource_filter_report",
            "candidate_rejection_report",
            "source_candidate_rejection_report",
            "refresh_budget_report",
            "operational_feedback",
            "candidate_refresh_execution"
          ] ++
            @publication_lineage_id_array_fields ++
            @publication_lineage_count_map_fields ++
            @publication_lineage_stable_id_array_map_fields ++
            @resource_availability_count_fields ++
            @resource_availability_count_map_fields ++
            @resource_availability_string_array_fields
      },
      "candidate_refresh_execution.v1" => %{
        "schema_contract" => "candidate_refresh_execution.v1",
        "artifact_family" => "candidate_refresh_execution",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "bundle_id",
          "execution_mode",
          "policy_fingerprint",
          "refresh_id",
          "study_id",
          "snapshot_id",
          "spacecraft_id",
          "scenario_id",
          "ground_station_id",
          "evidence",
          "counts",
          "policies",
          "external_validation",
          "model_limits"
        ],
        "nested_contracts" => []
      },
      "candidate_activity.v1" => %{
        "schema_contract" => "candidate_activity.v1",
        "artifact_family" => "candidate_activity",
        "schema_version" => 1,
        "required_fields" => ["id", "type", "scenario_id"],
        "nested_contracts" => []
      },
      "candidate_diff_row.v1" => %{
        "schema_contract" => "candidate_diff_row.v1",
        "artifact_family" => "candidate_diff_row",
        "schema_version" => 1,
        "required_fields" => ["schema_contract", "id", "type", "scenario_id", "diff_reason"],
        "optional_fields" =>
          [
            "starts_at_s",
            "ends_at_s",
            "target_id",
            "ground_station_id",
            "direction",
            "source_target_id",
            "source_target",
            "target_latitude_deg",
            "target_longitude_deg",
            "target_minimum_elevation_deg",
            "target_priority",
            "target_priority_source",
            "target_priority_objective_ids",
            "target_priority_objective_type",
            "matched_prior_candidate_id",
            "source_window_id",
            "semantic_change_reasons",
            "semantic_change_details",
            "changed_fields",
            "candidate_diff_changed_fields",
            "candidate_diff_changed_field_count"
          ] ++ @scoped_context_fields,
        "nested_contracts" => []
      },
      "candidate_diff_report.v1" => %{
        "schema_contract" => "candidate_diff_report.v1",
        "artifact_family" => "candidate_diff_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "prior_candidate_count",
          "refreshed_candidate_count",
          "retained_candidate_count",
          "new_candidate_count",
          "invalidated_candidate_count",
          "retained_candidates",
          "new_candidates",
          "invalidated_candidates"
        ],
        "optional_fields" => [
          "model_limits",
          "valid_prior_candidate_count",
          "invalid_prior_candidate_input_count",
          "invalid_prior_candidate_input_ids",
          "source_window_lineage"
        ],
        "nested_contracts" => []
      },
      "freshness_report.v1" => %{
        "schema_contract" => "freshness_report.v1",
        "artifact_family" => "freshness_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "generated_at",
          "accepted_at",
          "current_epoch_s",
          "horizon_starts_at_s",
          "accepted_snapshot_age_s",
          "horizon_start_offset_s",
          "max_snapshot_age_s",
          "max_horizon_start_offset_s",
          "status",
          "stale_reasons"
        ],
        "optional_fields" => [
          "model_limits",
          "accepted_state_quality_level",
          "state_quality_status",
          "allowed_state_quality_levels",
          "unknown_reasons"
        ],
        "nested_contracts" => []
      },
      "invalidated_candidate.v1" => %{
        "schema_contract" => "invalidated_candidate.v1",
        "artifact_family" => "invalidated_candidate",
        "schema_version" => 1,
        "required_fields" => ["schema_contract", "id", "invalidated_reason"],
        "optional_fields" =>
          [
            "type",
            "scenario_id",
            "starts_at_s",
            "ends_at_s",
            "target_id",
            "ground_station_id",
            "direction",
            "source_target_id",
            "source_target",
            "target_latitude_deg",
            "target_longitude_deg",
            "target_minimum_elevation_deg",
            "target_priority",
            "target_priority_source",
            "target_priority_objective_ids",
            "target_priority_objective_type",
            "replacement_candidate_id",
            "source_window_id",
            "semantic_change_reasons",
            "semantic_change_details",
            "changed_fields",
            "candidate_diff_changed_fields",
            "candidate_diff_changed_field_count"
          ] ++ @scoped_context_fields,
        "nested_contracts" => []
      },
      "refresh_budget_report.v1" => %{
        "schema_contract" => "refresh_budget_report.v1",
        "artifact_family" => "refresh_budget_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "input_candidate_count",
          "kept_candidate_count",
          "dropped_candidate_count",
          "kept_candidate_ids",
          "dropped_candidate_ids",
          "max_candidate_activities",
          "selection_order",
          "assumptions"
        ],
        "optional_fields" => ["model_limits", "invalid_candidate_limit_policy"],
        "nested_contracts" => []
      },
      "refreshed_window.v1" => %{
        "schema_contract" => "refreshed_window.v1",
        "artifact_family" => "refreshed_window",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "id",
          "type",
          "scenario_id",
          "starts_at_s",
          "ends_at_s"
        ],
        "optional_fields" => [
          "target_id",
          "ground_station_id",
          "sample_count",
          "minimum_elevation_deg",
          "max_elevation_deg",
          "target_priority",
          "assumptions"
        ],
        "nested_contracts" => []
      },
      "remaining_horizon.v1" => %{
        "schema_contract" => "remaining_horizon.v1",
        "artifact_family" => "remaining_horizon",
        "schema_version" => 1,
        "required_fields" => ["schema_contract", "starts_at_s", "ends_at_s", "output_step_s"],
        "nested_contracts" => []
      },
      "source_window_lineage.v1" => %{
        "schema_contract" => "source_window_lineage.v1",
        "artifact_family" => "source_window_lineage",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "candidate_activity_id",
          "source_window_id",
          "source_window_type",
          "scenario_id"
        ],
        "optional_fields" => ["source_window"] ++ @scoped_context_fields,
        "nested_contracts" => []
      }
    }
  end
end
