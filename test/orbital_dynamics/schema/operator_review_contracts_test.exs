defmodule OrbitalDynamics.Schema.OperatorReviewContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "exports nested operator review package row schema" do
    assert {:ok, schema} = Schema.json_schema("operator_review_package.v1")

    row_schema = get_in(schema, ["properties", "rows", "items"])

    assert row_schema["type"] == "object"
    assert "review_type" in row_schema["required"]

    assert "contact_contention_review" in get_in(row_schema, ["properties", "review_type", "enum"])

    assert "command_window_review" in get_in(row_schema, ["properties", "review_type", "enum"])
    assert "station_calendar_review" in get_in(row_schema, ["properties", "review_type", "enum"])
    assert "link_capacity_review" in get_in(row_schema, ["properties", "review_type", "enum"])

    assert "contact_allocation_capacity_pack_review" in get_in(row_schema, [
             "properties",
             "review_type",
             "enum"
           ])

    assert "timeline_protection" in get_in(row_schema, ["properties", "review_type", "enum"])
    assert "policy_escalation" in get_in(row_schema, ["properties", "review_type", "enum"])

    assert "resource_projection_review" in get_in(row_schema, [
             "properties",
             "review_type",
             "enum"
           ])

    assert "timeline_diff_review" in get_in(row_schema, ["properties", "review_type", "enum"])
    assert "maneuver_review" in get_in(row_schema, ["properties", "review_type", "enum"])
    assert "contact_suppression" in get_in(row_schema, ["properties", "review_type", "enum"])
    assert "resource_suppression" in get_in(row_schema, ["properties", "review_type", "enum"])
    assert "strategy_tradeoff" in get_in(row_schema, ["properties", "review_type", "enum"])

    assert "ranking_comparison_review" in get_in(row_schema, ["properties", "review_type", "enum"])

    assert get_in(row_schema, ["properties", "id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "delta", "type"]) == "number"
    assert get_in(row_schema, ["properties", "repair_score", "type"]) == "number"

    assert get_in(row_schema, ["properties", "station_reservation_expires_at_s"]) == %{
             "anyOf" => [
               %{"type" => "number"},
               %{"type" => "array", "items" => %{"type" => "number"}}
             ]
           }

    assert get_in(row_schema, [
             "properties",
             "first_resource_pressure_station_calendar_provider_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "first_resource_pressure_station_calendar_provider_entry_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "repair_score_term_keys", "items", "type"]) ==
             "string"

    assert get_in(row_schema, ["properties", "source_contention_group", "type"]) == "object"

    assert get_in(row_schema, [
             "properties",
             "source_contention_group",
             "properties",
             "ground_station_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "source_tradeoff", "type"]) == "object"
    assert get_in(row_schema, ["properties", "source_branch_comparison", "type"]) == "object"

    assert get_in(row_schema, [
             "properties",
             "source_branch_comparison",
             "properties",
             "first_resource_pressure_station_calendar_provider_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "collection_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "branch_collection_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "source_branch_comparison",
             "properties",
             "branch_collection_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "source_branch_comparison",
             "properties",
             "downlink_completion_required_contacts"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(row_schema, [
             "properties",
             "source_branch_comparison",
             "properties",
             "priority_commitment_required_target_count"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(row_schema, ["properties", "source_ranking_comparison", "type"]) == "object"

    assert get_in(row_schema, [
             "properties",
             "source_ranking_comparison",
             "properties",
             "scenario_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "source_policy_decision", "type"]) == "object"
    assert get_in(row_schema, ["properties", "source_command_window", "type"]) == "object"

    assert get_in(row_schema, [
             "properties",
             "source_command_window",
             "properties",
             "activity_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "source_maneuver_review", "type"]) == "object"

    assert get_in(row_schema, [
             "properties",
             "source_maneuver_review",
             "properties",
             "maneuver_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "source_station_calendar_review", "type"]) ==
             "object"

    assert get_in(row_schema, [
             "properties",
             "source_station_calendar_review",
             "properties",
             "ground_station_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "source_feedback", "type"]) == "object"

    assert get_in(row_schema, [
             "properties",
             "source_feedback",
             "properties",
             "activity_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    Enum.each(
      [
        "contact_success_factor",
        "command_success_factor",
        "observation_success_factor",
        "maneuver_success_factor"
      ],
      fn field ->
        assert get_in(row_schema, [
                 "properties",
                 "source_feedback",
                 "properties",
                 field
               ]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }
      end
    )

    assert get_in(row_schema, ["properties", "source_link_capacity", "type"]) == "object"
    assert get_in(row_schema, ["properties", "source_resource_projection", "type"]) == "object"

    Enum.each(
      ["capacity_fraction", "used_capacity_fraction", "unused_capacity_fraction"],
      fn field ->
        assert get_in(row_schema, ["properties", field]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }
      end
    )

    assert get_in(row_schema, ["properties", "capacity_packed_contact_ids", "items", "type"]) ==
             "string"

    assert get_in(row_schema, [
             "properties",
             "capacity_pack_group_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "capacity_pack_required_capacity_sources",
             "items",
             "type"
           ]) == "string"

    assert get_in(row_schema, ["properties", "source_timeline_diff", "type"]) == "object"

    assert get_in(row_schema, [
             "properties",
             "source_timeline_diff",
             "properties",
             "timeline_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "source_timeline_diff",
             "properties",
             "diff_status",
             "enum"
           ]) == ["added", "removed", "changed", "unchanged"]

    assert get_in(row_schema, [
             "properties",
             "source_timeline_application",
             "properties",
             "application_status",
             "type"
           ]) == "string"

    assert get_in(row_schema, [
             "properties",
             "timeline_link",
             "properties",
             "source_timeline_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "source_timeline_protection",
             "properties",
             "changed_executed_count",
             "minimum"
           ]) == 0

    assert get_in(row_schema, ["properties", "source_window", "properties", "id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "replacement_source_window_lineage",
             "properties",
             "candidate_activity_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "source_delta",
             "properties",
             "activity_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "source_requirement",
             "properties",
             "activity_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "source_contact_suppression",
             "properties",
             "source_window_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "source_resource_suppression",
             "properties",
             "id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "source_link_capacity",
             "properties",
             "ground_station_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "source_resource_projection",
             "properties",
             "spacecraft_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "changed_fields", "items", "type"]) == "string"
    assert get_in(row_schema, ["properties", "requires_operator_review", "type"]) == "boolean"
    assert get_in(row_schema, ["properties", "window_type", "type"]) == "string"
    assert get_in(row_schema, ["properties", "maneuver_id", "type"]) == "string"
    assert get_in(row_schema, ["properties", "delta_v_km_s", "items", "type"]) == "number"
    assert get_in(row_schema, ["properties", "contact_id", "type"]) == "string"
    assert get_in(row_schema, ["properties", "contact_ids", "items", "type"]) == "string"
    assert get_in(row_schema, ["properties", "scenario_ids", "items", "type"]) == "string"
    assert get_in(row_schema, ["properties", "station_calendar_entry_id", "type"]) == "string"

    assert get_in(row_schema, ["properties", "contact_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(row_schema, ["properties", "selected_contact_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(row_schema, ["properties", "observation_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(row_schema, ["properties", "downlink_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(row_schema, ["properties", "max_concurrent_contacts"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(row_schema, ["properties", "overlap_contact_pair_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(row_schema, ["properties", "activity_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(row_schema, ["properties", "effective_activity_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(row_schema, ["properties", "ignored_activity_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(row_schema, ["properties", "resource_flow_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(row_schema, ["properties", "left_rank", "type"]) == ["integer", "null"]
    assert get_in(row_schema, ["properties", "right_rank", "type"]) == ["integer", "null"]
    assert get_in(row_schema, ["properties", "rank_delta", "type"]) == ["integer", "null"]
    assert get_in(row_schema, ["properties", "value_delta", "type"]) == ["number", "null"]

    assert get_in(row_schema, ["properties", "selected_contact_ids", "items", "type"]) ==
             "string"

    assert get_in(row_schema, ["properties", "capacity_adjusted_throughput_mb", "type"]) ==
             "number"

    Enum.each(["throughput_completion_fraction", "completed_fraction"], fn field ->
      assert get_in(row_schema, ["properties", field]) == %{
               "type" => "number",
               "minimum" => 0.0,
               "maximum" => 1.0
             }
    end)

    Enum.each(
      [
        "eclipse_overlap_fraction",
        "planned_eclipse_overlap_fraction",
        "realized_eclipse_overlap_fraction"
      ],
      fn field ->
        assert get_in(row_schema, ["properties", field]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }
      end
    )

    assert get_in(row_schema, ["properties", "eclipse_overlap_s", "type"]) == "number"
    assert get_in(row_schema, ["properties", "planned_eclipse_overlap_s", "type"]) == "number"
    assert get_in(row_schema, ["properties", "realized_eclipse_overlap_s", "type"]) == "number"
    assert get_in(row_schema, ["properties", "lighting_condition", "type"]) == "string"
    assert get_in(row_schema, ["properties", "planned_lighting_condition", "type"]) == "string"
    assert get_in(row_schema, ["properties", "realized_lighting_condition", "type"]) == "string"

    assert get_in(row_schema, ["properties", "lighting_condition_match_status", "type"]) ==
             "string"

    assert get_in(row_schema, ["properties", "lighting_condition_detail", "type"]) == "string"
    assert get_in(row_schema, ["properties", "lighting_condition_model", "type"]) == "string"
    assert get_in(row_schema, ["properties", "lighting_detail_model", "type"]) == "string"

    assert get_in(row_schema, ["properties", "lighting_confidence", "type"]) == [
             "number",
             "string"
           ]

    assert get_in(row_schema, ["properties", "attitude_confidence"]) == %{
             "type" => "number",
             "minimum" => 0.0,
             "maximum" => 1.0
           }

    Enum.each(
      [
        "cloud_cover_fraction",
        "planned_cloud_cover_fraction",
        "realized_cloud_cover_fraction",
        "blur_score",
        "planned_blur_score",
        "realized_blur_score"
      ],
      fn field ->
        assert get_in(row_schema, ["properties", field]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }
      end
    )

    assert get_in(row_schema, ["properties", "scenario_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "planned_timeline_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "activity_count", "type"]) == "integer"

    assert get_in(row_schema, ["properties", "dependency_activity_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "exclusive_with_timeline_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "realized_activity_context", "type"]) == "object"

    assert get_in(row_schema, [
             "properties",
             "actual_data_rate_throughput_derivation",
             "type"
           ]) == "object"

    assert get_in(row_schema, ["properties", "realized_activity_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "source_protection_decision", "type"]) ==
             "object"

    assert get_in(row_schema, ["properties", "planned_protection_decision", "type"]) ==
             "string"

    assert get_in(row_schema, ["properties", "resource_flow_count", "type"]) == "integer"
    assert get_in(row_schema, ["properties", "peak_storage_overflow_mb", "type"]) == "number"
    assert get_in(row_schema, ["properties", "review_queue_key", "type"]) == "string"

    assert get_in(row_schema, [
             "properties",
             "approval_requirements",
             "items",
             "properties",
             "schema_contract",
             "const"
           ]) ==
             "approval_requirement.v1"

    assert get_in(row_schema, [
             "properties",
             "approval_rule_matches",
             "items",
             "properties",
             "rule_id",
             "pattern"
           ]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "first_resource_pressure_activity_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "first_resource_pressure_activity_type", "type"]) ==
             "string"

    assert get_in(row_schema, ["properties", "first_resource_pressure_kind", "type"]) == "string"

    assert get_in(row_schema, ["properties", "first_resource_pressure_starts_at_s", "type"]) ==
             "number"

    assert get_in(row_schema, ["properties", "peak_unused_downlink_capacity_mb", "type"]) ==
             "number"

    assert get_in(row_schema, ["properties", "projected_battery_overuse_wh", "type"]) == "number"

    assert get_in(row_schema, ["properties", "resource_trust_boundary_status", "type"]) ==
             "string"

    assert get_in(row_schema, ["properties", "storage_limited_downlinked_mb", "type"]) == "number"
    assert get_in(row_schema, ["properties", "unused_downlink_capacity_mb", "type"]) == "number"

    resource_projection_package =
      read_json!("study_results/operator_review_resource_projection_battery_handoff_v1.json")

    invalid_first_pressure_activity =
      put_in(
        resource_projection_package,
        ["rows", Access.at(0), "first_resource_pressure_activity_id"],
        "bad id"
      )

    assert {:error, first_pressure_activity_report} =
             Schema.validate_artifact(invalid_first_pressure_activity)

    assert Enum.any?(
             first_pressure_activity_report["errors"],
             &(&1["path"] == "$.rows[0].first_resource_pressure_activity_id")
           )

    invalid_storage_limited_downlink =
      put_in(
        resource_projection_package,
        ["rows", Access.at(0), "storage_limited_downlinked_mb"],
        "0.0"
      )

    assert {:error, storage_limited_downlink_report} =
             Schema.validate_artifact(invalid_storage_limited_downlink)

    assert Enum.any?(
             storage_limited_downlink_report["errors"],
             &(&1["path"] == "$.rows[0].storage_limited_downlinked_mb")
           )

    assert get_in(row_schema, ["properties", "branch_event_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(row_schema, ["properties", "branch_event_types", "items", "type"]) == "string"

    assert get_in(row_schema, [
             "properties",
             "branch_event_trust_boundary_status_counts",
             "additionalProperties",
             "type"
           ]) == "integer"

    assert get_in(row_schema, [
             "properties",
             "combined_source_branch_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    Enum.each(
      [
        "branch_image_quality_min_score",
        "branch_cloud_cover_max_fraction",
        "branch_blur_max_score"
      ],
      fn field ->
        assert get_in(row_schema, ["properties", field]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }
      end
    )

    assert get_in(row_schema, [
             "properties",
             "branch_image_quality_statuses",
             "items",
             "type"
           ]) == "string"

    assert get_in(row_schema, [
             "properties",
             "branch_image_quality_sources",
             "items",
             "type"
           ]) == "string"

    assert get_in(row_schema, ["properties", "spacecraft_id", "type"]) == "string"
    assert get_in(row_schema, ["properties", "projected_storage_margin", "type"]) == "number"
    assert get_in(row_schema, ["properties", "payload_available", "type"]) == "boolean"
    assert get_in(row_schema, ["properties", "warnings", "items", "type"]) == "string"
    assert get_in(row_schema, ["properties", "timeline_identity", "type"]) == "object"
    assert get_in(row_schema, ["properties", "required_authority", "type"]) == "string"
    assert get_in(row_schema, ["properties", "sla_s", "type"]) == "number"
    assert get_in(row_schema, ["properties", "source_timeline_identity", "type"]) == "object"
    assert get_in(row_schema, ["properties", "replacement_timeline_identity", "type"]) == "object"

    assert get_in(row_schema, [
             "properties",
             "source_timeline_identity",
             "properties",
             "timeline_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "source_activity_context",
             "properties",
             "activity_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "source_activity_context",
             "properties",
             "lighting_condition",
             "type"
           ]) == "string"

    assert get_in(row_schema, [
             "properties",
             "source_activity_context",
             "properties",
             "blur_score"
           ]) == %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0}

    assert get_in(row_schema, [
             "properties",
             "replacement_activity_context",
             "properties",
             "delta_v_3sigma_km_s",
             "items",
             "type"
           ]) == "number"

    assert get_in(row_schema, ["properties", "protection_category", "enum"]) == [
             "preserved_locked_or_approved",
             "preserved_executed",
             "changed_locked_or_approved",
             "changed_executed"
           ]

    assert get_in(row_schema, ["properties", "protection_decision", "enum"]) == [
             "preserved",
             "changed"
           ]

    assert get_in(schema, ["properties", "timeline_protection_count", "type"]) == "integer"
    assert get_in(schema, ["properties", "timeline_protection_count", "minimum"]) == 0
    assert get_in(schema, ["properties", "policy_escalation_count", "type"]) == "integer"
    assert get_in(schema, ["properties", "contention_review_count", "type"]) == "integer"
    assert get_in(schema, ["properties", "resource_projection_review_count", "type"]) == "integer"
    assert get_in(schema, ["properties", "command_window_count", "type"]) == "integer"
    assert get_in(schema, ["properties", "command_window_count", "minimum"]) == 0
    assert get_in(schema, ["properties", "station_calendar_review_count", "type"]) == "integer"
    assert get_in(schema, ["properties", "station_calendar_review_count", "minimum"]) == 0
    assert get_in(schema, ["properties", "link_capacity_review_count", "type"]) == "integer"
    assert get_in(schema, ["properties", "contact_suppression_count", "type"]) == "integer"
    assert get_in(schema, ["properties", "resource_suppression_count", "type"]) == "integer"
    assert get_in(schema, ["properties", "timeline_diff_count", "type"]) == "integer"
    assert get_in(schema, ["properties", "maneuver_review_count", "type"]) == "integer"
    assert get_in(schema, ["properties", "tradeoff_count", "type"]) == "integer"
    assert get_in(schema, ["properties", "ranking_comparison_count", "type"]) == "integer"

    summary_counter_fields = [
      "candidate_diff_review_count",
      "constraint_review_count",
      "contact_allocation_capacity_pack_review_count",
      "contact_allocation_review_count",
      "contact_intent_review_count",
      "execution_review_count",
      "freshness_review_count",
      "objective_satisfaction_review_count",
      "objective_tradeoff_review_count",
      "operational_timeline_count",
      "pareto_frontier_count",
      "provider_counteroffer_review_count",
      "quality_gate_review_count",
      "refresh_budget_review_count",
      "schema_validation_review_count",
      "score_term_review_count"
    ]

    Enum.each(summary_counter_fields, fn field ->
      assert get_in(schema, ["properties", field]) == %{
               "type" => "integer",
               "minimum" => 0
             }
    end)

    package = read_json!("study_results/operator_review_resource_pressure_v1.json")
    invalid_package = Map.put(package, "candidate_diff_review_count", -1)

    assert {:error, invalid_count_report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             invalid_count_report["errors"],
             &(&1["path"] == "$.candidate_diff_review_count")
           )
  end

  test "validates checked-in operator review package example" do
    package = read_json!("study_results/operator_review_package_v1.json")

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert %{
             "source_artifact_type" => "timeline_feedback_report.v1",
             "review_count" => 8,
             "approval_requirement_count" => 1,
             "contention_review_count" => 0,
             "policy_escalation_count" => 1,
             "contact_suppression_count" => 1,
             "resource_projection_review_count" => 1,
             "resource_suppression_count" => 1,
             "command_window_count" => 0,
             "station_calendar_review_count" => 0,
             "link_capacity_review_count" => 1,
             "timeline_diff_count" => 1,
             "maneuver_review_count" => 0,
             "realized_feedback_count" => 1,
             "rows" => [
               %{"review_type" => "approval_requirement"},
               %{
                 "review_type" => "policy_escalation",
                 "required_authority" => "contact_schedule_authority"
               },
               %{
                 "review_type" => "realized_feedback",
                 "activity_id" => "downlink_equator",
                 "throughput_delta_mb" => -48.0
               },
               %{
                 "review_type" => "resource_suppression",
                 "activity_id" => "leo_1_observe_target_a_1",
                 "source_resource_suppression" => %{
                   "suppressed_reason" => "payload_unavailable"
                 }
               },
               %{
                 "review_type" => "resource_projection_review",
                 "spacecraft_id" => "leo_1",
                 "projected_storage_margin" => 0.75,
                 "source_resource_projection" => %{"spacecraft_id" => "leo_1"}
               },
               %{
                 "review_type" => "contact_suppression",
                 "activity_id" => "leo_1_downlink_equator_prime_1",
                 "source_contact_suppression" => %{
                   "suppressed_reason" => "ground_station_unavailable"
                 }
               },
               %{
                 "review_type" => "link_capacity_review",
                 "ground_station_id" => "equator_prime",
                 "source_link_capacity" => %{"ground_station_id" => "equator_prime"}
               },
               %{
                 "review_type" => "timeline_diff_review",
                 "timeline_id" => "timeline:downlink_equator",
                 "changed_fields" => ["starts_at_s", "ends_at_s", "approval_status"],
                 "source_timeline_diff" => %{
                   "requires_operator_review" => true
                 }
               }
             ]
           } = package

    assert package["rows"]
           |> Enum.find(&(&1["review_type"] == "link_capacity_review"))
           |> Map.fetch!("selected_estimated_throughput_mb") == 0.0

    link_capacity_review_index =
      Enum.find_index(package["rows"], &(&1["review_type"] == "link_capacity_review"))

    invalid_link_capacity_review_capacity_range =
      package
      |> put_in(["rows", Access.at(link_capacity_review_index), "capacity_fraction_min"], -0.1)
      |> put_in(["rows", Access.at(link_capacity_review_index), "capacity_fraction_max"], 1.2)

    assert {:error, link_capacity_review_capacity_range_report} =
             Schema.validate_artifact(invalid_link_capacity_review_capacity_range)

    assert Enum.any?(
             link_capacity_review_capacity_range_report["errors"],
             &(&1["path"] == "$.rows[#{link_capacity_review_index}].capacity_fraction_min")
           )

    assert Enum.any?(
             link_capacity_review_capacity_range_report["errors"],
             &(&1["path"] == "$.rows[#{link_capacity_review_index}].capacity_fraction_max")
           )

    invalid_dependency_id =
      put_in(
        package,
        ["rows", Access.at(2), "dependency_activity_ids"],
        ["dependency with spaces"]
      )

    assert {:error, dependency_id_report} = Schema.validate_artifact(invalid_dependency_id)

    assert Enum.any?(
             dependency_id_report["errors"],
             &(&1["path"] == "$.rows[2].dependency_activity_ids[0]")
           )

    invalid_timeline_link =
      put_in(package, ["rows", Access.at(0), "timeline_link"], %{
        "source_timeline_id" => "timeline with spaces"
      })

    assert {:error, timeline_link_report} = Schema.validate_artifact(invalid_timeline_link)

    assert Enum.any?(
             timeline_link_report["errors"],
             &(&1["path"] == "$.rows[0].timeline_link.source_timeline_id")
           )

    invalid_source_timeline_id =
      put_in(package, ["rows", Access.at(0), "source_timeline_id"], "timeline with spaces")

    assert {:error, source_timeline_id_report} =
             Schema.validate_artifact(invalid_source_timeline_id)

    assert Enum.any?(
             source_timeline_id_report["errors"],
             &(&1["path"] == "$.rows[0].source_timeline_id")
           )

    invalid_timeline_protection =
      put_in(package, ["rows", Access.at(0), "source_timeline_protection"], %{
        "changed_executed_count" => -1
      })

    assert {:error, timeline_protection_report} =
             Schema.validate_artifact(invalid_timeline_protection)

    assert Enum.any?(
             timeline_protection_report["errors"],
             &(&1["path"] == "$.rows[0].source_timeline_protection.changed_executed_count")
           )

    invalid_source_window =
      package
      |> put_in(["rows", Access.at(2), "source_window_id"], "window_1")
      |> put_in(["rows", Access.at(2), "source_window"], %{"id" => "window with spaces"})

    assert {:error, source_window_report} = Schema.validate_artifact(invalid_source_window)

    assert Enum.any?(
             source_window_report["errors"],
             &(&1["path"] == "$.rows[2].source_window.id")
           )

    invalid_source_window_lineage =
      package
      |> put_in(["rows", Access.at(2), "source_window_id"], "window_1")
      |> put_in(["rows", Access.at(2), "source_window_lineage"], %{
        "candidate_activity_id" => "activity with spaces",
        "source_window_id" => "window_1",
        "source_window_type" => "downlink",
        "scenario_id" => "leo_1"
      })

    assert {:error, source_window_lineage_report} =
             Schema.validate_artifact(invalid_source_window_lineage)

    assert Enum.any?(
             source_window_lineage_report["errors"],
             &(&1["path"] == "$.rows[2].source_window_lineage.candidate_activity_id")
           )

    invalid_battery_handoff =
      package
      |> put_in(["rows", Access.at(4), "total_battery_energy_consumed_wh"], "twenty")
      |> put_in(["rows", Access.at(4), "source_resource_projection"], %{
        "spacecraft_id" => "leo_1",
        "total_battery_energy_generated_wh" => "five"
      })

    assert {:error, battery_handoff_report} =
             Schema.validate_artifact(invalid_battery_handoff)

    assert Enum.any?(
             battery_handoff_report["errors"],
             &(&1["path"] == "$.rows[4].total_battery_energy_consumed_wh")
           )

    assert Enum.any?(
             battery_handoff_report["errors"],
             &(&1["path"] ==
                 "$.rows[4].source_resource_projection.total_battery_energy_generated_wh")
           )

    invalid_source_delta =
      put_in(package, ["rows", Access.at(0), "source_delta"], %{
        "activity_id" => "activity with spaces",
        "activity_type" => "downlink",
        "status" => "changed",
        "repair_action" => "moved"
      })

    assert {:error, source_delta_report} = Schema.validate_artifact(invalid_source_delta)

    assert Enum.any?(
             source_delta_report["errors"],
             &(&1["path"] == "$.rows[0].source_delta.activity_id")
           )

    invalid_source_requirement =
      put_in(package, ["rows", Access.at(0), "source_requirement", "activity_id"], "bad id")

    assert {:error, source_requirement_report} =
             Schema.validate_artifact(invalid_source_requirement)

    assert Enum.any?(
             source_requirement_report["errors"],
             &(&1["path"] == "$.rows[0].source_requirement.activity_id")
           )

    invalid_source_policy_decision =
      put_in(
        package,
        ["rows", Access.at(1), "source_policy_decision", "classification"],
        "maybe"
      )

    assert {:error, source_policy_decision_report} =
             Schema.validate_artifact(invalid_source_policy_decision)

    assert Enum.any?(
             source_policy_decision_report["errors"],
             &(&1["path"] == "$.rows[1].source_policy_decision.classification")
           )

    invalid_source_policy_escalation =
      put_in(
        package,
        ["rows", Access.at(1), "source_policy_escalation", "rule_id"],
        "rule with spaces"
      )

    assert {:error, source_policy_escalation_report} =
             Schema.validate_artifact(invalid_source_policy_escalation)

    assert Enum.any?(
             source_policy_escalation_report["errors"],
             &(&1["path"] == "$.rows[1].source_policy_escalation.rule_id")
           )

    invalid_source_resource_suppression =
      put_in(
        package,
        ["rows", Access.at(3), "source_resource_suppression", "id"],
        "resource suppression with spaces"
      )

    assert {:error, source_resource_suppression_report} =
             Schema.validate_artifact(invalid_source_resource_suppression)

    assert Enum.any?(
             source_resource_suppression_report["errors"],
             &(&1["path"] == "$.rows[3].source_resource_suppression.id")
           )

    invalid_source_contact_suppression =
      put_in(
        package,
        ["rows", Access.at(5), "source_contact_suppression", "source_window_id"],
        "window with spaces"
      )

    assert {:error, source_contact_suppression_report} =
             Schema.validate_artifact(invalid_source_contact_suppression)

    assert Enum.any?(
             source_contact_suppression_report["errors"],
             &(&1["path"] == "$.rows[5].source_contact_suppression.source_window_id")
           )

    invalid_source_resource_projection =
      put_in(
        package,
        ["rows", Access.at(4), "source_resource_projection", "spacecraft_id"],
        "spacecraft with spaces"
      )

    assert {:error, source_resource_projection_report} =
             Schema.validate_artifact(invalid_source_resource_projection)

    assert Enum.any?(
             source_resource_projection_report["errors"],
             &(&1["path"] == "$.rows[4].source_resource_projection.spacecraft_id")
           )

    invalid_source_link_capacity =
      put_in(
        package,
        ["rows", Access.at(6), "source_link_capacity", "ground_station_id"],
        "station with spaces"
      )

    assert {:error, source_link_capacity_report} =
             Schema.validate_artifact(invalid_source_link_capacity)

    assert Enum.any?(
             source_link_capacity_report["errors"],
             &(&1["path"] == "$.rows[6].source_link_capacity.ground_station_id")
           )

    invalid_source_timeline_diff =
      put_in(
        package,
        ["rows", Access.at(7), "source_timeline_diff", "timeline_id"],
        "timeline with spaces"
      )

    assert {:error, source_timeline_diff_report} =
             Schema.validate_artifact(invalid_source_timeline_diff)

    assert Enum.any?(
             source_timeline_diff_report["errors"],
             &(&1["path"] == "$.rows[7].source_timeline_diff.timeline_id")
           )

    command_window_row =
      read_json!("study_results/command_window_report_v1.json")
      |> Map.fetch!("rows")
      |> List.first()

    package_with_command_window_source =
      put_in(package, ["rows", Access.at(0), "source_command_window"], command_window_row)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package_with_command_window_source)

    invalid_source_command_window =
      put_in(
        package_with_command_window_source,
        ["rows", Access.at(0), "source_command_window", "ground_station_id"],
        "station with spaces"
      )

    assert {:error, source_command_window_report} =
             Schema.validate_artifact(invalid_source_command_window)

    assert Enum.any?(
             source_command_window_report["errors"],
             &(&1["path"] == "$.rows[0].source_command_window.ground_station_id")
           )

    maneuver_review_row =
      read_json!("study_results/maneuver_review_report_v1.json")
      |> Map.fetch!("rows")
      |> List.first()

    package_with_maneuver_review_source =
      put_in(package, ["rows", Access.at(0), "source_maneuver_review"], maneuver_review_row)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package_with_maneuver_review_source)

    invalid_source_maneuver_review =
      put_in(
        package_with_maneuver_review_source,
        ["rows", Access.at(0), "source_maneuver_review", "maneuver_id"],
        "maneuver with spaces"
      )

    assert {:error, source_maneuver_review_report} =
             Schema.validate_artifact(invalid_source_maneuver_review)

    assert Enum.any?(
             source_maneuver_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_maneuver_review.maneuver_id")
           )

    ranking_comparison_row =
      read_json!("study_results/ranking_comparison_report_v1.json")
      |> Map.fetch!("rows")
      |> List.first()

    package_with_ranking_comparison_source =
      put_in(
        package,
        ["rows", Access.at(0), "source_ranking_comparison"],
        ranking_comparison_row
      )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package_with_ranking_comparison_source)

    invalid_source_ranking_comparison =
      put_in(
        package_with_ranking_comparison_source,
        ["rows", Access.at(0), "source_ranking_comparison", "scenario_id"],
        "scenario with spaces"
      )

    assert {:error, source_ranking_comparison_report} =
             Schema.validate_artifact(invalid_source_ranking_comparison)

    assert Enum.any?(
             source_ranking_comparison_report["errors"],
             &(&1["path"] == "$.rows[0].source_ranking_comparison.scenario_id")
           )

    contention_group =
      read_json!("study_results/contact_contention_report_v1.json")
      |> Map.fetch!("conflict_groups")
      |> List.first()

    package_with_contention_group_source =
      put_in(package, ["rows", Access.at(0), "source_contention_group"], contention_group)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package_with_contention_group_source)

    invalid_source_contention_group =
      put_in(
        package_with_contention_group_source,
        ["rows", Access.at(0), "source_contention_group", "ground_station_id"],
        "station with spaces"
      )

    assert {:error, source_contention_group_report} =
             Schema.validate_artifact(invalid_source_contention_group)

    assert Enum.any?(
             source_contention_group_report["errors"],
             &(&1["path"] == "$.rows[0].source_contention_group.ground_station_id")
           )

    station_calendar_contact =
      read_json!("study_results/station_calendar_report_v1.json")
      |> Map.fetch!("affected_contacts")
      |> List.first()

    package_with_station_calendar_source =
      put_in(
        package,
        ["rows", Access.at(0), "source_station_calendar_review"],
        station_calendar_contact
      )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package_with_station_calendar_source)

    invalid_source_station_calendar_review =
      put_in(
        package_with_station_calendar_source,
        ["rows", Access.at(0), "source_station_calendar_review", "ground_station_id"],
        "station with spaces"
      )

    assert {:error, source_station_calendar_review_report} =
             Schema.validate_artifact(invalid_source_station_calendar_review)

    assert Enum.any?(
             source_station_calendar_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_station_calendar_review.ground_station_id")
           )

    invalid_required_scalar_count = Map.put(package, "review_count", 8.0)

    assert {:error, required_scalar_count_report} =
             Schema.validate_artifact(invalid_required_scalar_count)

    assert Enum.any?(
             required_scalar_count_report["errors"],
             &(&1["path"] == "$.review_count")
           )

    invalid_optional_scalar_count = Map.put(package, "command_window_count", 1.0)

    assert {:error, optional_scalar_count_report} =
             Schema.validate_artifact(invalid_optional_scalar_count)

    assert Enum.any?(
             optional_scalar_count_report["errors"],
             &(&1["path"] == "$.command_window_count")
           )

    invalid_negative_scalar_count = Map.put(package, "link_capacity_review_count", -1)

    assert {:error, negative_scalar_count_report} =
             Schema.validate_artifact(invalid_negative_scalar_count)

    assert Enum.any?(
             negative_scalar_count_report["errors"],
             &(&1["path"] == "$.link_capacity_review_count")
           )

    invalid_row_contact_count =
      put_in(package, ["rows", Access.at(6), "contact_count"], 1.0)

    assert {:error, row_contact_count_report} =
             Schema.validate_artifact(invalid_row_contact_count)

    assert Enum.any?(
             row_contact_count_report["errors"],
             &(&1["path"] == "$.rows[6].contact_count")
           )

    invalid_row_observation_count =
      put_in(package, ["rows", Access.at(4), "observation_count"], -1)

    assert {:error, row_observation_count_report} =
             Schema.validate_artifact(invalid_row_observation_count)

    assert Enum.any?(
             row_observation_count_report["errors"],
             &(&1["path"] == "$.rows[4].observation_count")
           )

    invalid_row_overlap_count =
      package
      |> put_in(["rows", Access.at(0), "max_concurrent_contacts"], 1.0)
      |> put_in(["rows", Access.at(0), "overlap_contact_pair_count"], -1)

    assert {:error, row_overlap_count_report} =
             Schema.validate_artifact(invalid_row_overlap_count)

    assert Enum.any?(
             row_overlap_count_report["errors"],
             &(&1["path"] == "$.rows[0].max_concurrent_contacts")
           )

    assert Enum.any?(
             row_overlap_count_report["errors"],
             &(&1["path"] == "$.rows[0].overlap_contact_pair_count")
           )

    invalid_row_activity_count =
      put_in(package, ["rows", Access.at(4), "effective_activity_count"], 1.0)

    assert {:error, row_activity_count_report} =
             Schema.validate_artifact(invalid_row_activity_count)

    assert Enum.any?(
             row_activity_count_report["errors"],
             &(&1["path"] == "$.rows[4].effective_activity_count")
           )

    invalid_row_resource_flow_count =
      put_in(package, ["rows", Access.at(4), "resource_flow_count"], -1)

    assert {:error, row_resource_flow_count_report} =
             Schema.validate_artifact(invalid_row_resource_flow_count)

    assert Enum.any?(
             row_resource_flow_count_report["errors"],
             &(&1["path"] == "$.rows[4].resource_flow_count")
           )

    invalid_source_feedback =
      put_in(
        package,
        ["rows", Access.at(2), "source_feedback", "activity_id"],
        "activity with spaces"
      )

    assert {:error, source_feedback_report} = Schema.validate_artifact(invalid_source_feedback)

    assert Enum.any?(
             source_feedback_report["errors"],
             &(&1["path"] == "$.rows[2].source_feedback.activity_id")
           )

    invalid_source_feedback_factor =
      put_in(package, ["rows", Access.at(2), "source_feedback", "contact_success_factor"], 1.5)

    assert {:error, source_feedback_factor_report} =
             Schema.validate_artifact(invalid_source_feedback_factor)

    assert Enum.any?(
             source_feedback_factor_report["errors"],
             &(&1["path"] == "$.rows[2].source_feedback.contact_success_factor")
           )

    invalid_source_feedback_quality =
      put_in(package, ["rows", Access.at(2), "source_feedback", "blur_score"], 1.5)

    assert {:error, source_feedback_quality_report} =
             Schema.validate_artifact(invalid_source_feedback_quality)

    assert Enum.any?(
             source_feedback_quality_report["errors"],
             &(&1["path"] == "$.rows[2].source_feedback.blur_score")
           )

    invalid_row_quality_fraction =
      put_in(package, ["rows", Access.at(2), "realized_cloud_cover_fraction"], 1.2)

    assert {:error, row_quality_fraction_report} =
             Schema.validate_artifact(invalid_row_quality_fraction)

    assert Enum.any?(
             row_quality_fraction_report["errors"],
             &(&1["path"] == "$.rows[2].realized_cloud_cover_fraction")
           )

    invalid_row_image_quality_score =
      package
      |> put_in(["rows", Access.at(2), "image_quality_score"], 1.2)
      |> put_in(["rows", Access.at(2), "planned_image_quality_score"], -0.1)

    assert {:error, row_image_quality_score_report} =
             Schema.validate_artifact(invalid_row_image_quality_score)

    assert Enum.any?(
             row_image_quality_score_report["errors"],
             &(&1["path"] == "$.rows[2].image_quality_score")
           )

    assert Enum.any?(
             row_image_quality_score_report["errors"],
             &(&1["path"] == "$.rows[2].planned_image_quality_score")
           )

    invalid_row_observation_quality_handoff =
      package
      |> put_in(["rows", Access.at(2), "cloud_cover_fraction_delta"], "more")
      |> put_in(["rows", Access.at(2), "blur_score_delta"], "blurrier")
      |> put_in(["rows", Access.at(2), "planned_image_quality_status"], 42)
      |> put_in(["rows", Access.at(2), "image_quality_source"], 42)

    assert {:error, row_observation_quality_handoff_report} =
             Schema.validate_artifact(invalid_row_observation_quality_handoff)

    assert Enum.any?(
             row_observation_quality_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].cloud_cover_fraction_delta")
           )

    assert Enum.any?(
             row_observation_quality_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].blur_score_delta")
           )

    assert Enum.any?(
             row_observation_quality_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].planned_image_quality_status")
           )

    assert Enum.any?(
             row_observation_quality_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].image_quality_source")
           )

    invalid_row_feedback_maneuver_handoff =
      package
      |> put_in(["rows", Access.at(2), "feedback_weight"], -0.1)
      |> put_in(["rows", Access.at(2), "feedback_weight_source"], 42)
      |> put_in(["rows", Access.at(2), "maneuver_success"], "yes")
      |> put_in(["rows", Access.at(2), "maneuver_result"], 42)
      |> put_in(["rows", Access.at(2), "maneuver_success_factor"], 1.2)
      |> put_in(["rows", Access.at(2), "maneuver_success_factor_source"], 42)

    assert {:error, row_feedback_maneuver_handoff_report} =
             Schema.validate_artifact(invalid_row_feedback_maneuver_handoff)

    for field <- [
          "feedback_weight",
          "feedback_weight_source",
          "maneuver_success",
          "maneuver_result",
          "maneuver_success_factor",
          "maneuver_success_factor_source"
        ] do
      assert Enum.any?(
               row_feedback_maneuver_handoff_report["errors"],
               &(&1["path"] == "$.rows[2].#{field}")
             )
    end

    invalid_row_completion_fraction =
      package
      |> put_in(["rows", Access.at(2), "completed_fraction"], 1.2)
      |> put_in(["rows", Access.at(2), "throughput_completion_fraction"], -0.1)

    assert {:error, row_completion_fraction_report} =
             Schema.validate_artifact(invalid_row_completion_fraction)

    assert Enum.any?(
             row_completion_fraction_report["errors"],
             &(&1["path"] == "$.rows[2].completed_fraction")
           )

    assert Enum.any?(
             row_completion_fraction_report["errors"],
             &(&1["path"] == "$.rows[2].throughput_completion_fraction")
           )

    invalid_row_eclipse_overlap_fraction =
      package
      |> put_in(["rows", Access.at(2), "eclipse_overlap_fraction"], 1.2)
      |> put_in(["rows", Access.at(2), "planned_eclipse_overlap_fraction"], -0.1)

    assert {:error, row_eclipse_overlap_fraction_report} =
             Schema.validate_artifact(invalid_row_eclipse_overlap_fraction)

    assert Enum.any?(
             row_eclipse_overlap_fraction_report["errors"],
             &(&1["path"] == "$.rows[2].eclipse_overlap_fraction")
           )

    assert Enum.any?(
             row_eclipse_overlap_fraction_report["errors"],
             &(&1["path"] == "$.rows[2].planned_eclipse_overlap_fraction")
           )

    invalid_row_eclipse_lighting_handoff =
      package
      |> put_in(["rows", Access.at(2), "eclipse_overlap_s"], "long")
      |> put_in(["rows", Access.at(2), "planned_lighting_condition"], 42)
      |> put_in(["rows", Access.at(2), "lighting_confidence"], %{"label" => "high"})

    assert {:error, row_eclipse_lighting_handoff_report} =
             Schema.validate_artifact(invalid_row_eclipse_lighting_handoff)

    assert Enum.any?(
             row_eclipse_lighting_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].eclipse_overlap_s")
           )

    assert Enum.any?(
             row_eclipse_lighting_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].planned_lighting_condition")
           )

    assert Enum.any?(
             row_eclipse_lighting_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].lighting_confidence")
           )

    invalid_row_link_error_rate =
      package
      |> put_in(["rows", Access.at(2), "bit_error_rate"], 1.2)
      |> put_in(["rows", Access.at(2), "realized_packet_loss_rate"], -0.1)

    assert {:error, row_link_error_rate_report} =
             Schema.validate_artifact(invalid_row_link_error_rate)

    assert Enum.any?(
             row_link_error_rate_report["errors"],
             &(&1["path"] == "$.rows[2].bit_error_rate")
           )

    assert Enum.any?(
             row_link_error_rate_report["errors"],
             &(&1["path"] == "$.rows[2].realized_packet_loss_rate")
           )

    invalid_row_link_handoff =
      package
      |> put_in(["rows", Access.at(2), "frequency_band"], 42)
      |> put_in(["rows", Access.at(2), "planned_link_margin_db"], "cold")
      |> put_in(["rows", Access.at(2), "realized_carrier_lock"], "lost")

    assert {:error, row_link_handoff_report} =
             Schema.validate_artifact(invalid_row_link_handoff)

    assert Enum.any?(
             row_link_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].frequency_band")
           )

    assert Enum.any?(
             row_link_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].planned_link_margin_db")
           )

    assert Enum.any?(
             row_link_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].realized_carrier_lock")
           )

    invalid_row_attitude_confidence =
      put_in(package, ["rows", Access.at(2), "attitude_confidence"], 1.2)

    assert {:error, row_attitude_confidence_report} =
             Schema.validate_artifact(invalid_row_attitude_confidence)

    assert Enum.any?(
             row_attitude_confidence_report["errors"],
             &(&1["path"] == "$.rows[2].attitude_confidence")
           )

    invalid_row_thermal_handoff =
      package
      |> put_in(["rows", Access.at(2), "thermal_zone_id"], "payload deck")
      |> put_in(["rows", Access.at(2), "thermal_confidence"], 1.2)

    assert {:error, row_thermal_handoff_report} =
             Schema.validate_artifact(invalid_row_thermal_handoff)

    assert Enum.any?(
             row_thermal_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].thermal_zone_id")
           )

    assert Enum.any?(
             row_thermal_handoff_report["errors"],
             &(&1["path"] == "$.rows[2].thermal_confidence")
           )

    invalid_review_counts =
      put_in(package, ["required_operator_action_counts", "review_contact_variance"], 99)

    assert {:error, review_counts_report} = Schema.validate_artifact(invalid_review_counts)

    assert Enum.any?(
             review_counts_report["errors"],
             &(&1["path"] == "$.required_operator_action_counts")
           )

    invalid_negative_review_counts =
      put_in(package, ["review_type_counts", "realized_feedback"], -1)

    assert {:error, negative_review_counts_report} =
             Schema.validate_artifact(invalid_negative_review_counts)

    assert Enum.any?(
             negative_review_counts_report["errors"],
             &(&1["path"] == "$.review_type_counts.realized_feedback")
           )

    for {field, key, counts} <- [
          {"calendar_entry_trust_boundary_status_counts", "declared", %{"declared" => -1}},
          {"station_reservation_match_status_counts", "overlap", %{"overlap" => -1}},
          {"station_reservation_expiration_status_counts", "declared", %{"declared" => -1}},
          {"resource_blocking_dimension_counts", "antenna", %{"antenna" => -1}},
          {"gate_status_counts", "review_required", %{"review_required" => -1}},
          {"gate_classification_counts", "review_only", %{"review_only" => -1}},
          {"required_capacity_fraction_source_counts", "capacity_model",
           %{"capacity_model" => -1}},
          {"provider_reservation_request_status_counts", "review_required",
           %{"review_required" => -1}},
          {"reduced_capacity_pack_status_counts", "capacity_limited",
           %{"capacity_limited" => -1}},
          {"station_pressure_contact_counts_by_availability", "reserved", %{"reserved" => -1}}
        ] do
      invalid_lifted_summary_counts = Map.put(package, field, counts)

      assert {:error, lifted_summary_counts_report} =
               Schema.validate_artifact(invalid_lifted_summary_counts)

      assert Enum.any?(
               lifted_summary_counts_report["errors"],
               &(&1["path"] == "$.#{field}.#{key}")
             )
    end

    invalid_resource_blocked_ids =
      Map.put(package, "resource_blocked_contact_ids_by_blocking_dimension", %{
        "antenna" => ["bad id"]
      })

    assert {:error, resource_blocked_ids_report} =
             Schema.validate_artifact(invalid_resource_blocked_ids)

    assert Enum.any?(
             resource_blocked_ids_report["errors"],
             &(&1["path"] ==
                 "$.resource_blocked_contact_ids_by_blocking_dimension.antenna[0]")
           )

    invalid_station_pressure_ids =
      Map.put(package, "station_pressure_contact_ids_by_availability", %{
        "reserved" => ["bad id"]
      })

    assert {:error, station_pressure_ids_report} =
             Schema.validate_artifact(invalid_station_pressure_ids)

    assert Enum.any?(
             station_pressure_ids_report["errors"],
             &(&1["path"] == "$.station_pressure_contact_ids_by_availability.reserved[0]")
           )

    invalid_station_reservation_routing_ids =
      Map.put(package, "station_reservation_ids_by_match_status", %{
        "overlap" => ["bad id"]
      })

    assert {:error, station_reservation_routing_ids_report} =
             Schema.validate_artifact(invalid_station_reservation_routing_ids)

    assert Enum.any?(
             station_reservation_routing_ids_report["errors"],
             &(&1["path"] == "$.station_reservation_ids_by_match_status.overlap[0]")
           )

    invalid_quality_gate_count =
      Map.put(package, "gate_count", -1)

    assert {:error, quality_gate_count_report} =
             Schema.validate_artifact(invalid_quality_gate_count)

    assert Enum.any?(
             quality_gate_count_report["errors"],
             &(&1["path"] == "$.gate_count")
           )

    invalid_quality_gate_ids =
      Map.put(package, "review_required_gate_ids", ["bad id"])

    assert {:error, quality_gate_ids_report} =
             Schema.validate_artifact(invalid_quality_gate_ids)

    assert Enum.any?(
             quality_gate_ids_report["errors"],
             &(&1["path"] == "$.review_required_gate_ids[0]")
           )

    invalid_quality_gate_routing_ids =
      Map.put(package, "quality_gate_row_ids_by_status", %{
        "review_required" => ["bad id"]
      })

    assert {:error, quality_gate_routing_ids_report} =
             Schema.validate_artifact(invalid_quality_gate_routing_ids)

    assert Enum.any?(
             quality_gate_routing_ids_report["errors"],
             &(&1["path"] == "$.quality_gate_row_ids_by_status.review_required[0]")
           )

    invalid_capacity_pack_group_ids =
      Map.put(package, "capacity_pack_group_ids", ["bad id"])

    assert {:error, capacity_pack_group_ids_report} =
             Schema.validate_artifact(invalid_capacity_pack_group_ids)

    assert Enum.any?(
             capacity_pack_group_ids_report["errors"],
             &(&1["path"] == "$.capacity_pack_group_ids[0]")
           )

    invalid_capacity_pack_group_ids_by_status =
      Map.put(package, "capacity_pack_group_ids_by_status", %{
        "capacity_limited" => ["bad id"]
      })

    assert {:error, capacity_pack_group_ids_by_status_report} =
             Schema.validate_artifact(invalid_capacity_pack_group_ids_by_status)

    assert Enum.any?(
             capacity_pack_group_ids_by_status_report["errors"],
             &(&1["path"] == "$.capacity_pack_group_ids_by_status.capacity_limited[0]")
           )

    invalid_required_capacity_source_ids =
      Map.put(package, "required_capacity_fraction_contact_ids_by_source", %{
        "capacity_model" => ["bad id"]
      })

    assert {:error, required_capacity_source_ids_report} =
             Schema.validate_artifact(invalid_required_capacity_source_ids)

    assert Enum.any?(
             required_capacity_source_ids_report["errors"],
             &(&1["path"] ==
                 "$.required_capacity_fraction_contact_ids_by_source.capacity_model[0]")
           )

    invalid_provider_reservation_count =
      Map.put(package, "provider_reservation_request_contact_count", -1)

    assert {:error, provider_reservation_count_report} =
             Schema.validate_artifact(invalid_provider_reservation_count)

    assert Enum.any?(
             provider_reservation_count_report["errors"],
             &(&1["path"] == "$.provider_reservation_request_contact_count")
           )

    invalid_provider_reservation_ids =
      Map.put(package, "provider_reservation_request_contact_ids", ["bad id"])

    assert {:error, provider_reservation_ids_report} =
             Schema.validate_artifact(invalid_provider_reservation_ids)

    assert Enum.any?(
             provider_reservation_ids_report["errors"],
             &(&1["path"] == "$.provider_reservation_request_contact_ids[0]")
           )

    invalid_provider_reservation_routing_ids =
      Map.put(package, "provider_reservation_request_ids_by_match_status", %{
        "matched" => ["bad id"]
      })

    assert {:error, provider_reservation_routing_ids_report} =
             Schema.validate_artifact(invalid_provider_reservation_routing_ids)

    assert Enum.any?(
             provider_reservation_routing_ids_report["errors"],
             &(&1["path"] == "$.provider_reservation_request_ids_by_match_status.matched[0]")
           )

    invalid_provider_reservation_direction_station_ids =
      Map.put(
        package,
        "provider_reservation_request_contact_ids_by_direction_and_ground_station_id",
        %{
          "downlink" => %{"equator_prime" => ["bad id"]}
        }
      )

    assert {:error, provider_reservation_direction_station_ids_report} =
             Schema.validate_artifact(invalid_provider_reservation_direction_station_ids)

    assert Enum.any?(
             provider_reservation_direction_station_ids_report["errors"],
             &(&1["path"] ==
                 "$.provider_reservation_request_contact_ids_by_direction_and_ground_station_id.downlink.equator_prime[0]")
           )

    invalid_capacity_pack_demand =
      Map.put(package, "capacity_pack_required_capacity_fraction", -1.0)

    assert {:error, capacity_pack_demand_report} =
             Schema.validate_artifact(invalid_capacity_pack_demand)

    assert Enum.any?(
             capacity_pack_demand_report["errors"],
             &(&1["path"] == "$.capacity_pack_required_capacity_fraction")
           )

    invalid_capacity_pack_demand_map =
      Map.put(package, "capacity_pack_required_capacity_fraction_by_status", %{
        "selected_by_reduced_station_capacity_pack" => -1.0
      })

    assert {:error, capacity_pack_demand_map_report} =
             Schema.validate_artifact(invalid_capacity_pack_demand_map)

    assert Enum.any?(
             capacity_pack_demand_map_report["errors"],
             &(&1["path"] ==
                 "$.capacity_pack_required_capacity_fraction_by_status.selected_by_reduced_station_capacity_pack")
           )

    invalid_capacity_pack_contact_ids =
      Map.put(package, "capacity_pack_contact_ids_by_status", %{
        "selected_by_reduced_station_capacity_pack" => ["bad id"]
      })

    assert {:error, capacity_pack_contact_ids_report} =
             Schema.validate_artifact(invalid_capacity_pack_contact_ids)

    assert Enum.any?(
             capacity_pack_contact_ids_report["errors"],
             &(&1["path"] ==
                 "$.capacity_pack_contact_ids_by_status.selected_by_reduced_station_capacity_pack[0]")
           )

    invalid_capacity_pack_station_contact_ids =
      Map.put(package, "capacity_pack_selected_contact_ids_by_ground_station_id", %{
        "gs_capacity_pack" => ["bad id"]
      })

    assert {:error, capacity_pack_station_contact_ids_report} =
             Schema.validate_artifact(invalid_capacity_pack_station_contact_ids)

    assert Enum.any?(
             capacity_pack_station_contact_ids_report["errors"],
             &(&1["path"] ==
                 "$.capacity_pack_selected_contact_ids_by_ground_station_id.gs_capacity_pack[0]")
           )

    invalid_reduced_capacity_packed_ids =
      Map.put(package, "reduced_capacity_packed_contact_ids", ["bad id"])

    assert {:error, reduced_capacity_packed_ids_report} =
             Schema.validate_artifact(invalid_reduced_capacity_packed_ids)

    assert Enum.any?(
             reduced_capacity_packed_ids_report["errors"],
             &(&1["path"] == "$.reduced_capacity_packed_contact_ids[0]")
           )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
