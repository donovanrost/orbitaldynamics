defmodule OrbitalDynamics.Schema.BranchComparisonRowJsonSchema do
  @moduledoc false

  def row_from_context(deps) when is_list(deps) do
    row(
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema),
      string_array_schema: fetch_dep!(deps, :string_array_schema),
      numeric_map_schema: fetch_dep!(deps, :numeric_map_schema),
      branch_event_trust_boundary_status_counts_schema:
        fetch_dep!(deps, :branch_event_trust_boundary_status_counts_schema),
      non_negative_integer_properties: fetch_dep!(deps, :non_negative_integer_properties),
      branch_scoped_downlink_context_properties:
        fetch_dep!(deps, :branch_scoped_downlink_context_properties)
    )
  end

  def row(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    stable_id_array_schema = Keyword.fetch!(opts, :stable_id_array_schema)
    string_array_schema = Keyword.fetch!(opts, :string_array_schema)
    numeric_map_schema = Keyword.fetch!(opts, :numeric_map_schema)

    branch_event_trust_boundary_status_counts_schema =
      Keyword.fetch!(opts, :branch_event_trust_boundary_status_counts_schema)

    non_negative_integer_properties =
      Keyword.fetch!(opts, :non_negative_integer_properties)

    branch_scoped_downlink_context_properties =
      Keyword.fetch!(opts, :branch_scoped_downlink_context_properties)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "id",
        "rank",
        "branch_id",
        "score",
        "score_delta_from_recommended",
        "selected",
        "approval_status",
        "risk_count",
        "approval_requirement_count",
        "score_terms"
      ],
      "properties" =>
        %{
          "id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "rank" => %{"type" => "integer"},
          "branch_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "score" => %{"type" => "number"},
          "score_delta_from_recommended" => %{"type" => "number"},
          "raw_score" => %{"type" => "number"},
          "branch_probability" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
          "expected_score" => %{"type" => "number"},
          "selected" => %{"type" => "boolean"},
          "approval_status" => %{
            "type" => "string",
            "enum" => ["auto_approvable", "operator_review_required", "blocked_by_policy"]
          },
          "risk_count" => %{"type" => "integer"},
          "approval_requirement_count" => %{"type" => "integer"},
          "candidate_activity_count" => %{"type" => "integer"},
          "repair_delta_count" => %{"type" => "integer"},
          "repair_score" => %{"type" => "number"},
          "repair_score_term_count" => %{"type" => "integer"},
          "repair_score_term_keys" => string_array_schema,
          "repair_activity_score" => %{"type" => "number"},
          "repair_schedule_churn_penalty" => %{"type" => "number"},
          "repair_schedule_move_penalty" => %{"type" => "number"},
          "repair_link_contact_count" => %{"type" => "integer"},
          "repair_link_selected_contact_count" => %{"type" => "integer"},
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
          "fuel_margin" => %{"type" => "number"},
          "storage_margin" => %{"type" => "number"},
          "downlink_capacity_margin" => %{"type" => "number"},
          "spacecraft_availability" => %{"type" => "number"},
          "payload_availability" => %{"type" => "number"},
          "antenna_availability" => %{"type" => "number"},
          "resource_score_adjustment" => %{"type" => "number"},
          "resource_projection_spacecraft_count" => %{"type" => "integer"},
          "resource_projection_unavailable_spacecraft_count" => %{"type" => "integer"},
          "resource_projection_unavailable_spacecraft_ids" => stable_id_array_schema,
          "resource_projection_payload_unavailable_count" => %{"type" => "integer"},
          "resource_projection_payload_unavailable_spacecraft_ids" => stable_id_array_schema,
          "resource_projection_degraded_payload_unavailable_count" => %{"type" => "integer"},
          "resource_projection_degraded_payload_unavailable_spacecraft_ids" =>
            stable_id_array_schema,
          "resource_projection_antenna_unavailable_count" => %{"type" => "integer"},
          "resource_projection_antenna_unavailable_spacecraft_ids" => stable_id_array_schema,
          "resource_projection_availability_pressure_types" => string_array_schema,
          "resource_projection_flow_count" => %{"type" => "integer"},
          "projected_storage_margin" => %{"type" => "number"},
          "projected_storage_remaining_mb" => %{"type" => "number"},
          "projected_downlink_margin" => %{"type" => "number"},
          "projected_downlink_remaining_mb" => %{"type" => "number"},
          "projected_power_margin" => %{"type" => "number"},
          "projected_storage_overflow_mb" => %{"type" => "number"},
          "projected_downlink_shortfall_mb" => %{"type" => "number"},
          "projected_battery_overuse_wh" => %{"type" => "number"},
          "resource_projection_peak_storage_overflow_mb" => %{"type" => "number"},
          "resource_projection_peak_downlink_shortfall_mb" => %{"type" => "number"},
          "resource_projection_peak_battery_overuse_wh" => %{"type" => "number"},
          "resource_projection_peak_unused_downlink_capacity_mb" => %{"type" => "number"},
          "resource_projection_warning_count" => %{"type" => "integer"},
          "risk_types" => string_array_schema,
          "high_risk_types" => string_array_schema,
          "resource_pressure_statuses" => string_array_schema,
          "resource_pressure_types" => string_array_schema,
          "first_resource_pressure_kinds" => string_array_schema,
          "operational_readiness_report_ids" => string_array_schema,
          "operational_readiness_source_artifact_types" => string_array_schema,
          "operational_readiness_source_artifact_ids" => string_array_schema,
          "operational_readiness_levels" => string_array_schema,
          "operational_readiness_import_classifications" => string_array_schema,
          "operational_readiness_statuses" => string_array_schema,
          "operational_readiness_gate_ids" => string_array_schema,
          "operational_readiness_gate_statuses" => string_array_schema,
          "operational_readiness_gate_classifications" => string_array_schema,
          "operational_readiness_required_operator_actions" => string_array_schema,
          "operational_readiness_feedback_sources" => string_array_schema,
          "operational_readiness_feedback_scopes" => string_array_schema,
          "operational_readiness_feedback_keys" => string_array_schema,
          "operational_readiness_trust_boundaries" => string_array_schema,
          "quality_gate_report_ids" => string_array_schema,
          "quality_gate_source_artifact_types" => string_array_schema,
          "quality_gate_source_artifact_ids" => string_array_schema,
          "quality_gate_source_readiness_report_ids" => string_array_schema,
          "quality_gate_readiness_levels" => string_array_schema,
          "quality_gate_import_classifications" => string_array_schema,
          "quality_gate_pressure_statuses" => string_array_schema,
          "quality_gate_ids" => string_array_schema,
          "quality_gate_statuses" => string_array_schema,
          "quality_gate_classifications" => string_array_schema,
          "quality_gate_required_operator_actions" => string_array_schema,
          "quality_gate_feedback_sources" => string_array_schema,
          "quality_gate_feedback_scopes" => string_array_schema,
          "quality_gate_feedback_keys" => string_array_schema,
          "quality_gate_trust_boundaries" => string_array_schema,
          "quality_gate_resource_availability_reason_ids" => string_array_schema,
          "quality_gate_unavailable_resource_reason_ids" => string_array_schema,
          "first_resource_pressure_activity_id" => %{
            "type" => "string",
            "pattern" => stable_id_pattern
          },
          "first_resource_pressure_activity_type" => %{"type" => "string"},
          "first_resource_pressure_kind" => %{"type" => "string"},
          "first_resource_pressure_starts_at_s" => %{"type" => "number"},
          "first_resource_pressure_direction" => %{"type" => "string"},
          "first_resource_pressure_ground_station_id" => %{
            "type" => "string",
            "pattern" => stable_id_pattern
          },
          "first_resource_pressure_station_calendar_entry_id" => %{
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
          "first_resource_pressure_station_calendar_directions" => string_array_schema,
          "fuel_preservation_mode" => %{"type" => "boolean"},
          "resource_risk_types" => string_array_schema,
          "storage_limited_downlinked_mb" => %{"type" => "number"},
          "unused_downlink_capacity_mb" => %{"type" => "number"},
          "downlink_completion_required_contacts" => %{"type" => "integer", "minimum" => 0},
          "downlink_completion_planned_contacts" => %{"type" => "integer", "minimum" => 0},
          "downlink_completion_planned_downlink_mb" => %{"type" => "number"},
          "downlink_completion_ratio" => %{
            "type" => "number",
            "minimum" => 0.0,
            "maximum" => 1.0
          },
          "feedback_risk_types" => string_array_schema,
          "feedback_score_adjustment" => %{"type" => "number"},
          "observation_success_factor" => %{
            "type" => "number",
            "minimum" => 0.0,
            "maximum" => 1.0
          },
          "coverage_observed_target_count" => %{"type" => "integer"},
          "priority_commitment_required_target_count" => %{"type" => "integer"},
          "priority_commitment_satisfied_target_count" => %{"type" => "integer"},
          "priority_commitment_missed_target_count" => %{"type" => "integer"},
          "priority_commitment_required_target_ids" => stable_id_array_schema,
          "priority_commitment_satisfied_target_ids" => stable_id_array_schema,
          "priority_commitment_missed_target_ids" => stable_id_array_schema,
          "revisit_count" => %{"type" => "integer"},
          "branch_event_count" => %{"type" => "integer", "minimum" => 0},
          "branch_event_types" => string_array_schema,
          "branch_event_trust_boundary_status_counts" =>
            branch_event_trust_boundary_status_counts_schema,
          "combined_source_branch_ids" => stable_id_array_schema,
          "branch_ground_station_ids" => stable_id_array_schema,
          "branch_directions" => string_array_schema,
          "branch_station_availabilities" => string_array_schema,
          "branch_station_contention_statuses" => string_array_schema,
          "branch_station_calendar_entry_ids" => stable_id_array_schema,
          "branch_station_calendar_provider_ids" => stable_id_array_schema,
          "branch_station_calendar_provider_entry_ids" => stable_id_array_schema,
          "branch_station_calendar_directions" => string_array_schema,
          "branch_station_calendar_statuses" => string_array_schema,
          "branch_station_calendar_trust_boundary_statuses" => string_array_schema,
          "branch_station_reservation_ids" => stable_id_array_schema,
          "branch_station_reserved_by" => string_array_schema,
          "branch_station_reservation_statuses" => string_array_schema,
          "branch_station_reservation_match_statuses" => string_array_schema,
          "branch_station_reservation_conflict_contact_ids" => stable_id_array_schema,
          "branch_station_reservation_conflict_reservation_ids" => stable_id_array_schema,
          "branch_station_reservation_conflict_match_statuses" => string_array_schema,
          "branch_station_reservation_expiration_statuses" => string_array_schema,
          "branch_image_quality_min_score" => %{
            "type" => "number",
            "minimum" => 0.0,
            "maximum" => 1.0
          },
          "branch_image_quality_statuses" => string_array_schema,
          "branch_image_quality_sources" => string_array_schema,
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
          "capacity_pack_group_ids" => stable_id_array_schema,
          "capacity_pack_statuses" => string_array_schema,
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
          "capacity_pack_required_capacity_sources" => string_array_schema,
          "score_terms" => numeric_map_schema
        }
        |> Map.merge(non_negative_integer_properties)
        |> Map.merge(branch_scoped_downlink_context_properties)
    }
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      value when is_function(value, 0) -> value.()
      value -> value
    end
  end
end
