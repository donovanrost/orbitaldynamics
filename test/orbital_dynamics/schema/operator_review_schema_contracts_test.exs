defmodule OrbitalDynamics.Schema.OperatorReviewSchemaContractsTest do
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

    assert get_in(schema, [
             "properties",
             "station_pressure_contact_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, [
             "properties",
             "station_pressure_contact_ids",
             "uniqueItems"
           ]) == true

    assert get_in(schema, [
             "properties",
             "station_pressure_review_contact_ids",
             "uniqueItems"
           ]) == true

    valid_station_pressure_identity =
      Map.merge(package, %{
        "station_pressure_contact_count" => 2,
        "station_pressure_contact_ids" => ["contact_a", "contact_b"]
      })

    assert {:ok, _package} = Schema.validate_artifact(valid_station_pressure_identity)

    for {contact_count, contact_ids, error_path} <- [
          {2, ["contact_b", "contact_a"], "$.station_pressure_contact_ids"},
          {1, ["contact_a", "contact_a"], "$.station_pressure_contact_ids"},
          {2, ["contact_a"], "$.station_pressure_contact_count"}
        ] do
      invalid_identity =
        Map.merge(package, %{
          "station_pressure_contact_count" => contact_count,
          "station_pressure_contact_ids" => contact_ids
        })

      assert {:error, invalid_identity_report} = Schema.validate_artifact(invalid_identity)

      assert Enum.any?(invalid_identity_report["errors"], &(&1["path"] == error_path))
    end

    valid_station_pressure_review_identity =
      Map.merge(package, %{
        "station_pressure_review_contact_count" => 2,
        "station_pressure_review_contact_ids" => ["contact_a", "contact_b"]
      })

    assert {:ok, _package} = Schema.validate_artifact(valid_station_pressure_review_identity)

    explicit_empty_station_pressure_review_identity =
      Map.merge(package, %{
        "station_pressure_review_contact_count" => 0,
        "station_pressure_review_contact_ids" => []
      })

    assert {:ok, _package} =
             Schema.validate_artifact(explicit_empty_station_pressure_review_identity)

    assert {:ok, _package} =
             package
             |> Map.put("station_pressure_review_contact_count", 2)
             |> Schema.validate_artifact()

    for {contact_count, contact_ids, error_path} <- [
          {2, ["contact_b", "contact_a"], "$.station_pressure_review_contact_ids"},
          {1, ["contact_a", "contact_a"], "$.station_pressure_review_contact_ids"},
          {2, ["contact_a"], "$.station_pressure_review_contact_count"}
        ] do
      invalid_review_identity =
        Map.merge(package, %{
          "station_pressure_review_contact_count" => contact_count,
          "station_pressure_review_contact_ids" => contact_ids
        })

      assert {:error, invalid_review_identity_report} =
               Schema.validate_artifact(invalid_review_identity)

      assert Enum.any?(invalid_review_identity_report["errors"], &(&1["path"] == error_path))
    end

    grouped_station_pressure_fields = [
      {"station_pressure_contact_counts_by_ground_station_id",
       "station_pressure_contact_ids_by_ground_station_id", "gs_a"},
      {"station_pressure_contact_counts_by_availability",
       "station_pressure_contact_ids_by_availability", "reserved"},
      {"station_pressure_contact_counts_by_precedence_availability",
       "station_pressure_contact_ids_by_precedence_availability", "reserved"},
      {"station_pressure_contact_counts_by_precedence_rank",
       "station_pressure_contact_ids_by_precedence_rank", "1"},
      {"station_pressure_contact_counts_by_status", "station_pressure_contact_ids_by_status",
       "reservation_hold"}
    ]

    for {count_field, id_field, key} <- grouped_station_pressure_fields do
      assert get_in(schema, [
               "properties",
               id_field,
               "additionalProperties",
               "uniqueItems"
             ]) == true

      valid_group =
        package
        |> Map.put(count_field, %{key => 2})
        |> Map.put(id_field, %{key => ["contact_a", "contact_b"]})

      assert {:ok, _package} = Schema.validate_artifact(valid_group)

      for {count, contact_ids, error_path} <- [
            {2, ["contact_b", "contact_a"], "$.#{id_field}.#{key}"},
            {1, ["contact_a", "contact_a"], "$.#{id_field}.#{key}"},
            {1, ["contact_a", "contact_b"], "$.#{count_field}.#{key}"}
          ] do
        invalid_group =
          package
          |> Map.put(count_field, %{key => count})
          |> Map.put(id_field, %{key => contact_ids})

        assert {:error, invalid_group_report} = Schema.validate_artifact(invalid_group)
        assert Enum.any?(invalid_group_report["errors"], &(&1["path"] == error_path))
      end
    end

    flat_direction_field = "station_pressure_contact_ids_by_direction"
    nested_direction_field = "station_pressure_contact_ids_by_direction_and_ground_station_id"

    assert get_in(schema, [
             "properties",
             flat_direction_field,
             "additionalProperties",
             "uniqueItems"
           ]) == true

    assert get_in(schema, [
             "properties",
             nested_direction_field,
             "additionalProperties",
             "additionalProperties",
             "uniqueItems"
           ]) == true

    valid_direction_routes =
      package
      |> Map.put(flat_direction_field, %{"downlink" => ["contact_a", "contact_b"]})
      |> Map.put(nested_direction_field, %{"downlink" => %{"gs_a" => ["contact_b"]}})

    assert {:ok, _package} = Schema.validate_artifact(valid_direction_routes)

    nested_only_direction_route =
      Map.put(package, nested_direction_field, %{"downlink" => %{"gs_a" => ["contact_b"]}})

    assert {:ok, _package} = Schema.validate_artifact(nested_only_direction_route)

    routed_station_pressure_identity =
      Map.merge(package, %{
        "station_pressure_review_contact_count" => 1,
        "station_pressure_review_contact_ids" => ["contact_review"],
        "station_pressure_contact_counts_by_ground_station_id" => %{"gs_a" => 1},
        "station_pressure_contact_ids_by_ground_station_id" => %{
          "gs_a" => ["contact_group"]
        },
        flat_direction_field => %{"downlink" => ["contact_nested"]},
        nested_direction_field => %{
          "downlink" => %{"gs_a" => ["contact_nested"]}
        }
      })

    assert {:ok, _package} = Schema.validate_artifact(routed_station_pressure_identity)

    valid_routed_top_identity =
      Map.merge(routed_station_pressure_identity, %{
        "station_pressure_contact_count" => 3,
        "station_pressure_contact_ids" => [
          "contact_group",
          "contact_nested",
          "contact_review"
        ]
      })

    assert {:ok, _package} = Schema.validate_artifact(valid_routed_top_identity)

    incomplete_routed_top_identity =
      Map.merge(routed_station_pressure_identity, %{
        "station_pressure_contact_count" => 1,
        "station_pressure_contact_ids" => ["contact_group"]
      })

    assert {:error, incomplete_routed_top_identity_report} =
             Schema.validate_artifact(incomplete_routed_top_identity)

    assert Enum.any?(
             incomplete_routed_top_identity_report["errors"],
             &(&1["path"] == "$.station_pressure_contact_ids")
           )

    for {flat_ids, nested_ids, error_path} <- [
          {["contact_b", "contact_a"], ["contact_b"], "$.#{flat_direction_field}.downlink"},
          {["contact_a", "contact_b"], ["contact_b", "contact_b"],
           "$.#{nested_direction_field}.downlink.gs_a"},
          {["contact_a"], ["contact_b"], "$.#{flat_direction_field}.downlink"}
        ] do
      invalid_routes =
        package
        |> Map.put(flat_direction_field, %{"downlink" => flat_ids})
        |> Map.put(nested_direction_field, %{"downlink" => %{"gs_a" => nested_ids}})

      assert {:error, invalid_routes_report} = Schema.validate_artifact(invalid_routes)
      assert Enum.any?(invalid_routes_report["errors"], &(&1["path"] == error_path))
    end

    provider_review_map_fields = [
      "provider_reservation_review_contact_ids_by_ground_station_id",
      "provider_reservation_review_contact_ids_by_direction",
      "provider_reservation_review_contact_ids_by_match_status"
    ]

    assert get_in(schema, [
             "properties",
             "provider_reservation_review_contact_ids",
             "uniqueItems"
           ]) == true

    for field <- provider_review_map_fields do
      assert get_in(schema, ["properties", field, "additionalProperties", "uniqueItems"]) ==
               true
    end

    provider_review_nested_field =
      "provider_reservation_review_contact_ids_by_direction_and_ground_station_id"

    assert get_in(schema, [
             "properties",
             provider_review_nested_field,
             "additionalProperties",
             "additionalProperties",
             "uniqueItems"
           ]) == true

    routed_provider_review_identity =
      Map.merge(package, %{
        "provider_reservation_review_contact_ids_by_ground_station_id" => %{
          "gs_a" => ["contact_station"]
        },
        "provider_reservation_review_contact_ids_by_direction" => %{
          "downlink" => ["contact_direction"]
        },
        provider_review_nested_field => %{
          "downlink" => %{"gs_a" => ["contact_nested"]}
        },
        "provider_reservation_review_contact_ids_by_match_status" => %{
          "overlap" => ["contact_match"]
        }
      })

    assert {:ok, _package} = Schema.validate_artifact(routed_provider_review_identity)

    valid_provider_review_identity =
      Map.merge(routed_provider_review_identity, %{
        "provider_reservation_review_contact_count" => 4,
        "provider_reservation_review_contact_ids" => [
          "contact_direction",
          "contact_match",
          "contact_nested",
          "contact_station"
        ]
      })

    assert {:ok, _package} = Schema.validate_artifact(valid_provider_review_identity)

    incomplete_provider_review_identity =
      Map.merge(routed_provider_review_identity, %{
        "provider_reservation_review_contact_count" => 1,
        "provider_reservation_review_contact_ids" => ["contact_station"]
      })

    assert {:error, incomplete_provider_review_identity_report} =
             Schema.validate_artifact(incomplete_provider_review_identity)

    assert Enum.any?(
             incomplete_provider_review_identity_report["errors"],
             &(&1["path"] == "$.provider_reservation_review_contact_ids")
           )

    invalid_provider_review_route =
      Map.put(package, "provider_reservation_review_contact_ids_by_direction", %{
        "downlink" => ["contact_b", "contact_a"]
      })

    assert {:error, invalid_provider_review_route_report} =
             Schema.validate_artifact(invalid_provider_review_route)

    assert Enum.any?(
             invalid_provider_review_route_report["errors"],
             &(&1["path"] ==
                 "$.provider_reservation_review_contact_ids_by_direction.downlink")
           )

    for {contact_count, contact_ids, error_path} <- [
          {2, ["contact_b", "contact_a"], "$.provider_reservation_review_contact_ids"},
          {1, ["contact_a", "contact_a"], "$.provider_reservation_review_contact_ids"},
          {2, ["contact_a"], "$.provider_reservation_review_contact_count"}
        ] do
      invalid_provider_review_identity =
        Map.merge(package, %{
          "provider_reservation_review_contact_count" => contact_count,
          "provider_reservation_review_contact_ids" => contact_ids
        })

      assert {:error, invalid_provider_review_identity_report} =
               Schema.validate_artifact(invalid_provider_review_identity)

      assert Enum.any?(
               invalid_provider_review_identity_report["errors"],
               &(&1["path"] == error_path)
             )
    end

    provider_request_map_fields = [
      "provider_reservation_request_contact_ids_by_ground_station_id",
      "provider_reservation_request_contact_ids_by_direction",
      "provider_reservation_request_contact_ids_by_match_status"
    ]

    assert get_in(schema, [
             "properties",
             "provider_reservation_request_contact_ids",
             "uniqueItems"
           ]) == true

    for field <- provider_request_map_fields do
      assert get_in(schema, ["properties", field, "additionalProperties", "uniqueItems"]) ==
               true
    end

    provider_request_nested_field =
      "provider_reservation_request_contact_ids_by_direction_and_ground_station_id"

    assert get_in(schema, [
             "properties",
             provider_request_nested_field,
             "additionalProperties",
             "additionalProperties",
             "uniqueItems"
           ]) == true

    routed_provider_request_identity =
      Map.merge(package, %{
        "provider_reservation_request_contact_ids_by_ground_station_id" => %{
          "gs_a" => ["contact_station"]
        },
        "provider_reservation_request_contact_ids_by_direction" => %{
          "downlink" => ["contact_direction"]
        },
        provider_request_nested_field => %{
          "downlink" => %{"gs_a" => ["contact_nested"]}
        },
        "provider_reservation_request_contact_ids_by_match_status" => %{
          "matched" => ["contact_match"]
        }
      })

    assert {:ok, _package} = Schema.validate_artifact(routed_provider_request_identity)

    valid_provider_request_identity =
      Map.merge(routed_provider_request_identity, %{
        "provider_reservation_request_contact_count" => 4,
        "provider_reservation_request_contact_ids" => [
          "contact_direction",
          "contact_match",
          "contact_nested",
          "contact_station"
        ]
      })

    assert {:ok, _package} = Schema.validate_artifact(valid_provider_request_identity)

    incomplete_provider_request_identity =
      Map.merge(routed_provider_request_identity, %{
        "provider_reservation_request_contact_count" => 1,
        "provider_reservation_request_contact_ids" => ["contact_station"]
      })

    assert {:error, incomplete_provider_request_identity_report} =
             Schema.validate_artifact(incomplete_provider_request_identity)

    assert Enum.any?(
             incomplete_provider_request_identity_report["errors"],
             &(&1["path"] == "$.provider_reservation_request_contact_ids")
           )

    invalid_provider_request_route =
      Map.put(package, "provider_reservation_request_contact_ids_by_direction", %{
        "downlink" => ["contact_b", "contact_a"]
      })

    assert {:error, invalid_provider_request_route_report} =
             Schema.validate_artifact(invalid_provider_request_route)

    assert Enum.any?(
             invalid_provider_request_route_report["errors"],
             &(&1["path"] ==
                 "$.provider_reservation_request_contact_ids_by_direction.downlink")
           )

    for {contact_count, contact_ids, error_path} <- [
          {2, ["contact_b", "contact_a"], "$.provider_reservation_request_contact_ids"},
          {1, ["contact_a", "contact_a"], "$.provider_reservation_request_contact_ids"},
          {2, ["contact_a"], "$.provider_reservation_request_contact_count"}
        ] do
      invalid_provider_request_identity =
        Map.merge(package, %{
          "provider_reservation_request_contact_count" => contact_count,
          "provider_reservation_request_contact_ids" => contact_ids
        })

      assert {:error, invalid_provider_request_identity_report} =
               Schema.validate_artifact(invalid_provider_request_identity)

      assert Enum.any?(
               invalid_provider_request_identity_report["errors"],
               &(&1["path"] == error_path)
             )
    end

    provider_no_request_direction_field =
      "provider_reservation_no_request_contact_ids_by_direction"

    provider_no_request_nested_field =
      "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id"

    assert get_in(schema, [
             "properties",
             "provider_reservation_no_request_contact_ids",
             "uniqueItems"
           ]) == true

    assert get_in(schema, [
             "properties",
             provider_no_request_direction_field,
             "additionalProperties",
             "uniqueItems"
           ]) == true

    assert get_in(schema, [
             "properties",
             provider_no_request_nested_field,
             "additionalProperties",
             "additionalProperties",
             "uniqueItems"
           ]) == true

    routed_provider_no_request_identity =
      Map.merge(package, %{
        provider_no_request_direction_field => %{
          "downlink" => ["contact_direction"]
        },
        provider_no_request_nested_field => %{
          "downlink" => %{"gs_a" => ["contact_nested"]}
        }
      })

    assert {:ok, _package} = Schema.validate_artifact(routed_provider_no_request_identity)

    valid_provider_no_request_identity =
      Map.merge(routed_provider_no_request_identity, %{
        "provider_reservation_no_request_contact_count" => 2,
        "provider_reservation_no_request_contact_ids" => [
          "contact_direction",
          "contact_nested"
        ]
      })

    assert {:ok, _package} = Schema.validate_artifact(valid_provider_no_request_identity)

    incomplete_provider_no_request_identity =
      Map.merge(routed_provider_no_request_identity, %{
        "provider_reservation_no_request_contact_count" => 1,
        "provider_reservation_no_request_contact_ids" => ["contact_direction"]
      })

    assert {:error, incomplete_provider_no_request_identity_report} =
             Schema.validate_artifact(incomplete_provider_no_request_identity)

    assert Enum.any?(
             incomplete_provider_no_request_identity_report["errors"],
             &(&1["path"] == "$.provider_reservation_no_request_contact_ids")
           )

    invalid_provider_no_request_route =
      Map.put(package, provider_no_request_direction_field, %{
        "downlink" => ["contact_b", "contact_a"]
      })

    assert {:error, invalid_provider_no_request_route_report} =
             Schema.validate_artifact(invalid_provider_no_request_route)

    assert Enum.any?(
             invalid_provider_no_request_route_report["errors"],
             &(&1["path"] == "$.#{provider_no_request_direction_field}.downlink")
           )

    for {contact_count, contact_ids, error_path} <- [
          {2, ["contact_b", "contact_a"], "$.provider_reservation_no_request_contact_ids"},
          {1, ["contact_a", "contact_a"], "$.provider_reservation_no_request_contact_ids"},
          {2, ["contact_a"], "$.provider_reservation_no_request_contact_count"}
        ] do
      invalid_provider_no_request_identity =
        Map.merge(package, %{
          "provider_reservation_no_request_contact_count" => contact_count,
          "provider_reservation_no_request_contact_ids" => contact_ids
        })

      assert {:error, invalid_provider_no_request_identity_report} =
               Schema.validate_artifact(invalid_provider_no_request_identity)

      assert Enum.any?(
               invalid_provider_no_request_identity_report["errors"],
               &(&1["path"] == error_path)
             )
    end

    invalid_station_pressure_ids =
      Map.put(package, "station_pressure_contact_ids", ["bad id"])

    assert {:error, station_pressure_ids_report} =
             Schema.validate_artifact(invalid_station_pressure_ids)

    assert Enum.any?(
             station_pressure_ids_report["errors"],
             &(&1["path"] == "$.station_pressure_contact_ids[0]")
           )
  end

  test "correlates capacity-pack group identity with top and status counts" do
    fields = [
      "reduced_capacity_pack_group_count",
      "reduced_capacity_pack_status_counts",
      "capacity_pack_group_ids",
      "capacity_pack_group_ids_by_status"
    ]

    package =
      "study_results/operator_review_resource_pressure_v1.json"
      |> read_json!()
      |> Map.drop(fields)

    schema = read_json!("schemas/operator_review_package.v1.schema.json")

    assert get_in(schema, ["properties", "capacity_pack_group_ids", "uniqueItems"]) == true

    assert get_in(schema, [
             "properties",
             "capacity_pack_group_ids_by_status",
             "additionalProperties",
             "uniqueItems"
           ]) == true

    routed_identity =
      Map.merge(package, %{
        "reduced_capacity_pack_status_counts" => %{"all_fit" => 2},
        "capacity_pack_group_ids_by_status" => %{
          "all_fit" => ["pack_direction", "pack_nested"]
        }
      })

    assert {:ok, _package} = Schema.validate_artifact(routed_identity)

    valid_identity =
      Map.merge(routed_identity, %{
        "reduced_capacity_pack_group_count" => 2,
        "capacity_pack_group_ids" => ["pack_direction", "pack_nested"]
      })

    assert {:ok, _package} = Schema.validate_artifact(valid_identity)

    incomplete_identity =
      Map.merge(routed_identity, %{
        "reduced_capacity_pack_group_count" => 1,
        "capacity_pack_group_ids" => ["pack_direction"]
      })

    assert {:error, incomplete_identity_report} = Schema.validate_artifact(incomplete_identity)

    assert Enum.any?(
             incomplete_identity_report["errors"],
             &(&1["path"] == "$.capacity_pack_group_ids")
           )

    invalid_route =
      Map.merge(package, %{
        "reduced_capacity_pack_status_counts" => %{"all_fit" => 2},
        "capacity_pack_group_ids_by_status" => %{
          "all_fit" => ["pack_b", "pack_a"]
        }
      })

    assert {:error, invalid_route_report} = Schema.validate_artifact(invalid_route)

    assert Enum.any?(
             invalid_route_report["errors"],
             &(&1["path"] == "$.capacity_pack_group_ids_by_status.all_fit")
           )

    invalid_status_count =
      put_in(routed_identity, ["reduced_capacity_pack_status_counts", "all_fit"], 1)

    assert {:error, invalid_status_count_report} = Schema.validate_artifact(invalid_status_count)

    assert Enum.any?(
             invalid_status_count_report["errors"],
             &(&1["path"] == "$.reduced_capacity_pack_status_counts.all_fit")
           )

    for {group_count, group_ids, error_path} <- [
          {2, ["pack_b", "pack_a"], "$.capacity_pack_group_ids"},
          {1, ["pack_a", "pack_a"], "$.capacity_pack_group_ids"},
          {2, ["pack_a"], "$.reduced_capacity_pack_group_count"}
        ] do
      invalid_identity =
        Map.merge(package, %{
          "reduced_capacity_pack_group_count" => group_count,
          "capacity_pack_group_ids" => group_ids
        })

      assert {:error, invalid_identity_report} = Schema.validate_artifact(invalid_identity)

      assert Enum.any?(
               invalid_identity_report["errors"],
               &(&1["path"] == error_path)
             )
    end
  end

  test "correlates capacity-pack contact IDs with status counts" do
    fields = ["capacity_pack_status_counts", "capacity_pack_contact_ids_by_status"]

    package =
      "study_results/operator_review_resource_pressure_v1.json"
      |> read_json!()
      |> Map.drop(fields)

    schema = read_json!("schemas/operator_review_package.v1.schema.json")
    status = "deferred_by_reduced_station_capacity_pack"

    assert get_in(schema, [
             "properties",
             "capacity_pack_contact_ids_by_status",
             "additionalProperties",
             "uniqueItems"
           ]) == true

    assert get_in(schema, [
             "properties",
             "capacity_pack_status_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    valid_identity =
      Map.merge(package, %{
        "capacity_pack_status_counts" => %{status => 2},
        "capacity_pack_contact_ids_by_status" => %{
          status => ["contact_a", "contact_b"]
        }
      })

    assert {:ok, _package} = Schema.validate_artifact(valid_identity)

    count_only = Map.put(package, "capacity_pack_status_counts", %{status => 2})
    assert {:ok, _package} = Schema.validate_artifact(count_only)

    invalid_route =
      Map.merge(package, %{
        "capacity_pack_status_counts" => %{status => 2},
        "capacity_pack_contact_ids_by_status" => %{
          status => ["contact_b", "contact_a"]
        }
      })

    assert {:error, invalid_route_report} = Schema.validate_artifact(invalid_route)

    assert Enum.any?(
             invalid_route_report["errors"],
             &(&1["path"] == "$.capacity_pack_contact_ids_by_status.#{status}")
           )

    for status_count <- [nil, 1] do
      invalid_count =
        Map.merge(package, %{
          "capacity_pack_status_counts" =>
            if(status_count == nil, do: %{}, else: %{status => status_count}),
          "capacity_pack_contact_ids_by_status" => %{status => ["contact_a", "contact_b"]}
        })

      assert {:error, invalid_count_report} = Schema.validate_artifact(invalid_count)

      assert Enum.any?(
               invalid_count_report["errors"],
               &(&1["path"] == "$.capacity_pack_status_counts.#{status}")
             )
    end
  end

  test "correlates station-reservation contact IDs with match-status counts" do
    fields = [
      "station_reservation_match_status_counts",
      "station_reservation_contact_ids_by_match_status"
    ]

    package =
      "study_results/operator_review_resource_pressure_v1.json"
      |> read_json!()
      |> Map.drop(fields)

    schema = read_json!("schemas/operator_review_package.v1.schema.json")
    status = "overlap"

    assert get_in(schema, [
             "properties",
             "station_reservation_contact_ids_by_match_status",
             "additionalProperties",
             "uniqueItems"
           ]) == true

    valid_identity =
      Map.merge(package, %{
        "station_reservation_match_status_counts" => %{status => 2},
        "station_reservation_contact_ids_by_match_status" => %{
          status => ["contact_a", "contact_b"]
        }
      })

    assert {:ok, _package} = Schema.validate_artifact(valid_identity)

    count_only = Map.put(package, "station_reservation_match_status_counts", %{status => 2})
    assert {:ok, _package} = Schema.validate_artifact(count_only)

    invalid_route =
      Map.merge(package, %{
        "station_reservation_match_status_counts" => %{status => 2},
        "station_reservation_contact_ids_by_match_status" => %{
          status => ["contact_b", "contact_a"]
        }
      })

    assert {:error, invalid_route_report} = Schema.validate_artifact(invalid_route)

    assert Enum.any?(
             invalid_route_report["errors"],
             &(&1["path"] ==
                 "$.station_reservation_contact_ids_by_match_status.#{status}")
           )

    for status_count <- [nil, 1] do
      invalid_count =
        Map.merge(package, %{
          "station_reservation_match_status_counts" =>
            if(status_count == nil, do: %{}, else: %{status => status_count}),
          "station_reservation_contact_ids_by_match_status" => %{
            status => ["contact_a", "contact_b"]
          }
        })

      assert {:error, invalid_count_report} = Schema.validate_artifact(invalid_count)

      assert Enum.any?(
               invalid_count_report["errors"],
               &(&1["path"] == "$.station_reservation_match_status_counts.#{status}")
             )
    end
  end

  test "correlates top-level and routed station-reservation identity" do
    route_fields = [
      "station_reservation_ids_by_expiration_status",
      "station_reservation_ids_by_match_status",
      "station_reservation_ids_by_status",
      "station_reservation_ids_by_reserved_by"
    ]

    package =
      "study_results/operator_review_resource_pressure_v1.json"
      |> read_json!()
      |> Map.drop(["station_reservation_ids" | route_fields])

    schema = read_json!("schemas/operator_review_package.v1.schema.json")

    assert get_in(schema, ["properties", "station_reservation_ids", "uniqueItems"]) == true

    for field <- route_fields do
      assert get_in(schema, ["properties", field, "additionalProperties", "uniqueItems"]) ==
               true
    end

    valid_identity =
      Map.merge(package, %{
        "station_reservation_ids" => ["reservation_direct", "reservation_routed"],
        "station_reservation_ids_by_match_status" => %{
          "overlap" => ["reservation_routed"]
        }
      })

    assert {:ok, _package} = Schema.validate_artifact(valid_identity)

    route_only =
      Map.put(package, "station_reservation_ids_by_match_status", %{
        "overlap" => ["reservation_routed"]
      })

    assert {:ok, _package} = Schema.validate_artifact(route_only)

    invalid_top = Map.put(valid_identity, "station_reservation_ids", ["reservation_direct"])
    assert {:error, invalid_top_report} = Schema.validate_artifact(invalid_top)

    assert Enum.any?(
             invalid_top_report["errors"],
             &(&1["path"] == "$.station_reservation_ids")
           )

    invalid_route =
      Map.merge(package, %{
        "station_reservation_ids" => [
          "reservation_a",
          "reservation_direct",
          "reservation_z"
        ],
        "station_reservation_ids_by_status" => %{
          "confirmed" => ["reservation_z", "reservation_a"]
        }
      })

    assert {:error, invalid_route_report} = Schema.validate_artifact(invalid_route)

    assert Enum.any?(
             invalid_route_report["errors"],
             &(&1["path"] == "$.station_reservation_ids_by_status.confirmed")
           )
  end

  test "correlates station-reservation contact IDs with owner counts" do
    fields = [
      "station_reserved_by_counts",
      "station_reservation_contact_ids_by_reserved_by"
    ]

    package =
      "study_results/operator_review_resource_pressure_v1.json"
      |> read_json!()
      |> Map.drop(fields)

    schema = read_json!("schemas/operator_review_package.v1.schema.json")
    owner = "mission_ops"

    assert get_in(schema, [
             "properties",
             "station_reservation_contact_ids_by_reserved_by",
             "additionalProperties",
             "uniqueItems"
           ]) == true

    valid_identity =
      Map.merge(package, %{
        "station_reserved_by_counts" => %{owner => 2},
        "station_reservation_contact_ids_by_reserved_by" => %{
          owner => ["contact_a", "contact_b"]
        }
      })

    assert {:ok, _package} = Schema.validate_artifact(valid_identity)

    count_only = Map.put(package, "station_reserved_by_counts", %{owner => 2})
    assert {:ok, _package} = Schema.validate_artifact(count_only)

    invalid_route =
      Map.merge(package, %{
        "station_reserved_by_counts" => %{owner => 2},
        "station_reservation_contact_ids_by_reserved_by" => %{
          owner => ["contact_b", "contact_a"]
        }
      })

    assert {:error, invalid_route_report} = Schema.validate_artifact(invalid_route)

    assert Enum.any?(
             invalid_route_report["errors"],
             &(&1["path"] == "$.station_reservation_contact_ids_by_reserved_by.#{owner}")
           )

    for owner_count <- [nil, 1] do
      invalid_count =
        Map.merge(package, %{
          "station_reserved_by_counts" =>
            if(owner_count == nil, do: %{}, else: %{owner => owner_count}),
          "station_reservation_contact_ids_by_reserved_by" => %{
            owner => ["contact_a", "contact_b"]
          }
        })

      assert {:error, invalid_count_report} = Schema.validate_artifact(invalid_count)

      assert Enum.any?(
               invalid_count_report["errors"],
               &(&1["path"] == "$.station_reserved_by_counts.#{owner}")
             )
    end
  end

  test "correlates station-reservation contact IDs with status counts" do
    fields = [
      "station_reservation_status_counts",
      "station_reservation_contact_ids_by_status"
    ]

    package =
      "study_results/operator_review_resource_pressure_v1.json"
      |> read_json!()
      |> Map.drop(fields)

    schema = read_json!("schemas/operator_review_package.v1.schema.json")
    status = "confirmed"

    assert get_in(schema, [
             "properties",
             "station_reservation_contact_ids_by_status",
             "additionalProperties",
             "uniqueItems"
           ]) == true

    valid_identity =
      Map.merge(package, %{
        "station_reservation_status_counts" => %{status => 2},
        "station_reservation_contact_ids_by_status" => %{
          status => ["contact_a", "contact_b"]
        }
      })

    assert {:ok, _package} = Schema.validate_artifact(valid_identity)

    count_only = Map.put(package, "station_reservation_status_counts", %{status => 2})
    assert {:ok, _package} = Schema.validate_artifact(count_only)

    invalid_route =
      Map.merge(package, %{
        "station_reservation_status_counts" => %{status => 2},
        "station_reservation_contact_ids_by_status" => %{
          status => ["contact_b", "contact_a"]
        }
      })

    assert {:error, invalid_route_report} = Schema.validate_artifact(invalid_route)

    assert Enum.any?(
             invalid_route_report["errors"],
             &(&1["path"] == "$.station_reservation_contact_ids_by_status.#{status}")
           )

    for status_count <- [nil, 1] do
      invalid_count =
        Map.merge(package, %{
          "station_reservation_status_counts" =>
            if(status_count == nil, do: %{}, else: %{status => status_count}),
          "station_reservation_contact_ids_by_status" => %{
            status => ["contact_a", "contact_b"]
          }
        })

      assert {:error, invalid_count_report} = Schema.validate_artifact(invalid_count)

      assert Enum.any?(
               invalid_count_report["errors"],
               &(&1["path"] == "$.station_reservation_status_counts.#{status}")
             )
    end
  end

  test "correlates station-reservation contact IDs with expiration counts" do
    scalar_count_field = "station_reservation_declared_expiration_contact_count"

    fields = [
      "station_reservation_expiration_status_counts",
      "station_reservation_contact_ids_by_expiration_status",
      scalar_count_field
    ]

    package =
      "study_results/operator_review_resource_pressure_v1.json"
      |> read_json!()
      |> Map.drop(fields)

    schema = read_json!("schemas/operator_review_package.v1.schema.json")
    status = "declared"

    assert get_in(schema, [
             "properties",
             "station_reservation_contact_ids_by_expiration_status",
             "additionalProperties",
             "uniqueItems"
           ]) == true

    valid_identity =
      Map.merge(package, %{
        "station_reservation_expiration_status_counts" => %{status => 2},
        scalar_count_field => 2,
        "station_reservation_contact_ids_by_expiration_status" => %{
          status => ["contact_a", "contact_b"]
        }
      })

    assert {:ok, _package} = Schema.validate_artifact(valid_identity)

    count_only =
      Map.merge(package, %{
        "station_reservation_expiration_status_counts" => %{status => 2},
        scalar_count_field => 2
      })

    assert {:ok, _package} = Schema.validate_artifact(count_only)

    assert {:ok, _package} =
             valid_identity
             |> Map.delete(scalar_count_field)
             |> Schema.validate_artifact()

    invalid_route =
      put_in(
        valid_identity,
        ["station_reservation_contact_ids_by_expiration_status", status],
        ["contact_b", "contact_a"]
      )

    assert {:error, invalid_route_report} = Schema.validate_artifact(invalid_route)

    assert Enum.any?(
             invalid_route_report["errors"],
             &(&1["path"] ==
                 "$.station_reservation_contact_ids_by_expiration_status.#{status}")
           )

    for count <- [nil, 1] do
      invalid_count =
        put_in(
          valid_identity,
          ["station_reservation_expiration_status_counts"],
          if(count == nil, do: %{}, else: %{status => count})
        )

      assert {:error, invalid_count_report} = Schema.validate_artifact(invalid_count)

      assert Enum.any?(
               invalid_count_report["errors"],
               &(&1["path"] == "$.station_reservation_expiration_status_counts.#{status}")
             )
    end

    invalid_scalar_count = Map.put(valid_identity, scalar_count_field, 1)
    assert {:error, invalid_scalar_report} = Schema.validate_artifact(invalid_scalar_count)

    assert Enum.any?(
             invalid_scalar_report["errors"],
             &(&1["path"] == "$.#{scalar_count_field}")
           )
  end

  test "correlates required-capacity contact IDs with source counts" do
    fields = [
      "required_capacity_fraction_source_counts",
      "required_capacity_fraction_contact_ids_by_source"
    ]

    package =
      "study_results/operator_review_resource_pressure_v1.json"
      |> read_json!()
      |> Map.drop(fields)

    schema = read_json!("schemas/operator_review_package.v1.schema.json")
    source = "capacity_model"

    assert get_in(schema, [
             "properties",
             "required_capacity_fraction_contact_ids_by_source",
             "additionalProperties",
             "uniqueItems"
           ]) == true

    valid_identity =
      Map.merge(package, %{
        "required_capacity_fraction_source_counts" => %{source => 2},
        "required_capacity_fraction_contact_ids_by_source" => %{
          source => ["contact_a", "contact_b"]
        }
      })

    assert {:ok, _package} = Schema.validate_artifact(valid_identity)

    count_only = Map.put(package, "required_capacity_fraction_source_counts", %{source => 2})
    assert {:ok, _package} = Schema.validate_artifact(count_only)

    invalid_route =
      Map.merge(package, %{
        "required_capacity_fraction_source_counts" => %{source => 2},
        "required_capacity_fraction_contact_ids_by_source" => %{
          source => ["contact_b", "contact_a"]
        }
      })

    assert {:error, invalid_route_report} = Schema.validate_artifact(invalid_route)

    assert Enum.any?(
             invalid_route_report["errors"],
             &(&1["path"] == "$.required_capacity_fraction_contact_ids_by_source.#{source}")
           )

    for source_count <- [nil, 1] do
      invalid_count =
        Map.merge(package, %{
          "required_capacity_fraction_source_counts" =>
            if(source_count == nil, do: %{}, else: %{source => source_count}),
          "required_capacity_fraction_contact_ids_by_source" => %{
            source => ["contact_a", "contact_b"]
          }
        })

      assert {:error, invalid_count_report} = Schema.validate_artifact(invalid_count)

      assert Enum.any?(
               invalid_count_report["errors"],
               &(&1["path"] == "$.required_capacity_fraction_source_counts.#{source}")
             )
    end
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
