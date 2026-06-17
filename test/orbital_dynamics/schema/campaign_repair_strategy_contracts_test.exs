defmodule OrbitalDynamics.Schema.CampaignRepairStrategyContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CampaignPlanner, Epoch, ResultSet, Schema}

  test "validates standalone repair and strategy decision contracts" do
    repair = repair_artifact()
    strategy = strategy_artifact(repair)

    plan_delta = List.first(repair["deltas"])

    approval_requirement = %{
      "schema_contract" => "approval_requirement.v1",
      "activity_id" => "dl_1",
      "activity_type" => "downlink",
      "requirement_type" => "contact_schedule_change",
      "action" => "approve_moved_contact",
      "reason" => "operator_review_boundary"
    }

    assert {:ok, %{"schema_contract" => "plan_delta.v1"}} =
             Schema.validate_artifact(plan_delta)

    fixture_plan_delta = read_json!("study_results/plan_delta_v1.json")

    assert {:ok, %{"schema_contract" => "plan_delta.v1"}} =
             Schema.validate_artifact(fixture_plan_delta)

    invalid_planned_delta =
      put_in(fixture_plan_delta, ["planned", "target_id"], "target id with spaces")

    assert {:error, invalid_planned_delta_report} =
             Schema.validate_artifact(invalid_planned_delta)

    assert Enum.any?(
             invalid_planned_delta_report["errors"],
             &(&1["path"] == "$.planned.target_id")
           )

    invalid_realized_delta =
      put_in(fixture_plan_delta, ["realized", "completed_fraction"], 1.2)

    assert {:error, invalid_realized_delta_report} =
             Schema.validate_artifact(invalid_realized_delta)

    assert Enum.any?(
             invalid_realized_delta_report["errors"],
             &(&1["path"] == "$.realized.completed_fraction")
           )

    assert {:ok, %{"schema_contract" => "approval_requirement.v1"}} =
             Schema.validate_artifact(approval_requirement)

    fixture_requirement = read_json!("study_results/approval_requirement_v1.json")

    assert {:ok, %{"schema_contract" => "approval_requirement.v1"}} =
             Schema.validate_artifact(fixture_requirement)

    invalid_requirement = Map.put(approval_requirement, "requirement_type", "ambiguous")

    assert {:error, invalid_requirement_report} = Schema.validate_artifact(invalid_requirement)

    assert Enum.any?(
             invalid_requirement_report["errors"],
             &(&1["path"] == "$.requirement_type")
           )

    invalid_policy_requirement =
      Map.put(fixture_requirement, "policy_classification", "maybe")

    assert {:error, invalid_policy_requirement_report} =
             Schema.validate_artifact(invalid_policy_requirement)

    assert Enum.any?(
             invalid_policy_requirement_report["errors"],
             &(&1["path"] == "$.policy_classification")
           )

    invalid_context_objective_id =
      put_in(
        fixture_requirement,
        ["activity_context", "observation_objective_ids"],
        ["obs:valid", "bad objective id"]
      )

    assert {:error, invalid_context_report} =
             Schema.validate_artifact(invalid_context_objective_id)

    assert Enum.any?(
             invalid_context_report["errors"],
             &(&1["path"] == "$.activity_context.observation_objective_ids[1]")
           )

    invalid_context_objective_ids =
      put_in(
        fixture_requirement,
        ["activity_context", "objective_ids"],
        ["objective:valid", "bad objective id"]
      )

    assert {:error, invalid_context_objective_ids_report} =
             Schema.validate_artifact(invalid_context_objective_ids)

    assert Enum.any?(
             invalid_context_objective_ids_report["errors"],
             &(&1["path"] == "$.activity_context.objective_ids[1]")
           )

    invalid_context_selector_id =
      put_in(
        fixture_requirement,
        ["activity_context", "collection_ids"],
        ["collection:valid", "bad collection id"]
      )

    assert {:error, invalid_context_selector_report} =
             Schema.validate_artifact(invalid_context_selector_id)

    assert Enum.any?(
             invalid_context_selector_report["errors"],
             &(&1["path"] == "$.activity_context.collection_ids[1]")
           )

    invalid_context_count =
      put_in(
        fixture_requirement,
        ["activity_context", "collection_latency_objective_count"],
        -1
      )

    assert {:error, invalid_context_count_report} =
             Schema.validate_artifact(invalid_context_count)

    assert Enum.any?(
             invalid_context_count_report["errors"],
             &(&1["path"] == "$.activity_context.collection_latency_objective_count")
           )

    invalid_context_station_id =
      put_in(
        fixture_requirement,
        ["activity_context", "station_calendar_provider_entry_id"],
        "bad provider entry id"
      )

    assert {:error, invalid_context_station_id_report} =
             Schema.validate_artifact(invalid_context_station_id)

    assert Enum.any?(
             invalid_context_station_id_report["errors"],
             &(&1["path"] == "$.activity_context.station_calendar_provider_entry_id")
           )

    invalid_context_source_event_id =
      put_in(
        fixture_requirement,
        ["activity_context", "source_event_id"],
        "bad source event id"
      )

    assert {:error, invalid_context_source_event_id_report} =
             Schema.validate_artifact(invalid_context_source_event_id)

    assert Enum.any?(
             invalid_context_source_event_id_report["errors"],
             &(&1["path"] == "$.activity_context.source_event_id")
           )

    invalid_context_source_event_provenance =
      put_in(
        fixture_requirement,
        ["activity_context", "source_event_provenance"],
        "opaque provenance"
      )

    assert {:error, invalid_context_source_event_provenance_report} =
             Schema.validate_artifact(invalid_context_source_event_provenance)

    assert Enum.any?(
             invalid_context_source_event_provenance_report["errors"],
             &(&1["path"] == "$.activity_context.source_event_provenance")
           )

    invalid_context_source_event_trust_boundary =
      put_in(
        fixture_requirement,
        ["activity_context", "source_event_provenance"],
        %{"trust_boundary" => ["operator_supplied"]}
      )

    assert {:error, invalid_context_source_event_trust_boundary_report} =
             Schema.validate_artifact(invalid_context_source_event_trust_boundary)

    assert Enum.any?(
             invalid_context_source_event_trust_boundary_report["errors"],
             &(&1["path"] == "$.activity_context.source_event_provenance.trust_boundary")
           )

    invalid_context_score_terms =
      put_in(
        fixture_requirement,
        ["activity_context", "score_terms"],
        %{"activity_score" => "high"}
      )

    assert {:error, invalid_context_score_terms_report} =
             Schema.validate_artifact(invalid_context_score_terms)

    assert Enum.any?(
             invalid_context_score_terms_report["errors"],
             &(&1["path"] == "$.activity_context.score_terms.activity_score")
           )

    invalid_context_throughput_derivation =
      put_in(
        fixture_requirement,
        ["activity_context", "actual_data_rate_throughput_derivation"],
        %{"actual_data_rate_mbps" => "fast"}
      )

    assert {:error, invalid_context_throughput_derivation_report} =
             Schema.validate_artifact(invalid_context_throughput_derivation)

    assert Enum.any?(
             invalid_context_throughput_derivation_report["errors"],
             &(&1["path"] ==
                 "$.activity_context.actual_data_rate_throughput_derivation.actual_data_rate_mbps")
           )

    invalid_context_source_window =
      put_in(
        fixture_requirement,
        ["activity_context", "source_window"],
        "opaque window"
      )

    assert {:error, invalid_context_source_window_report} =
             Schema.validate_artifact(invalid_context_source_window)

    assert Enum.any?(
             invalid_context_source_window_report["errors"],
             &(&1["path"] == "$.activity_context.source_window")
           )

    invalid_context_source_window_id =
      put_in(
        fixture_requirement,
        ["activity_context", "source_window"],
        %{"id" => "bad source window id"}
      )

    assert {:error, invalid_context_source_window_id_report} =
             Schema.validate_artifact(invalid_context_source_window_id)

    assert Enum.any?(
             invalid_context_source_window_id_report["errors"],
             &(&1["path"] == "$.activity_context.source_window.id")
           )

    invalid_context_source_window_timing =
      put_in(
        fixture_requirement,
        ["activity_context", "source_window"],
        %{"id" => "window:valid", "starts_at_s" => "soon"}
      )

    assert {:error, invalid_context_source_window_timing_report} =
             Schema.validate_artifact(invalid_context_source_window_timing)

    assert Enum.any?(
             invalid_context_source_window_timing_report["errors"],
             &(&1["path"] == "$.activity_context.source_window.starts_at_s")
           )

    invalid_context_changed_field_count =
      fixture_requirement
      |> put_in(["activity_context", "candidate_diff_changed_fields"], ["target_priority"])
      |> put_in(["activity_context", "candidate_diff_changed_field_count"], 2)

    assert {:error, invalid_context_changed_field_count_report} =
             Schema.validate_artifact(invalid_context_changed_field_count)

    assert Enum.any?(
             invalid_context_changed_field_count_report["errors"],
             &(&1["path"] == "$.activity_context.candidate_diff_changed_field_count")
           )

    invalid_context_station_overlap_id =
      put_in(
        fixture_requirement,
        ["activity_context", "station_calendar_overlap_entry_ids"],
        ["station_calendar:valid", "bad overlap id"]
      )

    assert {:error, invalid_context_station_overlap_id_report} =
             Schema.validate_artifact(invalid_context_station_overlap_id)

    assert Enum.any?(
             invalid_context_station_overlap_id_report["errors"],
             &(&1["path"] == "$.activity_context.station_calendar_overlap_entry_ids[1]")
           )

    invalid_context_integrity_issue_types =
      put_in(
        fixture_requirement,
        ["activity_context", "timeline_integrity_issue_types"],
        ["missing_dependency_activity", 42]
      )

    assert {:error, invalid_context_integrity_issue_types_report} =
             Schema.validate_artifact(invalid_context_integrity_issue_types)

    assert Enum.any?(
             invalid_context_integrity_issue_types_report["errors"],
             &(&1["path"] == "$.activity_context.timeline_integrity_issue_types[1]")
           )

    stale_context_integrity_issue_type =
      put_in(
        fixture_requirement,
        ["activity_context", "timeline_integrity_issue_types"],
        ["ghost_integrity_issue"]
      )

    assert {:error, stale_context_integrity_issue_type_report} =
             Schema.validate_artifact(stale_context_integrity_issue_type)

    assert Enum.any?(
             stale_context_integrity_issue_type_report["errors"],
             &(&1["path"] == "$.activity_context.timeline_integrity_issue_types[0]")
           )

    invalid_context_integrity_issues =
      put_in(
        fixture_requirement,
        ["activity_context", "timeline_integrity_issues"],
        ["opaque issue"]
      )

    assert {:error, invalid_context_integrity_issues_report} =
             Schema.validate_artifact(invalid_context_integrity_issues)

    assert Enum.any?(
             invalid_context_integrity_issues_report["errors"],
             &(&1["path"] == "$.activity_context.timeline_integrity_issues[0]")
           )

    invalid_context_integrity_issue_id =
      put_in(
        fixture_requirement,
        ["activity_context", "timeline_integrity_issues"],
        [
          %{
            "type" => "missing_dependency_activity",
            "missing_dependency_activity_id" => "bad dependency id"
          }
        ]
      )

    assert {:error, invalid_context_integrity_issue_id_report} =
             Schema.validate_artifact(invalid_context_integrity_issue_id)

    assert Enum.any?(
             invalid_context_integrity_issue_id_report["errors"],
             &(&1["path"] ==
                 "$.activity_context.timeline_integrity_issues[0].missing_dependency_activity_id")
           )

    invalid_context_integrity_issue_count =
      fixture_requirement
      |> put_in(["activity_context", "timeline_integrity_issue_count"], 2)
      |> put_in(["activity_context", "timeline_integrity_issue_types"], [
        "missing_dependency_activity"
      ])
      |> put_in(["activity_context", "missing_dependency_activity_ids"], ["dependency:missing"])
      |> put_in(["activity_context", "timeline_integrity_issues"], [
        %{
          "type" => "missing_dependency_activity",
          "missing_dependency_activity_id" => "dependency:missing"
        }
      ])

    assert {:error, invalid_context_integrity_issue_count_report} =
             Schema.validate_artifact(invalid_context_integrity_issue_count)

    assert Enum.any?(
             invalid_context_integrity_issue_count_report["errors"],
             &(&1["path"] == "$.activity_context.timeline_integrity_issue_count")
           )

    invalid_context_integrity_issue_ids =
      fixture_requirement
      |> put_in(["activity_context", "timeline_integrity_issue_count"], 1)
      |> put_in(["activity_context", "timeline_integrity_issue_types"], [
        "missing_dependency_activity"
      ])
      |> put_in(["activity_context", "missing_dependency_activity_ids"], ["dependency:stale"])
      |> put_in(["activity_context", "timeline_integrity_issues"], [
        %{
          "type" => "missing_dependency_activity",
          "missing_dependency_activity_id" => "dependency:missing"
        }
      ])

    assert {:error, invalid_context_integrity_issue_ids_report} =
             Schema.validate_artifact(invalid_context_integrity_issue_ids)

    assert Enum.any?(
             invalid_context_integrity_issue_ids_report["errors"],
             &(&1["path"] == "$.activity_context.missing_dependency_activity_ids")
           )

    for field <- [
          "self_dependency_activity_ids",
          "self_dependency_timeline_ids",
          "duplicate_dependency_activity_ids",
          "duplicate_dependency_timeline_ids",
          "duplicate_exclusivity_activity_ids",
          "duplicate_exclusivity_timeline_ids"
        ] do
      invalid_context_timeline_integrity_id =
        put_in(
          fixture_requirement,
          ["activity_context", field],
          ["timeline_integrity:valid", "bad #{field}"]
        )

      assert {:error, invalid_context_timeline_integrity_id_report} =
               Schema.validate_artifact(invalid_context_timeline_integrity_id)

      assert Enum.any?(
               invalid_context_timeline_integrity_id_report["errors"],
               &(&1["path"] == "$.activity_context.#{field}[1]")
             )
    end

    invalid_context_overlap_count =
      put_in(
        fixture_requirement,
        ["activity_context", "station_calendar_reservation_overlap_count"],
        -1
      )

    assert {:error, invalid_context_overlap_count_report} =
             Schema.validate_artifact(invalid_context_overlap_count)

    assert Enum.any?(
             invalid_context_overlap_count_report["errors"],
             &(&1["path"] == "$.activity_context.station_calendar_reservation_overlap_count")
           )

    invalid_context_success_factor =
      put_in(
        fixture_requirement,
        ["activity_context", "contact_success_factor"],
        1.2
      )

    assert {:error, invalid_context_success_factor_report} =
             Schema.validate_artifact(invalid_context_success_factor)

    assert Enum.any?(
             invalid_context_success_factor_report["errors"],
             &(&1["path"] == "$.activity_context.contact_success_factor")
           )

    invalid_context_resource_margin =
      put_in(
        fixture_requirement,
        ["activity_context", "storage_margin"],
        -0.1
      )

    assert {:error, invalid_context_resource_margin_report} =
             Schema.validate_artifact(invalid_context_resource_margin)

    assert Enum.any?(
             invalid_context_resource_margin_report["errors"],
             &(&1["path"] == "$.activity_context.storage_margin")
           )

    invalid_context_blur_score =
      put_in(
        fixture_requirement,
        ["activity_context", "blur_score"],
        1.2
      )

    assert {:error, invalid_context_blur_score_report} =
             Schema.validate_artifact(invalid_context_blur_score)

    assert Enum.any?(
             invalid_context_blur_score_report["errors"],
             &(&1["path"] == "$.activity_context.blur_score")
           )

    invalid_context_image_quality_score =
      put_in(
        fixture_requirement,
        ["activity_context", "image_quality_score"],
        1.2
      )

    assert {:error, invalid_context_image_quality_score_report} =
             Schema.validate_artifact(invalid_context_image_quality_score)

    assert Enum.any?(
             invalid_context_image_quality_score_report["errors"],
             &(&1["path"] == "$.activity_context.image_quality_score")
           )

    valid_context_lighting_confidence =
      put_in(
        fixture_requirement,
        ["activity_context", "lighting_confidence"],
        "bounded_by_sampled_eclipse_overlap"
      )

    assert {:ok, %{"schema_contract" => "approval_requirement.v1"}} =
             Schema.validate_artifact(valid_context_lighting_confidence)

    valid_numeric_context_lighting_confidence =
      put_in(
        fixture_requirement,
        ["activity_context", "lighting_confidence"],
        0.72
      )

    assert {:ok, %{"schema_contract" => "approval_requirement.v1"}} =
             Schema.validate_artifact(valid_numeric_context_lighting_confidence)

    invalid_context_lighting_confidence =
      put_in(
        fixture_requirement,
        ["activity_context", "lighting_confidence"],
        %{"label" => "bounded_by_sampled_eclipse_overlap"}
      )

    assert {:error, invalid_context_lighting_confidence_report} =
             Schema.validate_artifact(invalid_context_lighting_confidence)

    assert Enum.any?(
             invalid_context_lighting_confidence_report["errors"],
             &(&1["path"] == "$.activity_context.lighting_confidence")
           )

    assert {:ok, approval_requirement_schema} = Schema.json_schema("approval_requirement.v1")

    assert get_in(approval_requirement_schema, ["properties", "rule_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(approval_requirement_schema, ["properties", "activity_context", "type"]) ==
             "object"

    assert get_in(approval_requirement_schema, [
             "properties",
             "activity_context",
             "properties",
             "station_calendar_overlap_entry_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    for field <- [
          "target_ids",
          "objective_ids",
          "collection_ids",
          "product_ids",
          "payload_ids",
          "instrument_ids",
          "self_dependency_activity_ids",
          "self_dependency_timeline_ids",
          "duplicate_dependency_activity_ids",
          "duplicate_dependency_timeline_ids",
          "duplicate_exclusivity_activity_ids",
          "duplicate_exclusivity_timeline_ids"
        ] do
      assert get_in(approval_requirement_schema, [
               "properties",
               "activity_context",
               "properties",
               field,
               "items",
               "pattern"
             ]) == Schema.identity_policy()["stable_id_pattern"]
    end

    assert get_in(approval_requirement_schema, [
             "properties",
             "activity_context",
             "properties",
             "objective_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    for field <- ["source_event_id", "source_branch_id", "source_timeline_id"] do
      assert get_in(approval_requirement_schema, [
               "properties",
               "activity_context",
               "properties",
               field,
               "pattern"
             ]) == Schema.identity_policy()["stable_id_pattern"]
    end

    assert get_in(approval_requirement_schema, [
             "properties",
             "activity_context",
             "properties",
             "source_event_type",
             "type"
           ]) == "string"

    assert get_in(approval_requirement_schema, [
             "properties",
             "activity_context",
             "properties",
             "source_event_provenance",
             "type"
           ]) == "object"

    assert get_in(approval_requirement_schema, [
             "properties",
             "activity_context",
             "properties",
             "lighting_confidence",
             "type"
           ]) == ["number", "string"]

    assert get_in(approval_requirement_schema, [
             "properties",
             "activity_context",
             "properties",
             "source_event_provenance",
             "properties",
             "trust_boundary",
             "type"
           ]) == "string"

    assert get_in(approval_requirement_schema, [
             "properties",
             "activity_context",
             "properties",
             "score_terms",
             "additionalProperties",
             "type"
           ]) == "number"

    assert get_in(approval_requirement_schema, [
             "properties",
             "activity_context",
             "properties",
             "actual_data_rate_throughput_derivation",
             "properties",
             "actual_throughput_mb",
             "type"
           ]) == "number"

    assert get_in(approval_requirement_schema, [
             "properties",
             "activity_context",
             "properties",
             "source_window",
             "properties",
             "id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(approval_requirement_schema, [
             "properties",
             "activity_context",
             "properties",
             "source_window",
             "properties",
             "starts_at_s",
             "type"
           ]) == "number"

    assert get_in(approval_requirement_schema, [
             "properties",
             "activity_context",
             "properties",
             "candidate_diff_changed_field_count",
             "minimum"
           ]) == 0

    assert get_in(approval_requirement_schema, [
             "properties",
             "activity_context",
             "properties",
             "objective_type",
             "type"
           ]) == "string"

    assert get_in(approval_requirement_schema, [
             "properties",
             "activity_context",
             "properties",
             "station_calendar_reservation_overlap_count",
             "minimum"
           ]) == 0

    assert get_in(approval_requirement_schema, [
             "properties",
             "activity_context",
             "properties",
             "contact_success_factor",
             "maximum"
           ]) == 1.0

    assert get_in(approval_requirement_schema, [
             "properties",
             "activity_context",
             "properties",
             "blur_score",
             "maximum"
           ]) == 1.0

    assert get_in(approval_requirement_schema, [
             "properties",
             "activity_context",
             "properties",
             "storage_margin",
             "maximum"
           ]) == 1.0

    assert get_in(approval_requirement_schema, [
             "properties",
             "approval_rule_matches",
             "items",
             "properties",
             "rule_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert {:ok, policy_decision_schema} = Schema.json_schema("policy_decision.v1")
    assert {:ok, policy_bundle_schema} = Schema.json_schema("policy_bundle.v1")

    policy_decision_match_properties =
      get_in(policy_decision_schema, ["properties", "rule_matches", "items", "properties"])

    approval_requirement_match_properties =
      get_in(approval_requirement_schema, [
        "properties",
        "approval_rule_matches",
        "items",
        "properties"
      ])

    policy_action_rule_properties =
      get_in(policy_bundle_schema, [
        "properties",
        "approval_policy",
        "properties",
        "action_rules",
        "items",
        "properties"
      ])

    policy_context_array_fields = [
      "spacecraft_ids",
      "target_ids",
      "ground_station_ids",
      "directions",
      "station_availabilities",
      "station_contention_statuses",
      "station_reservation_ids",
      "station_reserved_bys",
      "station_reservation_statuses",
      "station_reservation_match_statuses",
      "station_calendar_reserved_bys",
      "station_calendar_reservation_statuses",
      "station_calendar_ambiguous_entry_ids",
      "station_calendar_trust_boundary_statuses",
      "station_calendar_directions",
      "resource_scopes",
      "selection_reasons",
      "selected_priority_sources",
      "resolution_statuses",
      "resolution_issues",
      "required_operator_actions",
      "operator_action_reasons",
      "allocation_statuses",
      "effective_allocation_statuses",
      "allocation_reasons",
      "suppressed_reasons",
      "resource_blocking_dimensions",
      "transition_decisions",
      "application_statuses",
      "planned_protection_decisions",
      "planned_protection_categories",
      "timeline_integrity_statuses",
      "source_timeline_integrity_statuses",
      "replacement_timeline_integrity_statuses",
      "source_protection_decisions",
      "source_protection_categories",
      "replacement_protection_decisions",
      "replacement_protection_categories",
      "resource_pressure_statuses",
      "resource_pressure_types",
      "resource_source_qualities",
      "resource_trust_boundaries",
      "resource_trust_boundary_statuses",
      "first_resource_pressure_kinds",
      "feedback_sources",
      "feedback_scopes",
      "trust_boundaries",
      "source_event_types"
    ]

    Enum.each(policy_context_array_fields, fn field ->
      assert Map.has_key?(policy_decision_match_properties, field)
      assert Map.has_key?(approval_requirement_match_properties, field)
      assert Map.has_key?(policy_action_rule_properties, field)
    end)

    Enum.each(
      [
        "station_calendar_provider_ids",
        "station_calendar_provider_entry_ids",
        "station_calendar_reservation_ids",
        "review_queues",
        "review_queue_keys"
      ],
      fn field ->
        assert Map.has_key?(policy_decision_match_properties, field)
        assert Map.has_key?(approval_requirement_match_properties, field)
        assert Map.has_key?(policy_action_rule_properties, field)
      end
    )

    assert get_in(policy_decision_match_properties, ["station_calendar_entry_ambiguous", "type"]) ==
             "boolean"

    assert get_in(policy_decision_match_properties, ["station_calendar_reserved_by", "type"]) == [
             "string",
             "array"
           ]

    assert get_in(policy_decision_match_properties, [
             "priority_fields_without_numeric_evidence_count",
             "type"
           ]) == "integer"

    Enum.each(
      [
        "max_concurrent_contacts",
        "overlap_contact_pair_count",
        "station_calendar_ambiguous_entry_count",
        "priority_fields_without_numeric_evidence_count"
      ],
      fn field ->
        assert get_in(policy_decision_match_properties, [field]) == %{
                 "type" => "integer",
                 "minimum" => 0
               }
      end
    )

    assert get_in(policy_action_rule_properties, ["capacity_fraction_min", "type"]) == "number"
    assert get_in(policy_action_rule_properties, ["capacity_fraction_max", "type"]) == "number"

    assert get_in(policy_action_rule_properties, [
             "station_calendar_ambiguous_entry_count_max",
             "type"
           ]) ==
             "integer"

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(repair["policy_decision"])

    assert {:ok, %{"schema_contract" => "strategy_recommendation.v1"}} =
             Schema.validate_artifact(strategy["recommendation"])

    invalid_decision = Map.put(repair["policy_decision"], "classification", "maybe")

    assert {:error, report} = Schema.validate_artifact(invalid_decision)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.classification"))

    invalid_rule_match_decision =
      repair["policy_decision"]
      |> Map.put("rule_matches", [
        %{
          "rule_id" => "bad rule id",
          "classification" => "maybe",
          "direction" => 42,
          "ground_station_id" => "equator_prime",
          "ground_station_ids" => [42],
          "station_contention_status" => 42,
          "station_reservation_status" => 42,
          "station_calendar_entry_ambiguous" => "false",
          "priority_fields_without_numeric_evidence_count" => "one",
          "max_concurrent_contacts" => 1.0,
          "overlap_contact_pair_count" => -1,
          "station_calendar_ambiguous_entry_count" => -1,
          "resource_pressure_statuses" => ["high", 42],
          "sla_s" => "soon"
        }
      ])
      |> Map.put("escalations", [
        %{
          "rule_id" => "bad escalation id",
          "classification" => "operator_review_required",
          "sla_s" => "later"
        }
      ])

    assert {:error, rule_match_report} = Schema.validate_artifact(invalid_rule_match_decision)

    assert Enum.any?(
             rule_match_report["errors"],
             &(&1["path"] == "$.rule_matches[0].rule_id")
           )

    assert Enum.any?(
             rule_match_report["errors"],
             &(&1["path"] == "$.rule_matches[0].classification")
           )

    assert Enum.any?(
             rule_match_report["errors"],
             &(&1["path"] == "$.rule_matches[0].direction")
           )

    assert Enum.any?(
             rule_match_report["errors"],
             &(&1["path"] == "$.rule_matches[0].station_contention_status")
           )

    assert Enum.any?(
             rule_match_report["errors"],
             &(&1["path"] == "$.rule_matches[0].station_reservation_status")
           )

    assert Enum.any?(
             rule_match_report["errors"],
             &(&1["path"] == "$.rule_matches[0].ground_station_ids[0]")
           )

    assert Enum.any?(
             rule_match_report["errors"],
             &(&1["path"] == "$.rule_matches[0].station_calendar_entry_ambiguous")
           )

    assert Enum.any?(
             rule_match_report["errors"],
             &(&1["path"] ==
                 "$.rule_matches[0].priority_fields_without_numeric_evidence_count")
           )

    assert Enum.any?(
             rule_match_report["errors"],
             &(&1["path"] == "$.rule_matches[0].max_concurrent_contacts")
           )

    assert Enum.any?(
             rule_match_report["errors"],
             &(&1["path"] == "$.rule_matches[0].overlap_contact_pair_count")
           )

    assert Enum.any?(
             rule_match_report["errors"],
             &(&1["path"] == "$.rule_matches[0].station_calendar_ambiguous_entry_count")
           )

    assert Enum.any?(
             rule_match_report["errors"],
             &(&1["path"] == "$.rule_matches[0].resource_pressure_statuses[1]")
           )

    assert Enum.any?(
             rule_match_report["errors"],
             &(&1["path"] == "$.rule_matches[0].sla_s")
           )

    assert Enum.any?(
             rule_match_report["errors"],
             &(&1["path"] == "$.escalations[0].rule_id")
           )

    assert Enum.any?(
             rule_match_report["errors"],
             &(&1["path"] == "$.escalations[0].sla_s")
           )
  end

  test "validates minimal V2 repair and V3 strategy contracts" do
    repair = repair_artifact()
    strategy = strategy_artifact(repair)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(repair)

    assert {:ok, %{"schema_contract" => "score_term_report.v1"}} =
             Schema.validate_artifact(repair["score_term_report"])

    assert {:ok, %{"schema_contract" => "objective_tradeoff_report.v1"}} =
             Schema.validate_artifact(repair["objective_tradeoff_report"])

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(repair["link_capacity_report"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3"}} =
             Schema.validate_artifact(strategy)

    invalid_strategy_event =
      put_in(strategy, ["branches", Access.at(0), "events"], [
        %{
          "type" => "contact_success_feedback",
          "trust_boundary" => ["operator_supplied"],
          "provenance" => "opaque",
          "feedback_sample_weight" => -1.0,
          "sample_weight" => "many",
          "confidence_weight" => "high",
          "feedback_sample_weight_source" => ["operator_sample_size"],
          "sample_weight_source" => 2,
          "confidence_weight_source" => false
        }
      ])

    assert {:error, invalid_strategy_event_report} =
             Schema.validate_artifact(invalid_strategy_event)

    for path <- [
          "$.branches[0].events[0].trust_boundary",
          "$.branches[0].events[0].provenance",
          "$.branches[0].events[0].feedback_sample_weight",
          "$.branches[0].events[0].sample_weight",
          "$.branches[0].events[0].confidence_weight",
          "$.branches[0].events[0].feedback_sample_weight_source",
          "$.branches[0].events[0].sample_weight_source",
          "$.branches[0].events[0].confidence_weight_source"
        ] do
      assert Enum.any?(invalid_strategy_event_report["errors"], &(&1["path"] == path))
    end

    assert {:ok, %{"schema_contract" => "ranking_comparison_report.v1"}} =
             Schema.validate_artifact(strategy["ranking_comparison_report"])

    assert {:ok, strategy_schema} = Schema.json_schema("campaign_strategy.v3")

    assert get_in(strategy_schema, ["properties", "ranking_comparison_report", "type"]) ==
             "object"

    branch_schema = get_in(strategy_schema, ["properties", "branches", "items"])

    assert branch_schema["required"] == [
             "branch_id",
             "probability",
             "events",
             "candidate_plan",
             "repair_result",
             "score",
             "score_terms",
             "warnings",
             "risk_indicators",
             "approval_status",
             "approval_requirements",
             "policy_decision"
           ]

    refute Map.has_key?(branch_schema["properties"], "id")

    assert get_in(branch_schema, ["properties", "branch_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(branch_schema, ["properties", "probability", "maximum"]) == 1.0

    assert get_in(branch_schema, ["properties", "score_terms", "additionalProperties", "type"]) ==
             "number"

    assert get_in(branch_schema, [
             "properties",
             "assumptions",
             "properties",
             "candidate_source",
             "properties",
             "refresh_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(branch_schema, [
             "properties",
             "provenance",
             "properties",
             "candidate_source",
             "properties",
             "source_report_input_paths",
             "items",
             "type"
           ]) == "string"

    invalid_repair =
      Map.put(repair, "source_station_calendar_report", %{
        "schema_contract" => "station_calendar_report.v1"
      })

    assert {:error, invalid_repair_report} = Schema.validate_artifact(invalid_repair)

    assert Enum.any?(
             invalid_repair_report["errors"],
             &(&1["path"] == "$.source_station_calendar_report.model")
           )
  end

  defp campaign_artifact do
    result_set =
      ResultSet.new!(%{
        study_id: :campaign,
        trajectory_results: [],
        event_results: [
          %{
            scenario_id: :leo_1,
            event_type: :ground_station_access,
            events: [
              %{
                type: :ground_station_access,
                starts_at: Epoch.new!(100.0, :tdb),
                ends_at: Epoch.new!(160.0, :tdb),
                metadata: %{
                  max_elevation_deg: 45.0,
                  minimum_elevation_deg: 5.0
                }
              }
            ],
            source: %{ground_station_id: :equator_prime}
          }
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    CampaignPlanner.build(result_set,
      generated_at: ~U[2026-05-14 00:00:00Z],
      campaign: %{
        "planning_horizon" => %{"duration_s" => 600.0},
        "constraints" => %{},
        "scoring_policy" => %{"downlink_rate_mb_s" => 2.0}
      }
    )
  end

  defp repair_artifact do
    CampaignPlanner.repair(%{
      prior_plan: campaign_artifact(),
      realized_state: %{activities: []},
      current_epoch_s: 0.0,
      remaining_horizon: %{"starts_at_s" => 0.0, "ends_at_s" => 600.0},
      generated_at: ~U[2026-05-14 00:00:00Z]
    })
  end

  defp strategy_artifact(repair) do
    CampaignPlanner.strategy(%{
      prior_plan: repair,
      mission_state: %{snapshot_id: "ops-snapshot"},
      branches: [
        %{id: "baseline"},
        %{id: "fuel", events: [%{type: "fuel_preservation_mode"}]}
      ],
      current_epoch_s: 0.0,
      remaining_horizon: %{"starts_at_s" => 0.0, "ends_at_s" => 600.0},
      generated_at: ~U[2026-05-14 00:00:00Z]
    })
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
