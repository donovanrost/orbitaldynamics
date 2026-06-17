defmodule OrbitalDynamics.Schema.CommunicationsContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CampaignPlanner,
    Communications.ContactContention,
    Communications.LinkCapacity,
    Epoch,
    ResultSet,
    Schema,
    Validation
  }

  test "validates generated V1 campaign artifacts and proposed contact contracts" do
    artifact = campaign_artifact()

    assert {:ok, report} = Schema.validate_artifact(artifact)
    assert report["schema_contract"] == "campaign_plan.v1"
    assert report["status"] == "pass"

    assert [
             %{
               "direction" => "downlink",
               "estimated_throughput_mb" => 120.0,
               "station_availability" => "available",
               "schedule_conflict_status" => "not_evaluated",
               "cadence_import" => %{"schema_contract" => "proposed_contact.v1"}
             }
           ] = artifact["proposed_contacts"]

    assert [
             %{
               "schema_contract" => "contact_intent.v1",
               "activity_id" => _activity_id,
               "direction" => "downlink",
               "timeline_id" => _timeline_id,
               "timeline_identity" => %{"timeline_id" => _}
             }
           ] = artifact["contact_intents"]

    assert %{
             "schema_contract" => "contact_filter_report.v1",
             "model" => "thin_ground_network_availability_filter",
             "input_candidate_count" => 1,
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 0,
             "suppressed_candidates" => []
           } = artifact["contact_filter_report"]

    assert %{
             "schema_contract" => "contact_contention_report.v1",
             "model" => "single_station_interval_overlap",
             "input_contact_count" => 1,
             "conflicted_contact_count" => 0,
             "conflict_group_count" => 0,
             "conflict_groups" => []
           } = artifact["contact_contention_report"]

    assert %{
             "schema_contract" => "contact_contention_resolution_report.v1",
             "model" => "deterministic_contact_contention_recommendation",
             "conflict_group_count" => 0,
             "recommendation_count" => 0,
             "recommendations" => []
           } = artifact["contact_contention_resolution_report"]

    assert %{
             "schema_contract" => "station_calendar_report.v1",
             "model" => "campaign_ground_network_interval_overlay",
             "input_contact_count" => 1,
             "calendar_entry_count" => 0,
             "affected_contact_count" => 0,
             "affected_contacts" => []
           } = artifact["station_calendar_report"]

    assert %{
             "schema_contract" => "objective_tradeoff_report.v1",
             "model" => "ranked_timeline_score_term_tradeoffs",
             "ranking_count" => 1,
             "tradeoffs" => [
               %{
                 "rank" => 1,
                 "scenario_id" => "leo_1",
                 "score_delta_from_selected" => schema_delta,
                 "activity_ids" => [_activity_id]
               }
             ]
           } = artifact["objective_tradeoff_report"]

    assert schema_delta == 0.0
    assert [] = artifact["target_commitments"]
  end

  test "validates standalone contact contention report contracts" do
    contention_report = %{
      "schema_contract" => "contact_contention_report.v1",
      "model" => "single_station_interval_overlap",
      "input_contact_count" => 2,
      "conflicted_contact_count" => 2,
      "conflict_group_count" => 1,
      "conflict_groups" => [
        %{
          "id" => "station:equator_prime:contention:1",
          "ground_station_id" => "equator_prime",
          "contact_count" => 2,
          "starts_at_s" => 100.0,
          "ends_at_s" => 220.0,
          "direction" => "downlink",
          "required_operator_action" => "review_contact_contention",
          "approval_status" => "operator_review_required",
          "operator_action_reason" => "same_station_overlapping_contact_windows",
          "contact_ids" => ["dl_1", "dl_2"],
          "source_window_ids" => [
            "window:leo_1:ground_station_access:equator_prime:1",
            "window:leo_2:ground_station_access:equator_prime:1"
          ],
          "scenario_ids" => ["leo_1", "leo_2"]
        }
      ],
      "provenance" => %{"source" => "schema_test"},
      "assumptions" => %{"resolution" => "report_only_no_candidate_suppression"}
    }

    resolution_report = %{
      "schema_contract" => "contact_contention_resolution_report.v1",
      "model" => "deterministic_contact_contention_recommendation",
      "policy" => %{
        "selection_rule" => "highest_score_earliest_start",
        "priority_fields" => ["missing_priority", "priority"],
        "requested_priority_fields" => ["missing_priority", "priority"]
      },
      "conflict_group_count" => 1,
      "recommendation_count" => 1,
      "recommendations" => [
        %{
          "group_id" => "station:equator_prime:contention:1",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 100.0,
          "ends_at_s" => 220.0,
          "selected_contact_id" => "dl_1",
          "selected_scenario_id" => "leo_1",
          "deferred_contact_ids" => ["dl_2"],
          "candidate_count" => 2,
          "selection_reason" => "highest_score_earliest_start",
          "resolution_priority_fields" => ["missing_priority", "priority"],
          "requested_priority_fields" => ["missing_priority", "priority"],
          "priority_field_evidence_counts" => %{
            "missing_priority" => 0,
            "priority" => 1
          },
          "priority_fields_without_numeric_evidence_count" => 1,
          "priority_fields_without_numeric_evidence" => ["missing_priority"],
          "action" => "recommend_preferred_contact_for_operator_review",
          "review_status" => "operator_review_required"
        }
      ],
      "assumptions" => %{"boundary" => "recommendation_only_no_station_reservation"}
    }

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(contention_report)

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution_report)

    invalid_contention_input_count =
      Map.put(contention_report, "input_contact_count", 1.0)

    assert {:error, report} = Schema.validate_artifact(invalid_contention_input_count)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.input_contact_count"))

    invalid_contention_optional_count =
      Map.put(contention_report, "invalid_contact_input_count", -1)

    assert {:error, report} = Schema.validate_artifact(invalid_contention_optional_count)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.invalid_contact_input_count"))

    invalid_contention_group_count =
      put_in(contention_report, ["conflict_groups", Access.at(0), "contact_count"], 1.0)

    assert {:error, report} = Schema.validate_artifact(invalid_contention_group_count)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.conflict_groups[0].contact_count"))

    invalid_resolution_count =
      Map.put(resolution_report, "recommendation_count", -1)

    assert {:error, report} = Schema.validate_artifact(invalid_resolution_count)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.recommendation_count"))

    invalid_resolution_candidate_count =
      put_in(resolution_report, ["recommendations", Access.at(0), "candidate_count"], 1.0)

    assert {:error, report} = Schema.validate_artifact(invalid_resolution_candidate_count)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.recommendations[0].candidate_count"))

    invalid_contention =
      put_in(contention_report, ["conflict_groups", Access.at(0), "id"], "bad id")

    assert {:error, report} = Schema.validate_artifact(invalid_contention)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.conflict_groups[0].id"))

    invalid_resolution =
      put_in(
        resolution_report,
        ["recommendations", Access.at(0), "selected_contact_id"],
        "bad id"
      )

    assert {:error, report} = Schema.validate_artifact(invalid_resolution)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.recommendations[0].selected_contact_id")
           )

    invalid_priority_evidence =
      put_in(
        resolution_report,
        ["recommendations", Access.at(0), "priority_field_evidence_counts", "priority"],
        -1
      )

    assert {:error, report} = Schema.validate_artifact(invalid_priority_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.recommendations[0].priority_field_evidence_counts.priority")
           )

    invalid_missing_priority_count =
      put_in(
        resolution_report,
        ["recommendations", Access.at(0), "priority_fields_without_numeric_evidence_count"],
        -1
      )

    assert {:error, report} = Schema.validate_artifact(invalid_missing_priority_count)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] ==
                 "$.recommendations[0].priority_fields_without_numeric_evidence_count")
           )
  end

  test "validates checked-in station provider and contention examples" do
    station_provider = read_json!("study_results/station_calendar_provider_v1.json")
    contention_report = read_json!("study_results/contact_contention_report_v1.json")

    resolution_report =
      read_json!("study_results/contact_contention_resolution_report_v1.json")

    assert {:ok, %{"schema_contract" => "station_calendar_provider.v1"}} =
             Schema.validate_artifact(station_provider)

    provider_with_direction_aliases =
      update_in(station_provider, ["entries", Access.at(0)], fn entry ->
        Map.merge(entry, %{
          "direction" => "tracking",
          "directions" => ["tracking", "health_check"],
          "station_calendar_directions" => ["tracking"]
        })
      end)

    assert {:ok, %{"schema_contract" => "station_calendar_provider.v1"}} =
             Schema.validate_artifact(provider_with_direction_aliases)

    invalid_provider_direction_alias =
      put_in(provider_with_direction_aliases, ["entries", Access.at(0), "directions"], [
        "tracking",
        42
      ])

    assert {:error, invalid_provider_direction_report} =
             Schema.validate_artifact(invalid_provider_direction_alias)

    assert Enum.any?(
             invalid_provider_direction_report["errors"],
             &(&1["path"] == "$.entries[0].directions[1]")
           )

    assert %{
             "id" => "declared_ground_network_demo",
             "entries" => [
               %{"ground_station_id" => "equator_prime", "availability" => "maintenance"},
               %{
                 "ground_station_id" => "equator_prime",
                 "availability" => "reserved",
                 "reservation_id" => "reservation_equator_prime_1"
               }
             ]
           } = station_provider

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(contention_report)

    expected_contention_assumptions = contact_contention_report_capability_assumptions()

    assert Map.take(
             contention_report["assumptions"],
             Map.keys(expected_contention_assumptions)
           ) == expected_contention_assumptions

    assert {:ok, contention_schema} = Schema.json_schema("contact_contention_report.v1")

    for {field, value} <- expected_contention_assumptions do
      assert get_in(contention_schema, [
               "properties",
               "assumptions",
               "properties",
               field,
               "const"
             ]) == value
    end

    assert get_in(contention_schema, ["properties", "model_limits", "items", "enum"]) == [
             "artifact_level_only",
             "no_provider_reservation",
             "no_candidate_suppression",
             "no_schedule_mutation",
             "no_link_budget_model"
           ]

    assert get_in(contention_schema, ["properties", "provenance", "type"]) == "object"

    assert get_in(contention_schema, ["properties", "duplicate_contact_id_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    group_schema = get_in(contention_schema, ["properties", "conflict_groups", "items"])

    assert get_in(group_schema, ["properties", "contact_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(group_schema, [
             "properties",
             "actual_data_rate_throughput_derivations",
             "items",
             "type"
           ]) == "object"

    assert get_in(group_schema, ["properties", "resource_scope", "type"]) == "string"
    assert get_in(group_schema, ["properties", "direction", "type"]) == "string"

    assert get_in(group_schema, ["properties", "directions", "items", "type"]) ==
             "string"

    for field <- ["ground_station_ids", "spacecraft_ids", "duplicate_contact_ids"] do
      assert get_in(group_schema, ["properties", field, "items", "pattern"]) ==
               Schema.identity_policy()["stable_id_pattern"]
    end

    assert get_in(group_schema, ["properties", "spacecraft_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(group_schema, [
             "properties",
             "duplicate_contact_candidate_count",
             "minimum"
           ]) == 0

    assert get_in(group_schema, [
             "properties",
             "duplicate_contact_id_count",
             "minimum"
           ]) == 0

    source_candidate_schema =
      get_in(group_schema, ["properties", "source_contact_candidates", "items"])

    assert get_in(source_candidate_schema, ["properties", "id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(source_candidate_schema, ["properties", "source_window_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(source_candidate_schema, ["properties", "spacecraft_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    invalid_contention_limits =
      Map.put(contention_report, "model_limits", ["artifact_level_only"])

    assert {:error, contention_limits_report} =
             Schema.validate_artifact(invalid_contention_limits)

    assert Enum.any?(contention_limits_report["errors"], &(&1["path"] == "$.model_limits"))

    invalid_contention_duplicate_count =
      Map.put(contention_report, "duplicate_contact_candidate_count", 99)

    assert {:error, contention_duplicate_count_report} =
             Schema.validate_artifact(invalid_contention_duplicate_count)

    assert Enum.any?(
             contention_duplicate_count_report["errors"],
             &(&1["path"] == "$.duplicate_contact_candidate_count")
           )

    invalid_group_station_id =
      put_in(contention_report, ["conflict_groups", Access.at(0), "ground_station_ids"], [
        "bad id"
      ])

    assert {:error, group_station_id_report} = Schema.validate_artifact(invalid_group_station_id)

    assert Enum.any?(
             group_station_id_report["errors"],
             &(&1["path"] == "$.conflict_groups[0].ground_station_ids[0]")
           )

    invalid_group_duplicate_id_count =
      put_in(
        contention_report,
        ["conflict_groups", Access.at(0), "duplicate_contact_id_count"],
        -1
      )

    assert {:error, group_duplicate_id_count_report} =
             Schema.validate_artifact(invalid_group_duplicate_id_count)

    assert Enum.any?(
             group_duplicate_id_count_report["errors"],
             &(&1["path"] == "$.conflict_groups[0].duplicate_contact_id_count")
           )

    invalid_group_source_candidate_id =
      put_in(
        contention_report,
        ["conflict_groups", Access.at(1), "source_contact_candidates", Access.at(0), "id"],
        "bad id"
      )

    assert {:error, group_source_candidate_id_report} =
             Schema.validate_artifact(invalid_group_source_candidate_id)

    assert Enum.any?(
             group_source_candidate_id_report["errors"],
             &(&1["path"] == "$.conflict_groups[1].source_contact_candidates[0].id")
           )

    assert %{
             "conflict_group_count" => 2,
             "conflict_groups" => [
               %{
                 "id" => "station:equator_prime:contention:1",
                 "direction" => "downlink",
                 "required_operator_action" => "review_contact_contention",
                 "approval_status" => "operator_review_required",
                 "contact_ids" => ["dl_1", "dl_2"]
               },
               %{
                 "id" => "spacecraft:sat_1:contention:1",
                 "resource_scope" => "spacecraft",
                 "contact_ids" => ["dl_3", "dl_4"]
               }
             ]
           } = contention_report

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution_report)

    assert {:ok, resolution_schema} =
             Schema.json_schema("contact_contention_resolution_report.v1")

    assert get_in(resolution_schema, ["properties", "model_limits", "items", "enum"]) == [
             "artifact_level_only",
             "no_provider_reservation",
             "no_candidate_suppression",
             "no_schedule_mutation",
             "no_link_budget_model"
           ]

    recommendation_schema = get_in(resolution_schema, ["properties", "recommendations", "items"])

    assert get_in(resolution_schema, ["properties", "recommendation_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(recommendation_schema, ["properties", "candidate_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(recommendation_schema, [
             "properties",
             "actual_data_rate_throughput_derivations",
             "items",
             "type"
           ]) == "object"

    assert get_in(recommendation_schema, ["properties", "resource_scope", "type"]) == "string"
    assert get_in(recommendation_schema, ["properties", "direction", "type"]) == "string"

    assert get_in(recommendation_schema, ["properties", "directions", "items", "type"]) ==
             "string"

    for field <- ["ground_station_ids", "spacecraft_ids"] do
      assert get_in(recommendation_schema, ["properties", field, "items", "pattern"]) ==
               Schema.identity_policy()["stable_id_pattern"]
    end

    assert get_in(recommendation_schema, ["properties", "spacecraft_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    source_candidate_schema =
      get_in(recommendation_schema, ["properties", "source_contact_candidates", "items"])

    assert get_in(source_candidate_schema, ["properties", "id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(source_candidate_schema, ["properties", "source_window_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(source_candidate_schema, ["properties", "direction", "type"]) == "string"
    assert get_in(source_candidate_schema, ["properties", "score", "type"]) == "number"

    invalid_resolution_limits =
      Map.put(resolution_report, "model_limits", ["artifact_level_only"])

    assert {:error, resolution_limits_report} =
             Schema.validate_artifact(invalid_resolution_limits)

    assert Enum.any?(resolution_limits_report["errors"], &(&1["path"] == "$.model_limits"))

    invalid_recommendation_station_id =
      put_in(
        resolution_report,
        ["recommendations", Access.at(0), "ground_station_ids"],
        ["bad id"]
      )

    assert {:error, recommendation_station_id_report} =
             Schema.validate_artifact(invalid_recommendation_station_id)

    assert Enum.any?(
             recommendation_station_id_report["errors"],
             &(&1["path"] == "$.recommendations[0].ground_station_ids[0]")
           )

    invalid_source_candidate_id =
      put_in(
        resolution_report,
        ["recommendations", Access.at(0), "source_contact_candidates", Access.at(0), "id"],
        "bad id"
      )

    assert {:error, source_candidate_id_report} =
             Schema.validate_artifact(invalid_source_candidate_id)

    assert Enum.any?(
             source_candidate_id_report["errors"],
             &(&1["path"] == "$.recommendations[0].source_contact_candidates[0].id")
           )

    assert %{
             "recommendation_count" => 2,
             "recommendations" => [
               %{
                 "group_id" => "station:equator_prime:contention:1",
                 "selected_contact_id" => "dl_1",
                 "review_status" => "operator_review_required"
               },
               %{
                 "group_id" => "spacecraft:sat_1:contention:1",
                 "selected_contact_id" => "dl_3",
                 "review_status" => "operator_review_required"
               }
             ]
           } = resolution_report
  end

  test "validates checked-in contact contention resolution summary fixture" do
    resolution_report =
      read_json!("study_results/contact_contention_resolution_report_v1.json")

    summary = read_json!("study_results/contact_contention_resolution_summary_v1.json")

    generated_summary =
      OrbitalDynamics.contact_contention_resolution_summary(resolution_report)

    assert generated_summary == summary

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert %{
             "source_artifact_type" => "contact_contention_resolution_report.v1",
             "conflict_group_count" => 2,
             "recommendation_count" => 2,
             "recommendation_group_ids" => [
               "spacecraft:sat_1:contention:1",
               "station:equator_prime:contention:1"
             ],
             "review_group_ids" => [
               "spacecraft:sat_1:contention:1",
               "station:equator_prime:contention:1"
             ],
             "selected_contact_ids" => ["dl_1", "dl_3"],
             "selected_contact_ids_by_group_id" => %{
               "spacecraft:sat_1:contention:1" => ["dl_3"],
               "station:equator_prime:contention:1" => ["dl_1"]
             },
             "deferred_contact_ids" => ["dl_2", "dl_4"],
             "deferred_contact_ids_by_group_id" => %{
               "spacecraft:sat_1:contention:1" => ["dl_4"],
               "station:equator_prime:contention:1" => ["dl_2"]
             },
             "review_contact_ids" => ["dl_1", "dl_2", "dl_3", "dl_4"],
             "review_contact_ids_by_group_id" => %{
               "spacecraft:sat_1:contention:1" => ["dl_3", "dl_4"],
               "station:equator_prime:contention:1" => ["dl_1", "dl_2"]
             },
             "review_recommendation_count" => 2,
             "resource_scope_counts" => %{"ground_station" => 1, "spacecraft" => 1},
             "selected_contact_ids_by_resource_scope" => %{
               "ground_station" => ["dl_1"],
               "spacecraft" => ["dl_3"]
             },
             "deferred_contact_ids_by_resource_scope" => %{
               "ground_station" => ["dl_2"],
               "spacecraft" => ["dl_4"]
             },
             "review_contact_ids_by_resource_scope" => %{
               "ground_station" => ["dl_1", "dl_2"],
               "spacecraft" => ["dl_3", "dl_4"]
             },
             "selection_reason_counts" => %{"highest_score_earliest_start" => 2},
             "selected_contact_ids_by_selection_reason" => %{
               "highest_score_earliest_start" => ["dl_1", "dl_3"]
             },
             "action_counts" => %{"recommend_preferred_contact_for_operator_review" => 2},
             "review_contact_ids_by_action" => %{
               "recommend_preferred_contact_for_operator_review" => [
                 "dl_1",
                 "dl_2",
                 "dl_3",
                 "dl_4"
               ]
             },
             "assumptions" => %{
               "candidate_mutation" => "none",
               "execution_boundary" =>
                 "artifact_only_no_provider_reservation_or_schedule_mutation",
               "operator_authority" => "not_granted_by_summary",
               "source" => "contact_contention_resolution_report.v1"
             }
           } = summary

    assert summary["model_limits"] == [
             "artifact_level_only",
             "no_provider_reservation",
             "no_candidate_suppression",
             "no_schedule_mutation",
             "no_link_budget_model"
           ]
  end

  test "validates checked-in cross-station contact contention challenge fixture" do
    report = read_json!("study_results/contact_contention_cross_station_spacecraft_v1.json")

    contacts = [
      %{
        id: :dl_equator,
        type: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        score: 8.0
      },
      %{
        id: :dl_dsn,
        type: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_1,
        ground_station_id: :deep_space_net,
        starts_at_s: 120.0,
        ends_at_s: 170.0,
        score: 10.0
      },
      %{
        id: :dl_other_spacecraft,
        type: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_2,
        ground_station_id: :polar_aux,
        starts_at_s: 125.0,
        ends_at_s: 155.0,
        score: 7.0
      }
    ]

    generated_report =
      OrbitalDynamics.contact_contention_report(
        contacts,
        source: "generated_cross_station_spacecraft_contention_fixture"
      )

    assert generated_report == report

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "schema_contract" => "contact_contention_report.v1",
             "model" => "single_station_interval_overlap",
             "input_contact_count" => 3,
             "conflict_group_count" => 1,
             "conflicted_contact_count" => 2,
             "duplicate_contact_candidate_count" => 0,
             "invalid_contact_input_count" => 0,
             "model_limits" => [
               "artifact_level_only",
               "no_provider_reservation",
               "no_candidate_suppression",
               "no_schedule_mutation",
               "no_link_budget_model"
             ],
             "conflict_groups" => [
               %{
                 "id" => "spacecraft:sat_1:contention:1",
                 "resource_scope" => "spacecraft",
                 "ground_station_id" => "multi_station",
                 "ground_station_ids" => ["deep_space_net", "equator_prime"],
                 "spacecraft_id" => "sat_1",
                 "spacecraft_ids" => ["sat_1"],
                 "contact_ids" => ["dl_equator", "dl_dsn"],
                 "direction" => "downlink",
                 "directions" => ["downlink"],
                 "required_operator_action" => "review_contact_contention",
                 "operator_action_reason" => "same_spacecraft_overlapping_contact_windows",
                 "approval_status" => "operator_review_required",
                 "contention_window_s" => 70.0,
                 "overlap_duration_s" => 40.0,
                 "max_concurrent_contacts" => 2,
                 "overlap_contact_pair_count" => 1
               }
             ],
             "assumptions" => %{
               "resolution" => "report_only_no_candidate_suppression"
             }
           } = report

    assert %{
             "resource_scope_counts" => %{"spacecraft" => 1},
             "conflict_group_ids_by_resource_scope" => %{
               "spacecraft" => ["spacecraft:sat_1:contention:1"]
             },
             "required_operator_action_counts" => %{
               "review_contact_contention" => 1
             }
           } = Validation.artifact_observations("contact_contention_report.v1", report)
  end

  test "validates checked-in contact intent summary fixture" do
    summary = read_json!("study_results/contact_intent_summary_v1.json")

    activities = [
      %{
        id: :direct_capacity_contact,
        type: :planned_contact,
        direction: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 10.0,
        ends_at_s: 70.0,
        required_capacity_fraction: "0.25"
      },
      %{
        id: :throughput_capacity_contact,
        type: :planned_contact,
        direction: :command,
        scenario_id: :leo_1,
        ground_station_id: :dss_43,
        starts_at_s: 80.0,
        ends_at_s: 120.0,
        throughput_model: %{required_station_capacity_percent: "50"}
      },
      %{
        id: :capacity_model_contact,
        type: :planned_contact,
        direction: :tracking,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 130.0,
        ends_at_s: 170.0,
        capacity_model: %{station_capacity_requirement: 0.2}
      }
    ]

    generated_summary =
      OrbitalDynamics.contact_intent_summary(
        activities,
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert generated_summary == summary

    assert {:ok, %{"schema_contract" => "contact_intent_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert %{
             "source_artifact_type" => "contact_intent.v1",
             "contact_intent_count" => 3,
             "capacity_pack_required_contact_count" => 3,
             "capacity_pack_required_capacity_fraction" => 0.95,
             "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
               "dss_43" => 0.5,
               "equator_prime" => 0.45
             },
             "capacity_pack_required_capacity_fraction_by_direction" => %{
               "command" => 0.5,
               "downlink" => 0.25,
               "tracking" => 0.2
             },
             "capacity_pack_required_capacity_fraction_by_direction_and_ground_station_id" => %{
               "command" => %{"dss_43" => 0.5},
               "downlink" => %{"equator_prime" => 0.25},
               "tracking" => %{"equator_prime" => 0.2}
             },
             "required_capacity_fraction_source_counts" => %{
               "capacity_model" => 1,
               "contact_required_capacity_fraction" => 1,
               "throughput_model" => 1
             },
             "required_capacity_fraction_contact_ids_by_source" => %{
               "capacity_model" => ["capacity_model_contact"],
               "contact_required_capacity_fraction" => ["direct_capacity_contact"],
               "throughput_model" => ["throughput_capacity_contact"]
             },
             "contact_ids_by_ground_station_id" => %{
               "dss_43" => ["throughput_capacity_contact"],
               "equator_prime" => ["capacity_model_contact", "direct_capacity_contact"]
             },
             "contact_ids_by_direction" => %{
               "command" => ["throughput_capacity_contact"],
               "downlink" => ["direct_capacity_contact"],
               "tracking" => ["capacity_model_contact"]
             },
             "contact_ids_by_direction_and_ground_station_id" => %{
               "command" => %{"dss_43" => ["throughput_capacity_contact"]},
               "downlink" => %{"equator_prime" => ["direct_capacity_contact"]},
               "tracking" => %{"equator_prime" => ["capacity_model_contact"]}
             },
             "capacity_pack_contact_ids_by_ground_station_id" => %{
               "dss_43" => ["throughput_capacity_contact"],
               "equator_prime" => ["capacity_model_contact", "direct_capacity_contact"]
             },
             "capacity_pack_contact_ids_by_direction" => %{
               "command" => ["throughput_capacity_contact"],
               "downlink" => ["direct_capacity_contact"],
               "tracking" => ["capacity_model_contact"]
             },
             "capacity_pack_contact_ids_by_direction_and_ground_station_id" => %{
               "command" => %{"dss_43" => ["throughput_capacity_contact"]},
               "downlink" => %{"equator_prime" => ["direct_capacity_contact"]},
               "tracking" => %{"equator_prime" => ["capacity_model_contact"]}
             },
             "ground_station_ids" => ["dss_43", "equator_prime"],
             "directions" => ["command", "downlink", "tracking"],
             "direction_counts" => %{"command" => 1, "downlink" => 1, "tracking" => 1},
             "assumptions" => %{
               "execution_boundary" =>
                 "artifact_only_no_provider_reservation_or_schedule_mutation",
               "source_artifact_type" => "contact_intent.v1"
             }
           } = summary

    assert get_in(summary, [
             "direction_routing",
             "downlink",
             "capacity_pack_required_capacity_fraction"
           ]) == 0.25

    assert summary["model_limits"] == [
             "no_command_execution",
             "no_link_budget_model",
             "no_provider_reservation",
             "no_schedule_mutation",
             "station_availability_is_declared_or_not_evaluated"
           ]
  end

  test "validates checked-in link capacity summary fixture" do
    summary = read_json!("study_results/link_capacity_summary_v1.json")

    contacts = [
      %{
        id: :science_downlink,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        planned_data_volume_mb: 120.0
      }
    ]

    selected_contacts = [
      %{
        id: :science_downlink,
        type: :downlink,
        ground_station_id: :equator_prime,
        actual_data_volume_mb: 90.0
      }
    ]

    generated_summary =
      OrbitalDynamics.link_capacity_summary(
        contacts,
        selected_contacts,
        policy: %{required_downlink_mb_by_ground_station: %{equator_prime: 100.0}},
        source: "timeline_feedback"
      )

    assert generated_summary == summary

    assert {:ok, %{"schema_contract" => "link_capacity_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert %{
             "source_artifact_type" => "link_capacity_report.v1",
             "source" => "timeline_feedback",
             "station_count" => 1,
             "contact_count" => 1,
             "effective_contact_count" => 1,
             "ignored_contact_count" => 0,
             "selected_contact_count" => 1,
             "ignored_selected_contact_count" => 0,
             "required_downlink_contact_count" => 0,
             "actual_throughput_contact_count" => 1,
             "actual_completion_contact_count" => 0,
             "invalid_contact_input_count" => 0,
             "invalid_selected_contact_input_count" => 0,
             "invalid_policy_required_downlink_station_count" => 0,
             "downlink_requirement_status" => "satisfied",
             "actual_downlink_requirement_status" => "shortfall",
             "selected_downlink_shortfall_mb" => +0.0,
             "actual_downlink_shortfall_mb" => 10.0,
             "capacity_adjusted_throughput_mb" => 120.0,
             "selected_capacity_adjusted_throughput_mb" => 120.0,
             "unused_capacity_adjusted_throughput_mb" => +0.0,
             "contact_ids" => ["science_downlink"],
             "selected_contact_ids" => ["science_downlink"],
             "ignored_contact_ids" => [],
             "ignored_selected_contact_ids" => [],
             "required_downlink_contact_ids" => [],
             "actual_throughput_contact_ids" => ["science_downlink"],
             "actual_completion_contact_ids" => [],
             "ground_station_ids" => ["equator_prime"],
             "shortfall_ground_station_ids" => [],
             "actual_shortfall_ground_station_ids" => ["equator_prime"],
             "selected_downlink_shortfall_mb_by_ground_station_id" => %{
               "equator_prime" => +0.0
             },
             "actual_downlink_shortfall_mb_by_ground_station_id" => %{
               "equator_prime" => 10.0
             },
             "selected_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["science_downlink"]
             },
             "capacity_adjusted_throughput_mb_by_ground_station_id" => %{
               "equator_prime" => 120.0
             },
             "selected_capacity_adjusted_throughput_mb_by_ground_station_id" => %{
               "equator_prime" => 120.0
             },
             "unused_capacity_adjusted_throughput_mb_by_ground_station_id" => %{
               "equator_prime" => +0.0
             },
             "actual_throughput_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["science_downlink"]
             },
             "actual_completion_contact_ids_by_ground_station_id" => %{},
             "assumptions" => %{
               "execution_boundary" =>
                 "artifact_only_no_provider_reservation_or_schedule_mutation",
               "operator_authority" => "not_granted_by_summary",
               "source" => "link_capacity_report.v1"
             }
           } = summary

    assert summary["model_limits"] ==
             LinkCapacity.capabilities()
             |> Map.fetch!(:known_limits)
             |> Enum.map(&to_string/1)
  end

  test "validates checked-in relay data-path summary fixture" do
    summary = read_json!("study_results/relay_data_path_summary_v1.json")

    generated_summary =
      OrbitalDynamics.relay_data_path_summary(summary["rows"], source: summary["source"])

    assert generated_summary == summary

    assert {:ok, %{"schema_contract" => "relay_data_path_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert %{
             "schema_contract" => "relay_data_path_summary.v1",
             "schema_version" => 1,
             "model" => "artifact_only_relay_data_path_summary",
             "source" => "relay_ops",
             "route_count" => 2,
             "relay_route_count" => 1,
             "direct_downlink_route_count" => 1,
             "custody_status_counts" => %{"confirmed" => 1, "missing_ack" => 1},
             "latency_status_counts" => %{"exceeds_limit" => 1, "within_limit" => 1},
             "risk_status_counts" => %{"high" => 1, "nominal" => 1},
             "route_ids" => [relay_route_id, "route_direct"],
             "source_spacecraft_ids" => ["sat_a", "sat_b"],
             "relay_spacecraft_ids" => ["relay_1", "relay_2"],
             "ground_station_ids" => ["dss_14", "dss_35"],
             "ground_downlink_contact_ids" => ["downlink_1", "downlink_2"],
             "route_ids_by_custody_status" => %{
               "confirmed" => [relay_route_id],
               "missing_ack" => ["route_direct"]
             },
             "route_ids_by_latency_status" => %{
               "exceeds_limit" => ["route_direct"],
               "within_limit" => [relay_route_id]
             },
             "route_ids_by_risk_status" => %{
               "high" => ["route_direct"],
               "nominal" => [relay_route_id]
             },
             "route_ids_by_ground_station_id" => %{
               "dss_14" => [relay_route_id],
               "dss_35" => ["route_direct"]
             },
             "maximum_latency_s" => 500.0,
             "maximum_latency_limit_s" => 300.0,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_relay_scheduling_or_schedule_mutation",
               "crosslink_visibility_model" => "not_evaluated",
               "custody_acknowledgement_delivery" => "not_performed",
               "provider_reservation" => "not_performed",
               "operator_authority" => "not_granted_by_summary"
             },
             "rows" => [
               %{
                 "route_id" => relay_route_id,
                 "source_spacecraft_id" => "sat_a",
                 "relay_chain_spacecraft_ids" => ["relay_2", "relay_1"],
                 "relay_hop_count" => 2,
                 "ground_station_id" => "dss_14",
                 "ground_downlink_contact_id" => "downlink_1",
                 "custody_status" => "confirmed",
                 "latency_s" => 180.0,
                 "latency_limit_s" => 240.0,
                 "latency_status" => "within_limit",
                 "risk_status" => "nominal",
                 "risk_reasons" => [],
                 "product_ids" => ["image_alpha"],
                 "collection_ids" => ["collection_alpha"]
               },
               %{
                 "route_id" => "route_direct",
                 "source_spacecraft_id" => "sat_b",
                 "relay_chain_spacecraft_ids" => [],
                 "relay_hop_count" => 0,
                 "ground_station_id" => "dss_35",
                 "ground_downlink_contact_id" => "downlink_2",
                 "custody_status" => "missing_ack",
                 "latency_s" => 500.0,
                 "latency_limit_s" => 300.0,
                 "latency_status" => "exceeds_limit",
                 "risk_status" => "high",
                 "risk_reasons" => [
                   "custody_missing_ack",
                   "latency_exceeds_limit",
                   "operator review queued"
                 ],
                 "product_ids" => ["image_beta"],
                 "collection_ids" => []
               }
             ]
           } = summary

    assert String.starts_with?(relay_route_id, "relay_data_path:sat_a:downlink_1:")
    assert relay_route_id =~ ~r/^relay_data_path:sat_a:downlink_1:[0-9a-f]{12}$/
    assert summary["model_limits"] == LinkCapacity.capabilities().relay_data_path_model_limits
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

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  defp contact_contention_report_capability_assumptions do
    capabilities = ContactContention.capabilities()

    %{
      "contact_types" => capabilities.contact_types,
      "contact_directions" => capabilities.contact_directions,
      "row_review_statuses" => capabilities.row_review_statuses,
      "station_unavailable_aliases" => capabilities.station_unavailable_aliases,
      "station_availability_precedence" => capabilities.station_availability_precedence,
      "station_capacity_value_paths" =>
        json_capacity_value_paths(capabilities.station_capacity_value_paths),
      "source_station_capacity_value_paths" =>
        json_capacity_value_paths(capabilities.source_station_capacity_value_paths),
      "required_capacity_value_paths" =>
        json_capacity_value_paths(capabilities.required_capacity_value_paths),
      "required_capacity_fraction_source_values" =>
        capabilities.required_capacity_fraction_source_values,
      "station_reservation_priority_match_statuses" =>
        capabilities.station_reservation_priority_match_statuses,
      "station_reservation_priority_statuses" =>
        capabilities.station_reservation_priority_statuses,
      "resolution_selection_rules" => capabilities.resolution_selection_rules,
      "resolution_tie_breakers" => capabilities.resolution_tie_breakers,
      "default_resolution_priority_fields" => capabilities.default_resolution_priority_fields,
      "resolution_priority_override_aliases" => capabilities.resolution_priority_override_aliases,
      "provider_direction_aliases" => capabilities.provider_direction_aliases,
      "provider_result_map_value_keys" => capabilities.provider_result_map_value_keys,
      "contact_stable_identity_fields" => capabilities.contact_stable_identity_fields,
      "command_contact_directions" => capabilities.command_contact_directions
    }
  end

  defp json_capacity_value_paths(paths) do
    Enum.map(paths, fn %{unit: unit, path: path} ->
      %{"unit" => Atom.to_string(unit), "path" => path}
    end)
  end
end
