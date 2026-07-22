defmodule OrbitalDynamics.Schema.CandidateRefreshResourceProvenanceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  test "validates checked-in candidate refresh resource provenance fixture" do
    artifact = read_json!("study_results/candidate_refresh_resource_provenance_v1.json")

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact)

    expected_reason_counts = %{"antenna_unavailable" => 1, "payload_unavailable" => 1}
    expected_reason_ids = ["antenna_unavailable", "payload_unavailable"]
    expected_reason_id_key = Enum.join(expected_reason_ids, "|")

    assert %{
             "schema_contract" => "candidate_refresh.v1",
             "planner" => "OrbitalDynamics.CandidateRefresh.V1",
             "provenance" => %{
               "run_input_sources" => %{
                 "source_operational_readiness_report" => [
                   "candidate_refresh.mission_state.source_operational_readiness_report"
                 ],
                 "source_quality_gate_report" => [
                   "candidate_refresh.mission_state.source_quality_gate_report"
                 ]
               },
               "source_reports" => %{
                 "operational_readiness_report" => operational_readiness_summary,
                 "quality_gate_report" => quality_gate_summary
               }
             }
           } = artifact

    assert %{
             "paths" => ["mission_state.source_operational_readiness_report"],
             "contract" => "operational_readiness_report.v1",
             "count" => 1,
             "row_count" => 1,
             "status_counts" => %{"review_required" => 1},
             "resource_availability_pressure_count" => 2,
             "resource_availability_reason_counts" => ^expected_reason_counts,
             "resource_availability_reason_ids" => ^expected_reason_ids,
             "station_availability_reason_counts" => %{},
             "station_availability_reason_ids" => [],
             "unavailable_resource_reason_ids" => ^expected_reason_ids,
             "review_type_counts" => %{"resource_projection_review" => 1},
             "import_action_counts" => %{"review_resource_projection" => 1}
           } = operational_readiness_summary

    assert {:ok, candidate_refresh_schema} = Schema.json_schema("candidate_refresh.v1")

    candidate_refresh_properties = candidate_refresh_schema["properties"]

    assert get_in(candidate_refresh_properties, ["model_limits", "items", "enum"]) ==
             OrbitalDynamics.CandidateRefresh.model_limits()

    assert get_in(candidate_refresh_properties, [
             "candidate_diff_report",
             "properties",
             "schema_contract",
             "const"
           ]) == "candidate_diff_report.v1"

    assert get_in(candidate_refresh_properties, [
             "contact_allocation_report",
             "properties",
             "schema_contract",
             "const"
           ]) == "contact_allocation_report.v1"

    assert get_in(candidate_refresh_properties, [
             "contact_filter_report",
             "properties",
             "schema_contract",
             "const"
           ]) == "contact_filter_report.v1"

    assert get_in(candidate_refresh_properties, [
             "freshness_report",
             "properties",
             "schema_contract",
             "const"
           ]) == "freshness_report.v1"

    assert get_in(candidate_refresh_properties, [
             "resource_filter_report",
             "properties",
             "schema_contract",
             "const"
           ]) == "resource_filter_report.v1"

    operational_readiness_source_report_properties =
      get_in(candidate_refresh_schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "operational_readiness_report",
        "properties"
      ])

    assert get_in(operational_readiness_source_report_properties, [
             "resource_availability_pressure_count",
             "minimum"
           ]) == 0

    assert get_in(operational_readiness_source_report_properties, [
             "gate_count",
             "minimum"
           ]) == 0

    assert get_in(operational_readiness_source_report_properties, [
             "readiness_level_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(operational_readiness_source_report_properties, [
             "import_action_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(operational_readiness_source_report_properties, [
             "resource_availability_reason_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(operational_readiness_source_report_properties, [
             "resource_availability_reason_ids",
             "items",
             "type"
           ]) == "string"

    assert get_in(operational_readiness_source_report_properties, [
             "resource_blocked_contact_ids_by_blocking_dimension",
             "additionalProperties",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    quality_gate_source_report_properties =
      get_in(candidate_refresh_schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "quality_gate_report",
        "properties"
      ])

    assert get_in(quality_gate_source_report_properties, [
             "schema_validation_status_ids",
             "items",
             "type"
           ]) == "string"

    assert %{
             "paths" => ["mission_state.source_quality_gate_report"],
             "contract" => "quality_gate_report.v1",
             "count" => 1,
             "row_count" => 6,
             "status_counts" => %{"review_required" => 1},
             "gate_status_counts" => %{"passed" => 3, "review_required" => 3},
             "resource_availability_pressure_count" => 2,
             "resource_availability_reason_counts" => ^expected_reason_counts,
             "resource_availability_reason_ids" => ^expected_reason_ids,
             "station_availability_reason_counts" => %{},
             "station_availability_reason_ids" => [],
             "unavailable_resource_reason_ids" => ^expected_reason_ids,
             "source_readiness_report_count" => 1
           } = quality_gate_summary

    assert quality_gate_summary["trust_boundary_status"] == "missing"
    assert quality_gate_summary["trust_boundaries"] == []

    assert Validation.artifact_observations("candidate_refresh.v1", artifact) ==
             %{
               "schema_contract" => "candidate_refresh.v1",
               "schema_version" => 1,
               "planner" => "OrbitalDynamics.CandidateRefresh.V1",
               "candidate_count" => 0,
               "contact_intent_count" => 0,
               "access_window_count" => 1,
               "target_visibility_window_count" => 1,
               "eclipse_interval_count" => 0,
               "warning_count" => 3,
               "source_report_family_count" => 2,
               "source_report_row_count" => 7,
               "source_candidate_rejection_branch_local_invalid_input_pressure" => false,
               "source_candidate_rejection_branch_local_rejection_pressure" => false,
               "source_candidate_rejection_branch_local_review_pressure" => false,
               "source_constraint_branch_local_constraint_pressure" => false,
               "source_constraint_branch_local_constraint_routing_pressure" => false,
               "source_constraint_branch_local_downlink_gap_pressure" => false,
               "source_constraint_branch_local_resource_margin_pressure" => false,
               "source_contact_filter_branch_local_candidate_suppression_pressure" => false,
               "source_contact_filter_branch_local_contact_filter_pressure" => false,
               "source_contact_filter_branch_local_invalid_contact_input_pressure" => false,
               "source_contact_filter_branch_local_station_suppression_pressure" => false,
               "source_contact_allocation_branch_local_provider_reservation_request_pressure" =>
                 false,
               "source_contact_allocation_branch_local_reservation_conflict_pressure" => false,
               "source_freshness_branch_local_freshness_pressure" => false,
               "source_freshness_branch_local_stale_pressure" => false,
               "source_freshness_branch_local_unknown_pressure" => false,
               "source_link_capacity_branch_local_actual_throughput_pressure" => false,
               "source_link_capacity_branch_local_capacity_adjusted_throughput_pressure" => false,
               "source_link_capacity_branch_local_downlink_shortfall_pressure" => false,
               "source_link_capacity_branch_local_link_capacity_pressure" => false,
               "source_objective_gap_branch_local_collection_latency_gap_pressure" => false,
               "source_objective_gap_branch_local_downlink_gap_pressure" => false,
               "source_objective_gap_branch_local_objective_gap_pressure" => false,
               "source_objective_gap_branch_local_objective_status_pressure" => false,
               "source_objective_gap_branch_local_routing_pressure" => false,
               "source_objective_gap_branch_local_score_term_pressure" => false,
               "source_objective_gap_branch_local_target_gap_pressure" => false,
               "source_quality_gate_report_count" => 1,
               "source_quality_gate_row_count" => 6,
               "source_quality_gate_gate_count" => 6,
               "source_quality_gate_passed_gate_count" => 3,
               "source_quality_gate_review_gate_count" => 3,
               "source_quality_gate_analysis_gate_count" => 0,
               "source_quality_gate_blocked_gate_count" => 0,
               "source_quality_gate_branch_local_import_pressure" => false,
               "source_quality_gate_branch_local_resource_pressure" => true,
               "source_quality_gate_branch_local_review_pressure" => true,
               "source_quality_gate_readiness_level_counts" => %{"operator_review" => 1},
               "source_quality_gate_import_classification_counts" => %{"review_only" => 1},
               "source_quality_gate_status_counts" => %{"review_required" => 1},
               "source_quality_gate_gate_status_counts" => %{
                 "passed" => 3,
                 "review_required" => 3
               },
               "source_quality_gate_gate_classification_counts" => %{
                 "importable" => 3,
                 "review_only" => 3
               },
               "source_quality_gate_resource_availability_pressure_count" => 2,
               "source_quality_gate_resource_availability_reason_counts" =>
                 expected_reason_counts,
               "source_quality_gate_resource_availability_reason_ids" => expected_reason_id_key,
               "source_quality_gate_trust_boundary_status" => "missing",
               "source_operational_readiness_report_count" => 1,
               "source_operational_readiness_row_count" => 1,
               "source_operational_readiness_gate_count" => 6,
               "source_operational_readiness_passed_gate_count" => 3,
               "source_operational_readiness_review_gate_count" => 3,
               "source_operational_readiness_analysis_gate_count" => 0,
               "source_operational_readiness_blocked_gate_count" => 0,
               "source_operational_readiness_branch_local_import_pressure" => false,
               "source_operational_readiness_branch_local_resource_pressure" => true,
               "source_operational_readiness_branch_local_review_pressure" => true,
               "source_operational_readiness_readiness_level_counts" => %{
                 "operator_review" => 1
               },
               "source_operational_readiness_import_classification_counts" => %{
                 "review_only" => 1
               },
               "source_operational_readiness_resource_availability_pressure_count" => 2,
               "source_operational_readiness_resource_availability_reason_counts" =>
                 expected_reason_counts,
               "source_operational_readiness_resource_availability_reason_ids" =>
                 expected_reason_id_key,
               "source_operational_readiness_status_counts" => %{"review_required" => 1},
               "source_operational_readiness_trust_boundary_status" => "missing",
               "source_refresh_budget_branch_local_budget_pressure" => false,
               "source_refresh_budget_branch_local_candidate_limit_applied" => false,
               "source_refresh_budget_branch_local_dropped_candidate_pressure" => false,
               "source_refresh_budget_branch_local_invalid_limit_pressure" => false,
               "source_station_calendar_branch_local_affected_contact_pressure" => false,
               "source_station_calendar_branch_local_provider_contention_pressure" => false,
               "source_station_calendar_branch_local_station_availability_pressure" => false,
               "source_station_calendar_branch_local_station_calendar_pressure" => false,
               "source_resource_filter_branch_local_candidate_suppression_pressure" => false,
               "source_resource_filter_branch_local_invalid_resource_summary_pressure" => false,
               "source_resource_filter_branch_local_resource_blocking_pressure" => false,
               "source_resource_filter_branch_local_resource_filter_pressure" => false,
               "source_score_term_branch_local_collection_latency_gap_pressure" => false,
               "source_score_term_branch_local_downlink_gap_pressure" => false,
               "source_score_term_branch_local_routing_pressure" => false,
               "source_score_term_branch_local_score_term_pressure" => false,
               "source_score_term_branch_local_target_gap_pressure" => false
             }

    invalid_reason_id =
      put_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "quality_gate_report",
          "resource_availability_reason_ids",
          Access.at(0)
        ],
        42
      )

    assert {:error, invalid_reason_id_report} = Schema.validate_artifact(invalid_reason_id)

    assert Enum.any?(
             invalid_reason_id_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.quality_gate_report.resource_availability_reason_ids[0]")
           )

    invalid_schema_validation_status_id =
      update_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "quality_gate_report"
        ],
        fn summary ->
          Map.put(summary, "schema_validation_status_ids", [42])
        end
      )

    assert {:error, invalid_schema_validation_status_id_report} =
             Schema.validate_artifact(invalid_schema_validation_status_id)

    assert Enum.any?(
             invalid_schema_validation_status_id_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.quality_gate_report.schema_validation_status_ids[0]")
           )

    invalid_reason_count =
      put_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "operational_readiness_report",
          "resource_availability_reason_counts",
          "payload_unavailable"
        ],
        -1
      )

    assert {:error, invalid_reason_count_report} = Schema.validate_artifact(invalid_reason_count)

    assert Enum.any?(
             invalid_reason_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.operational_readiness_report.resource_availability_reason_counts.payload_unavailable")
           )

    invalid_import_action_count =
      put_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "operational_readiness_report",
          "import_action_counts",
          "review_resource_projection"
        ],
        -1
      )

    assert {:error, invalid_import_action_count_report} =
             Schema.validate_artifact(invalid_import_action_count)

    assert Enum.any?(
             invalid_import_action_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.operational_readiness_report.import_action_counts.review_resource_projection")
           )

    invalid_station_reason_count =
      put_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "quality_gate_report",
          "station_availability_reason_counts",
          "ground_station_reserved"
        ],
        -1
      )

    assert {:error, invalid_station_reason_count_report} =
             Schema.validate_artifact(invalid_station_reason_count)

    assert Enum.any?(
             invalid_station_reason_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.quality_gate_report.station_availability_reason_counts.ground_station_reserved")
           )

    invalid_analysis_mode_count =
      update_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "quality_gate_report"
        ],
        fn summary ->
          Map.put(summary, "analysis_mode_counts", %{"not_for_execution" => -1})
        end
      )

    assert {:error, invalid_analysis_mode_count_report} =
             Schema.validate_artifact(invalid_analysis_mode_count)

    assert Enum.any?(
             invalid_analysis_mode_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.quality_gate_report.analysis_mode_counts.not_for_execution")
           )

    invalid_trust_boundary_status =
      put_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "quality_gate_report",
          "trust_boundary_status"
        ],
        42
      )

    assert {:error, invalid_trust_boundary_status_report} =
             Schema.validate_artifact(invalid_trust_boundary_status)

    assert Enum.any?(
             invalid_trust_boundary_status_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.quality_gate_report.trust_boundary_status")
           )

    invalid_trust_boundary =
      update_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "quality_gate_report"
        ],
        fn summary ->
          Map.put(summary, "trust_boundaries", [42])
        end
      )

    assert {:error, invalid_trust_boundary_report} =
             Schema.validate_artifact(invalid_trust_boundary)

    assert Enum.any?(
             invalid_trust_boundary_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.quality_gate_report.trust_boundaries[0]")
           )

    invalid_model_limits = Map.put(artifact, "model_limits", ["stale_candidate_refresh_limit"])

    assert {:error, invalid_model_limits_report} =
             Schema.validate_artifact(invalid_model_limits)

    assert Enum.any?(
             invalid_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    invalid_top_level_contact_allocation =
      put_in(artifact, ["contact_allocation_report", "allocated_contact_count"], -1)

    assert {:error, invalid_top_level_contact_allocation_report} =
             Schema.validate_artifact(invalid_top_level_contact_allocation)

    assert Enum.any?(
             invalid_top_level_contact_allocation_report["errors"],
             &(&1["path"] == "$.contact_allocation_report.allocated_contact_count")
           )
  end

  test "validates station, contact, maneuver, and policy source-report provenance contracts" do
    artifact = read_json!("study_results/candidate_refresh_resource_provenance_v1.json")

    artifact_with_station_pressure_summary =
      put_in(artifact, ["provenance", "source_reports", "contact_allocation_report"], %{
        "paths" => ["mission_state.source_contact_allocation_report"],
        "contract" => "contact_allocation_report.v1",
        "count" => 1,
        "row_count" => 2,
        "station_pressure_contact_count" => 2,
        "station_pressure_ground_station_counts" => %{"gs_equator" => 1, "gs_polar" => 1},
        "station_pressure_availability_counts" => %{"reserved" => 1, "unavailable" => 1},
        "station_pressure_precedence_availability_counts" => %{
          "reserved" => 1,
          "unavailable" => 1
        },
        "station_pressure_precedence_rank_counts" => %{"1" => 1, "2" => 1},
        "provider_reservation_request_contact_ids_by_direction_and_ground_station" => %{
          "downlink" => %{"equator_prime" => ["dl_reserved_owner"]}
        }
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_station_pressure_summary)

    stale_contact_allocation_direction_route =
      put_in(
        artifact_with_station_pressure_summary,
        ["provenance", "source_reports", "contact_allocation_report", "direction_routing"],
        %{
          "stale_direction" => %{
            "contact_count" => 99,
            "contact_ids" => ["stale_contact"]
          }
        }
      )

    assert {:error, stale_contact_allocation_direction_route_report} =
             Schema.validate_artifact(stale_contact_allocation_direction_route)

    assert Enum.any?(
             stale_contact_allocation_direction_route_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_allocation_report.direction_routing")
           )

    artifact_with_allocation_direction_summary =
      put_in(artifact, ["provenance", "source_reports", "contact_allocation_report"], %{
        "paths" => ["source_contact_allocation_report"],
        "contract" => "contact_allocation_report.v1",
        "count" => 1,
        "row_count" => 2,
        "blocked_row_count" => 1,
        "deferred_row_count" => 1,
        "allocated_contact_count" => 2,
        "allocated_contact_ids" => ["dl_backup", "dl_primary"],
        "allocated_contact_ids_by_ground_station" => %{
          "equator_prime" => ["dl_backup", "dl_primary"]
        },
        "allocation_status_counts" => %{"allocated" => 2},
        "effective_allocation_status_counts" => %{"allocated" => 2},
        "allocation_reason_counts" => %{"selected" => 2},
        "contact_ids_by_allocation_reason" => %{
          "selected" => ["dl_backup", "dl_primary"]
        },
        "review_contact_ids" => ["review_a", "review_b"],
        "station_pressure_review_contact_count" => 2,
        "station_pressure_review_contact_ids" => ["station_review_a", "station_review_b"],
        "reservation_conflict_contact_count" => 2,
        "reservation_conflict_contact_ids" => ["conflict_a", "conflict_b"],
        "reservation_conflict_match_status_counts" => %{"overlap" => 2},
        "reservation_conflict_contact_ids_by_match_status" => %{
          "overlap" => ["conflict_a", "conflict_b"]
        },
        "reservation_conflict_reservation_ids_by_match_status" => %{
          "overlap" => ["reservation_a", "reservation_b"]
        },
        "reservation_conflict_direction_counts" => %{"downlink" => 2},
        "reservation_conflict_contact_ids_by_direction" => %{
          "downlink" => ["conflict_a", "conflict_b"]
        },
        "reservation_conflict_contact_ids_by_direction_and_ground_station" => %{
          "downlink" => %{"equator_prime" => ["conflict_a", "conflict_b"]}
        },
        "resource_blocked_contact_count" => 2,
        "resource_blocked_contact_ids" => ["resource_a", "resource_b"],
        "resource_blocking_dimension_counts" => %{"antenna" => 2},
        "resource_blocked_contact_ids_by_blocking_dimension" => %{
          "antenna" => ["resource_a", "resource_b"]
        },
        "resource_blocked_contact_ids_by_spacecraft" => %{
          "leo_1" => ["resource_a", "resource_b"]
        },
        "direction_counts" => %{"downlink" => 2},
        "contact_ids_by_direction" => %{
          "downlink" => ["dl_backup", "dl_primary"]
        },
        "direction_routing" => %{
          "downlink" => %{
            "contact_count" => 2,
            "contact_ids" => ["dl_backup", "dl_primary"],
            "provider_reservation_no_request_contact_ids" => [],
            "provider_reservation_request_contact_ids" => [],
            "provider_reservation_review_contact_ids" => [],
            "reservation_conflict_contact_count" => 2,
            "reservation_conflict_contact_ids" => ["conflict_a", "conflict_b"],
            "station_pressure_contact_ids" => []
          }
        }
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_allocation_direction_summary)

    undersized_allocation_outcome_count =
      put_in(
        artifact_with_allocation_direction_summary,
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "allocated_contact_count"
        ],
        1
      )

    assert {:error, undersized_allocation_outcome_count_report} =
             Schema.validate_artifact(undersized_allocation_outcome_count)

    assert Enum.any?(
             undersized_allocation_outcome_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_allocation_report.allocated_contact_count")
           )

    noncanonical_allocation_outcome_ids =
      put_in(
        artifact_with_allocation_direction_summary,
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "allocated_contact_ids"
        ],
        ["dl_primary", "dl_backup", "dl_backup"]
      )

    assert {:error, noncanonical_allocation_outcome_ids_report} =
             Schema.validate_artifact(noncanonical_allocation_outcome_ids)

    assert Enum.any?(
             noncanonical_allocation_outcome_ids_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_allocation_report.allocated_contact_ids")
           )

    noncanonical_allocation_outcome_routes =
      put_in(
        artifact_with_allocation_direction_summary,
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "allocated_contact_ids_by_ground_station"
        ],
        %{
          "equator_prime" => ["dl_primary", "dl_backup", "dl_backup"],
          "invalid station" => ["orphan_contact"]
        }
      )

    assert {:error, noncanonical_allocation_outcome_routes_report} =
             Schema.validate_artifact(noncanonical_allocation_outcome_routes)

    assert Enum.any?(
             noncanonical_allocation_outcome_routes_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_allocation_report.allocated_contact_ids_by_ground_station")
           )

    noncanonical_allocation_review_ids =
      put_in(
        artifact_with_allocation_direction_summary,
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "review_contact_ids"
        ],
        ["review_b", "review_a", "review_a"]
      )

    assert {:error, noncanonical_allocation_review_ids_report} =
             Schema.validate_artifact(noncanonical_allocation_review_ids)

    assert Enum.any?(
             noncanonical_allocation_review_ids_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_allocation_report.review_contact_ids")
           )

    contradictory_station_pressure_review_count =
      put_in(
        artifact_with_allocation_direction_summary,
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "station_pressure_review_contact_count"
        ],
        1
      )

    assert {:error, contradictory_station_pressure_review_count_report} =
             Schema.validate_artifact(contradictory_station_pressure_review_count)

    assert Enum.any?(
             contradictory_station_pressure_review_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_allocation_report.station_pressure_review_contact_count")
           )

    noncanonical_station_pressure_review_ids =
      put_in(
        artifact_with_allocation_direction_summary,
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "station_pressure_review_contact_ids"
        ],
        ["station_review_b", "station_review_a", "station_review_a"]
      )

    assert {:error, noncanonical_station_pressure_review_ids_report} =
             Schema.validate_artifact(noncanonical_station_pressure_review_ids)

    assert Enum.any?(
             noncanonical_station_pressure_review_ids_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_allocation_report.station_pressure_review_contact_ids")
           )

    contradictory_reservation_conflict_count =
      put_in(
        artifact_with_allocation_direction_summary,
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "reservation_conflict_contact_count"
        ],
        1
      )

    assert {:error, contradictory_reservation_conflict_count_report} =
             Schema.validate_artifact(contradictory_reservation_conflict_count)

    assert Enum.any?(
             contradictory_reservation_conflict_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_allocation_report.reservation_conflict_contact_count")
           )

    noncanonical_reservation_conflict_nested_route =
      put_in(
        artifact_with_allocation_direction_summary,
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "reservation_conflict_contact_ids_by_direction_and_ground_station"
        ],
        %{
          "Down Link" => %{
            "equator_prime" => ["conflict_b", "conflict_a", "conflict_a"],
            "invalid station" => ["orphan_contact"]
          }
        }
      )

    assert {:error, noncanonical_reservation_conflict_nested_route_report} =
             Schema.validate_artifact(noncanonical_reservation_conflict_nested_route)

    assert Enum.any?(
             noncanonical_reservation_conflict_nested_route_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_allocation_report.reservation_conflict_contact_ids_by_direction_and_ground_station")
           )

    incomplete_reservation_conflict_direction_rollup =
      put_in(
        artifact_with_allocation_direction_summary,
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "reservation_conflict_contact_ids_by_direction"
        ],
        %{"downlink" => ["conflict_a"]}
      )

    assert {:error, incomplete_reservation_conflict_direction_rollup_report} =
             Schema.validate_artifact(incomplete_reservation_conflict_direction_rollup)

    assert Enum.any?(
             incomplete_reservation_conflict_direction_rollup_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_allocation_report.reservation_conflict_contact_ids_by_direction")
           )

    nested_only_reservation_conflict_missing_aggregate_route =
      artifact_with_allocation_direction_summary
      |> update_in(
        ["provenance", "source_reports", "contact_allocation_report"],
        &Map.delete(&1, "reservation_conflict_contact_ids_by_direction")
      )
      |> put_in(
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "direction_routing",
          "downlink",
          "reservation_conflict_contact_ids"
        ],
        []
      )

    assert {:error, nested_only_reservation_conflict_missing_aggregate_route_report} =
             Schema.validate_artifact(nested_only_reservation_conflict_missing_aggregate_route)

    assert Enum.any?(
             nested_only_reservation_conflict_missing_aggregate_route_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_allocation_report.direction_routing")
           )

    noncanonical_reservation_conflict_direction_counts =
      put_in(
        artifact_with_allocation_direction_summary,
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "reservation_conflict_direction_counts"
        ],
        %{"Down Link" => 2}
      )

    assert {:error, noncanonical_reservation_conflict_direction_counts_report} =
             Schema.validate_artifact(noncanonical_reservation_conflict_direction_counts)

    assert Enum.any?(
             noncanonical_reservation_conflict_direction_counts_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_allocation_report.reservation_conflict_direction_counts")
           )

    undersized_reservation_conflict_match_status_counts =
      put_in(
        artifact_with_allocation_direction_summary,
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "reservation_conflict_match_status_counts"
        ],
        %{"overlap" => 1}
      )

    assert {:error, undersized_reservation_conflict_match_status_counts_report} =
             Schema.validate_artifact(undersized_reservation_conflict_match_status_counts)

    assert Enum.any?(
             undersized_reservation_conflict_match_status_counts_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_allocation_report.reservation_conflict_match_status_counts")
           )

    over_cardinality_allocation_reason_ids =
      put_in(
        artifact_with_allocation_direction_summary,
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "allocation_reason_counts",
          "selected"
        ],
        1
      )

    assert {:error, over_cardinality_allocation_reason_ids_report} =
             Schema.validate_artifact(over_cardinality_allocation_reason_ids)

    assert Enum.any?(
             over_cardinality_allocation_reason_ids_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_allocation_report.contact_ids_by_allocation_reason")
           )

    undersized_blocked_input_count =
      update_in(
        artifact_with_allocation_direction_summary,
        ["provenance", "source_reports", "contact_allocation_report"],
        fn summary ->
          Map.merge(summary, %{
            "resource_blocked_contact_count" => 1,
            "resource_blocked_contact_ids" => ["resource_a", "resource_b"]
          })
        end
      )

    assert {:error, undersized_blocked_input_count_report} =
             Schema.validate_artifact(undersized_blocked_input_count)

    assert Enum.any?(
             undersized_blocked_input_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_allocation_report.resource_blocked_contact_count")
           )

    noncanonical_blocked_input_ids =
      update_in(
        artifact_with_allocation_direction_summary,
        ["provenance", "source_reports", "contact_allocation_report"],
        fn summary ->
          Map.merge(summary, %{
            "status_blocked_contact_count" => 2,
            "status_blocked_contact_ids" => ["status_b", "status_a", "status_a"]
          })
        end
      )

    assert {:error, noncanonical_blocked_input_ids_report} =
             Schema.validate_artifact(noncanonical_blocked_input_ids)

    assert Enum.any?(
             noncanonical_blocked_input_ids_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_allocation_report.status_blocked_contact_ids")
           )

    over_cardinality_resource_dimension_route =
      put_in(
        artifact_with_allocation_direction_summary,
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "resource_blocking_dimension_counts",
          "antenna"
        ],
        1
      )

    assert {:error, over_cardinality_resource_dimension_route_report} =
             Schema.validate_artifact(over_cardinality_resource_dimension_route)

    assert Enum.any?(
             over_cardinality_resource_dimension_route_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_allocation_report.resource_blocked_contact_ids_by_blocking_dimension")
           )

    noncanonical_resource_spacecraft_route =
      put_in(
        artifact_with_allocation_direction_summary,
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "resource_blocked_contact_ids_by_spacecraft"
        ],
        %{
          "leo_1" => ["resource_b", "resource_a", "resource_a"],
          "invalid spacecraft" => ["orphan_contact"]
        }
      )

    assert {:error, noncanonical_resource_spacecraft_route_report} =
             Schema.validate_artifact(noncanonical_resource_spacecraft_route)

    assert Enum.any?(
             noncanonical_resource_spacecraft_route_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_allocation_report.resource_blocked_contact_ids_by_spacecraft")
           )

    contradictory_allocation_row_counts =
      put_in(
        artifact_with_allocation_direction_summary,
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "blocked_row_count"
        ],
        2
      )

    assert {:error, contradictory_allocation_row_count_report} =
             Schema.validate_artifact(contradictory_allocation_row_counts)

    for field <- ["blocked_row_count", "deferred_row_count"] do
      assert Enum.any?(
               contradictory_allocation_row_count_report["errors"],
               &(&1["path"] ==
                   "$.provenance.source_reports.contact_allocation_report.#{field}")
             )
    end

    noncanonical_allocation_count_maps =
      artifact_with_allocation_direction_summary
      |> put_in(
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "allocation_status_counts",
          "stale_status"
        ],
        0
      )
      |> put_in(
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "effective_allocation_status_counts",
          "stale_effective_status"
        ],
        0
      )
      |> put_in(
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "allocation_reason_counts",
          "stale_reason"
        ],
        0
      )

    assert {:error, noncanonical_allocation_count_map_report} =
             Schema.validate_artifact(noncanonical_allocation_count_maps)

    for field <- [
          "allocation_status_counts",
          "effective_allocation_status_counts",
          "allocation_reason_counts"
        ] do
      assert Enum.any?(
               noncanonical_allocation_count_map_report["errors"],
               &(&1["path"] ==
                   "$.provenance.source_reports.contact_allocation_report.#{field}")
             )
    end

    for field <- [
          "allocation_status_counts",
          "effective_allocation_status_counts",
          "allocation_reason_counts"
        ] do
      overstated_allocation_count_map =
        put_in(
          artifact_with_allocation_direction_summary,
          ["provenance", "source_reports", "contact_allocation_report", field],
          %{"overstated" => 3}
        )

      assert {:error, overstated_allocation_count_map_report} =
               Schema.validate_artifact(overstated_allocation_count_map)

      assert Enum.any?(
               overstated_allocation_count_map_report["errors"],
               &(&1["path"] ==
                   "$.provenance.source_reports.contact_allocation_report.#{field}")
             )
    end

    allocation_maps_without_row_count =
      update_in(
        artifact_with_allocation_direction_summary,
        ["provenance", "source_reports", "contact_allocation_report"],
        &Map.delete(&1, "row_count")
      )

    assert {:error, allocation_maps_without_row_count_report} =
             Schema.validate_artifact(allocation_maps_without_row_count)

    for field <- [
          "allocation_status_counts",
          "effective_allocation_status_counts",
          "allocation_reason_counts"
        ] do
      assert Enum.any?(
               allocation_maps_without_row_count_report["errors"],
               &(&1["path"] ==
                   "$.provenance.source_reports.contact_allocation_report.#{field}")
             )
    end

    for field <- ["blocked_row_count", "deferred_row_count"] do
      assert Enum.any?(
               allocation_maps_without_row_count_report["errors"],
               &(&1["path"] ==
                   "$.provenance.source_reports.contact_allocation_report.#{field}")
             )
    end

    noncanonical_allocation_direction =
      update_in(
        artifact_with_allocation_direction_summary,
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "direction_counts"
        ],
        fn counts -> counts |> Map.delete("downlink") |> Map.put("Down Link", 2) end
      )

    assert {:error, noncanonical_allocation_direction_report} =
             Schema.validate_artifact(noncanonical_allocation_direction)

    assert Enum.any?(
             noncanonical_allocation_direction_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_allocation_report.direction_counts")
           )

    over_cardinality_allocation_direction =
      put_in(
        artifact_with_allocation_direction_summary,
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "direction_counts",
          "downlink"
        ],
        1
      )

    assert {:error, over_cardinality_allocation_direction_report} =
             Schema.validate_artifact(over_cardinality_allocation_direction)

    assert Enum.any?(
             over_cardinality_allocation_direction_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_allocation_report.contact_ids_by_direction")
           )

    invalid_station_pressure_count =
      put_in(
        artifact_with_station_pressure_summary,
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "station_pressure_availability_counts",
          "reserved"
        ],
        -1
      )

    assert {:error, invalid_station_pressure_count_report} =
             Schema.validate_artifact(invalid_station_pressure_count)

    assert Enum.any?(
             invalid_station_pressure_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_allocation_report.station_pressure_availability_counts.reserved")
           )

    invalid_provider_reservation_contact_id =
      put_in(
        artifact_with_station_pressure_summary,
        [
          "provenance",
          "source_reports",
          "contact_allocation_report",
          "provider_reservation_request_contact_ids_by_direction_and_ground_station",
          "downlink",
          "equator_prime",
          Access.at(0)
        ],
        "bad contact"
      )

    assert {:error, invalid_provider_reservation_contact_id_report} =
             Schema.validate_artifact(invalid_provider_reservation_contact_id)

    assert Enum.any?(
             invalid_provider_reservation_contact_id_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_allocation_report.provider_reservation_request_contact_ids_by_direction_and_ground_station.downlink.equator_prime[0]")
           )

    artifact_with_station_calendar_summary =
      put_in(artifact, ["provenance", "source_reports", "station_calendar_report"], %{
        "paths" => ["source_station_calendar_report"],
        "contract" => "station_calendar_report.v1",
        "count" => 1,
        "row_count" => 4,
        "affected_contact_count" => 3,
        "affected_contact_ids" => ["dl_reduced", "dl_reserved", "dl_unavailable"],
        "affected_station_calendar_entry_ids" => [
          "station_entry_reduced",
          "station_entry_reserved",
          "station_entry_unavailable"
        ],
        "affected_station_reservation_ids" => ["reservation_dss_43"],
        "affected_contact_ground_station_counts" => %{
          "dss_43" => 1,
          "equator_prime" => 2
        },
        "affected_contact_availability_counts" => %{
          "reduced_capacity" => 1,
          "reserved" => 1,
          "unavailable" => 1
        },
        "direction_counts" => %{"downlink" => 2, "uplink" => 1},
        "contact_ids_by_direction" => %{
          "downlink" => ["dl_reduced", "dl_unavailable"],
          "uplink" => ["dl_reserved"]
        },
        "station_calendar_entry_ids_by_direction" => %{
          "downlink" => ["station_entry_reduced", "station_entry_unavailable"],
          "uplink" => ["station_entry_reserved"]
        },
        "station_reservation_ids_by_direction" => %{"uplink" => ["reservation_dss_43"]},
        "station_capacity_fractions_by_direction" => %{"downlink" => [0.4]},
        "direction_routing" => %{
          "downlink" => %{
            "contact_count" => 2,
            "contact_ids" => ["dl_reduced", "dl_unavailable"],
            "station_calendar_entry_ids" => [
              "station_entry_reduced",
              "station_entry_unavailable"
            ],
            "station_reservation_ids" => [],
            "station_capacity_fractions" => [0.4],
            "provider_contention_group_count" => 1,
            "provider_contention_group_ids" => [
              "station_calendar_provider_contention:equator_prime:1"
            ],
            "provider_contention_source_entry_ids" => ["provider_a", "provider_b"],
            "provider_contention_provider_entry_ids" => [
              "provider_entry_ops",
              "provider_entry_partner"
            ],
            "provider_contention_capacity_fractions" => [0.25]
          },
          "uplink" => %{
            "contact_count" => 1,
            "contact_ids" => ["dl_reserved"],
            "station_calendar_entry_ids" => ["station_entry_reserved"],
            "station_reservation_ids" => ["reservation_dss_43"],
            "station_capacity_fractions" => []
          }
        },
        "provider_calendar_contention_group_count" => 1,
        "provider_calendar_contention_group_ids" => [
          "station_calendar_provider_contention:equator_prime:1"
        ],
        "provider_calendar_contention_source_entry_ids" => ["provider_a", "provider_b"],
        "provider_calendar_contention_provider_entry_ids" => [
          "provider_entry_ops",
          "provider_entry_partner"
        ],
        "provider_calendar_contention_capacity_fractions" => [0.25],
        "provider_calendar_contention_minimum_capacity_fraction" => 0.25,
        "provider_calendar_contention_provider_counts" => %{
          "ops_calendar" => 1,
          "partner_calendar" => 1
        },
        "provider_calendar_contention_ground_station_counts" => %{
          "dss_43" => 1,
          "equator_prime" => 1
        },
        "provider_calendar_contention_direction_counts" => %{
          "downlink" => 1,
          "tracking" => 1
        },
        "provider_calendar_contention_group_ids_by_direction" => %{
          "downlink" => ["station_calendar_provider_contention:equator_prime:1"],
          "tracking" => ["station_calendar_provider_contention:equator_prime:1"]
        },
        "provider_calendar_contention_source_entry_ids_by_direction" => %{
          "downlink" => ["provider_a", "provider_b"],
          "tracking" => ["provider_a", "provider_b"]
        },
        "provider_calendar_contention_provider_entry_ids_by_direction" => %{
          "downlink" => ["provider_entry_ops", "provider_entry_partner"],
          "tracking" => ["provider_entry_ops", "provider_entry_partner"]
        },
        "provider_calendar_contention_capacity_fractions_by_direction" => %{
          "downlink" => [0.25],
          "tracking" => [0.25]
        }
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_station_calendar_summary)

    assert {:ok, candidate_refresh_schema} = Schema.json_schema("candidate_refresh.v1")

    station_calendar_source_report_properties =
      get_in(candidate_refresh_schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "station_calendar_report",
        "properties"
      ])

    assert get_in(station_calendar_source_report_properties, [
             "direction_routing",
             "additionalProperties",
             "properties",
             "provider_contention_provider_entry_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(station_calendar_source_report_properties, [
             "provider_calendar_contention_capacity_fractions_by_direction",
             "additionalProperties",
             "items",
             "type"
           ]) == "number"

    invalid_station_calendar_route_fraction =
      put_in(
        artifact_with_station_calendar_summary,
        [
          "provenance",
          "source_reports",
          "station_calendar_report",
          "direction_routing",
          "downlink",
          "provider_contention_capacity_fractions"
        ],
        [-0.25]
      )

    assert {:error, invalid_station_calendar_route_fraction_report} =
             Schema.validate_artifact(invalid_station_calendar_route_fraction)

    assert Enum.any?(
             invalid_station_calendar_route_fraction_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.station_calendar_report.direction_routing.downlink.provider_contention_capacity_fractions[0]")
           )

    invalid_station_calendar_direction_id =
      put_in(
        artifact_with_station_calendar_summary,
        [
          "provenance",
          "source_reports",
          "station_calendar_report",
          "provider_calendar_contention_provider_entry_ids_by_direction",
          "downlink"
        ],
        ["bad provider entry"]
      )

    assert {:error, invalid_station_calendar_direction_id_report} =
             Schema.validate_artifact(invalid_station_calendar_direction_id)

    assert Enum.any?(
             invalid_station_calendar_direction_id_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.station_calendar_report.provider_calendar_contention_provider_entry_ids_by_direction.downlink[0]")
           )

    artifact_with_contact_intent_summary =
      put_in(artifact, ["provenance", "source_reports", "contact_intent"], %{
        "paths" => ["source_contact_intent"],
        "contract" => "contact_intent.v1",
        "count" => 1,
        "row_count" => 1,
        "station_feedback_count" => 1,
        "capacity_pack_required_contact_count" => 1,
        "capacity_pack_required_capacity_fraction" => 0.25,
        "capacity_pack_required_capacity_fraction_by_ground_station" => %{
          "equator_prime" => 0.25
        },
        "capacity_pack_required_capacity_fraction_by_direction" => %{"downlink" => 0.25},
        "capacity_pack_required_capacity_fraction_by_direction_and_ground_station" => %{
          "downlink" => %{"equator_prime" => 0.25}
        },
        "required_capacity_fraction_source_counts" => %{
          "contact_required_capacity_fraction" => 1
        },
        "required_capacity_fraction_contact_ids_by_source" => %{
          "contact_required_capacity_fraction" => ["intent_direct_capacity"]
        },
        "capacity_pack_contact_ids_by_ground_station" => %{
          "equator_prime" => ["intent_direct_capacity"]
        },
        "contact_ids_by_ground_station" => %{
          "equator_prime" => ["intent_direct_capacity", "intent_station_only"]
        },
        "capacity_pack_contact_ids_by_direction" => %{
          "downlink" => ["intent_direct_capacity"]
        },
        "capacity_pack_contact_ids_by_direction_and_ground_station" => %{
          "downlink" => %{"equator_prime" => ["intent_direct_capacity"]}
        },
        "directions" => ["command", "downlink"],
        "direction_counts" => %{"command" => 1, "downlink" => 1},
        "contact_ids_by_direction" => %{
          "command" => ["intent_station_only"],
          "downlink" => ["intent_direct_capacity"]
        },
        "contact_ids_by_direction_and_ground_station" => %{
          "command" => %{"equator_prime" => ["intent_station_only"]},
          "downlink" => %{"equator_prime" => ["intent_direct_capacity"]}
        },
        "direction_routing" => %{
          "command" => %{
            "contact_count" => 1,
            "contact_ids" => ["intent_station_only"],
            "capacity_pack_contact_ids" => [],
            "ground_station_ids" => ["equator_prime"],
            "contact_ids_by_ground_station" => %{
              "equator_prime" => ["intent_station_only"]
            }
          },
          "downlink" => %{
            "contact_count" => 1,
            "contact_ids" => ["intent_direct_capacity"],
            "capacity_pack_required_capacity_fraction" => 0.25,
            "capacity_pack_contact_ids" => ["intent_direct_capacity"],
            "ground_station_ids" => ["equator_prime"],
            "contact_ids_by_ground_station" => %{
              "equator_prime" => ["intent_direct_capacity"]
            },
            "capacity_pack_required_capacity_fraction_by_ground_station" => %{
              "equator_prime" => 0.25
            },
            "capacity_pack_contact_ids_by_ground_station" => %{
              "equator_prime" => ["intent_direct_capacity"]
            }
          }
        },
        "station_calendar_status_counts" => %{"unavailable" => 1},
        "cadence_import_status_counts" => %{"missing" => 1},
        "policy_classification_counts" => %{"review_only" => 1}
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_contact_intent_summary)

    assert {:ok, candidate_refresh_schema} = Schema.json_schema("candidate_refresh.v1")

    contact_intent_source_report_properties =
      get_in(candidate_refresh_schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "contact_intent",
        "properties"
      ])

    assert get_in(contact_intent_source_report_properties, [
             "direction_routing",
             "additionalProperties",
             "properties",
             "capacity_pack_contact_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(contact_intent_source_report_properties, [
             "capacity_pack_required_capacity_fraction_by_direction",
             "additionalProperties",
             "minimum"
           ]) == 0.0

    assert get_in(contact_intent_source_report_properties, [
             "capacity_pack_required_capacity_fraction_by_direction_and_ground_station",
             "additionalProperties",
             "additionalProperties",
             "minimum"
           ]) == 0.0

    assert get_in(contact_intent_source_report_properties, [
             "contact_ids_by_direction",
             "additionalProperties",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(contact_intent_source_report_properties, [
             "contact_ids_by_direction_and_ground_station",
             "additionalProperties",
             "additionalProperties",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    invalid_contact_intent_status_count =
      put_in(
        artifact_with_contact_intent_summary,
        [
          "provenance",
          "source_reports",
          "contact_intent",
          "station_calendar_status_counts",
          "unavailable"
        ],
        -1
      )

    assert {:error, invalid_contact_intent_status_count_report} =
             Schema.validate_artifact(invalid_contact_intent_status_count)

    assert Enum.any?(
             invalid_contact_intent_status_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_intent.station_calendar_status_counts.unavailable")
           )

    invalid_contact_intent_direction_fraction =
      put_in(
        artifact_with_contact_intent_summary,
        [
          "provenance",
          "source_reports",
          "contact_intent",
          "direction_routing",
          "downlink",
          "capacity_pack_required_capacity_fraction"
        ],
        -0.25
      )

    assert {:error, invalid_contact_intent_direction_fraction_report} =
             Schema.validate_artifact(invalid_contact_intent_direction_fraction)

    assert Enum.any?(
             invalid_contact_intent_direction_fraction_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_intent.direction_routing.downlink.capacity_pack_required_capacity_fraction")
           )

    invalid_contact_intent_direction_id =
      put_in(
        artifact_with_contact_intent_summary,
        [
          "provenance",
          "source_reports",
          "contact_intent",
          "contact_ids_by_direction",
          "downlink"
        ],
        ["bad id"]
      )

    assert {:error, invalid_contact_intent_direction_id_report} =
             Schema.validate_artifact(invalid_contact_intent_direction_id)

    assert Enum.any?(
             invalid_contact_intent_direction_id_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_intent.contact_ids_by_direction.downlink[0]")
           )

    invalid_contact_intent_nested_route =
      put_in(
        artifact_with_contact_intent_summary,
        [
          "provenance",
          "source_reports",
          "contact_intent",
          "direction_routing",
          "downlink",
          "contact_ids_by_ground_station",
          "equator_prime"
        ],
        ["stale_intent"]
      )

    assert {:error, invalid_contact_intent_nested_route_report} =
             Schema.validate_artifact(invalid_contact_intent_nested_route)

    assert Enum.any?(
             invalid_contact_intent_nested_route_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_intent.direction_routing.downlink.contact_ids_by_ground_station")
           )

    artifact_with_maneuver_review_summary =
      put_in(artifact, ["provenance", "source_reports", "maneuver_review_report"], %{
        "paths" => ["source_maneuver_review_report"],
        "contract" => "maneuver_review_report.v1",
        "count" => 1,
        "row_count" => 2,
        "maneuver_success_feedback_count" => 1,
        "execution_uncertainty_declared_count" => 1,
        "execution_uncertainty_missing_count" => 0,
        "input_keys" => ["maneuver_success_rate", "maneuver_execution_uncertainty"],
        "maneuver_id_counts" => %{"mnv_raise_apogee" => 2},
        "required_operator_action_counts" => %{"review_maneuver_execution" => 1}
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_maneuver_review_summary)

    maneuver_review_source_report_properties =
      get_in(candidate_refresh_schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "maneuver_review_report",
        "properties"
      ])

    assert get_in(maneuver_review_source_report_properties, [
             "maneuver_success_feedback_count",
             "minimum"
           ]) == 0

    assert get_in(maneuver_review_source_report_properties, [
             "input_keys",
             "items",
             "type"
           ]) == "string"

    assert get_in(maneuver_review_source_report_properties, [
             "maneuver_id_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    invalid_maneuver_review_count =
      put_in(
        artifact_with_maneuver_review_summary,
        [
          "provenance",
          "source_reports",
          "maneuver_review_report",
          "execution_uncertainty_missing_count"
        ],
        -1
      )

    assert {:error, invalid_maneuver_review_count_report} =
             Schema.validate_artifact(invalid_maneuver_review_count)

    assert Enum.any?(
             invalid_maneuver_review_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.maneuver_review_report.execution_uncertainty_missing_count")
           )

    invalid_maneuver_review_id_count =
      put_in(
        artifact_with_maneuver_review_summary,
        [
          "provenance",
          "source_reports",
          "maneuver_review_report",
          "maneuver_id_counts",
          "mnv_raise_apogee"
        ],
        -1
      )

    assert {:error, invalid_maneuver_review_id_count_report} =
             Schema.validate_artifact(invalid_maneuver_review_id_count)

    assert Enum.any?(
             invalid_maneuver_review_id_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.maneuver_review_report.maneuver_id_counts.mnv_raise_apogee")
           )

    invalid_maneuver_review_input_key =
      put_in(
        artifact_with_maneuver_review_summary,
        [
          "provenance",
          "source_reports",
          "maneuver_review_report",
          "input_keys",
          Access.at(0)
        ],
        42
      )

    assert {:error, invalid_maneuver_review_input_key_report} =
             Schema.validate_artifact(invalid_maneuver_review_input_key)

    assert Enum.any?(
             invalid_maneuver_review_input_key_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.maneuver_review_report.input_keys[0]")
           )

    artifact_with_provider_counteroffer_summary =
      put_in(artifact, ["provenance", "source_reports", "provider_counteroffer_report"], %{
        "paths" => ["source_provider_counteroffer_report"],
        "contract" => "provider_counteroffer_report.v1",
        "count" => 1,
        "row_count" => 2,
        "reviewable_count" => 1,
        "counteroffer_cost_delta_count" => 1,
        "counteroffer_cost_delta_total" => 125.5,
        "counteroffer_timing_shift_count" => 1,
        "counteroffer_start_delta_count" => 1,
        "counteroffer_end_delta_count" => 1,
        "counteroffer_duration_delta_count" => 1,
        "counteroffer_lock_deadline_count" => 1,
        "earliest_counteroffer_lock_deadline_s" => 150.0,
        "counteroffer_status_counts" => %{"proposed" => 1},
        "required_operator_action_counts" => %{"review_provider_counteroffer" => 1}
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_provider_counteroffer_summary)

    provider_counteroffer_source_report_properties =
      get_in(candidate_refresh_schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "provider_counteroffer_report",
        "properties"
      ])

    assert get_in(provider_counteroffer_source_report_properties, [
             "reviewable_count",
             "minimum"
           ]) == 0

    assert get_in(provider_counteroffer_source_report_properties, [
             "counteroffer_cost_delta_total",
             "type"
           ]) == "number"

    assert get_in(provider_counteroffer_source_report_properties, [
             "required_operator_action_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    invalid_provider_counteroffer_count =
      put_in(
        artifact_with_provider_counteroffer_summary,
        [
          "provenance",
          "source_reports",
          "provider_counteroffer_report",
          "reviewable_count"
        ],
        -1
      )

    assert {:error, invalid_provider_counteroffer_count_report} =
             Schema.validate_artifact(invalid_provider_counteroffer_count)

    assert Enum.any?(
             invalid_provider_counteroffer_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.provider_counteroffer_report.reviewable_count")
           )

    invalid_provider_counteroffer_status_count =
      put_in(
        artifact_with_provider_counteroffer_summary,
        [
          "provenance",
          "source_reports",
          "provider_counteroffer_report",
          "counteroffer_status_counts",
          "proposed"
        ],
        -1
      )

    assert {:error, invalid_provider_counteroffer_status_count_report} =
             Schema.validate_artifact(invalid_provider_counteroffer_status_count)

    assert Enum.any?(
             invalid_provider_counteroffer_status_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.provider_counteroffer_report.counteroffer_status_counts.proposed")
           )

    invalid_provider_counteroffer_status_counts_shape =
      put_in(
        artifact_with_provider_counteroffer_summary,
        [
          "provenance",
          "source_reports",
          "provider_counteroffer_report",
          "counteroffer_status_counts"
        ],
        "proposed"
      )

    assert {:error, invalid_provider_counteroffer_status_counts_shape_report} =
             Schema.validate_artifact(invalid_provider_counteroffer_status_counts_shape)

    assert Enum.any?(
             invalid_provider_counteroffer_status_counts_shape_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.provider_counteroffer_report.counteroffer_status_counts")
           )

    invalid_provider_counteroffer_required_action_counts_shape =
      put_in(
        artifact_with_provider_counteroffer_summary,
        [
          "provenance",
          "source_reports",
          "provider_counteroffer_report",
          "required_operator_action_counts"
        ],
        "review_provider_counteroffer"
      )

    assert {:error, invalid_provider_counteroffer_required_action_counts_shape_report} =
             Schema.validate_artifact(invalid_provider_counteroffer_required_action_counts_shape)

    assert Enum.any?(
             invalid_provider_counteroffer_required_action_counts_shape_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.provider_counteroffer_report.required_operator_action_counts")
           )

    invalid_provider_counteroffer_total =
      put_in(
        artifact_with_provider_counteroffer_summary,
        [
          "provenance",
          "source_reports",
          "provider_counteroffer_report",
          "counteroffer_cost_delta_total"
        ],
        "125.5"
      )

    assert {:error, invalid_provider_counteroffer_total_report} =
             Schema.validate_artifact(invalid_provider_counteroffer_total)

    assert Enum.any?(
             invalid_provider_counteroffer_total_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.provider_counteroffer_report.counteroffer_cost_delta_total")
           )

    artifact_with_model_acceptance_summary =
      put_in(artifact, ["provenance", "source_reports", "model_acceptance_report"], %{
        "paths" => ["source_model_acceptance_report"],
        "contract" => "model_acceptance_report.v1",
        "count" => 1,
        "row_count" => 4,
        "record_count" => 3,
        "intended_use_counts" => %{"operational_import" => 1},
        "status_counts" => %{"blocked" => 1},
        "model_count" => 4,
        "accepted_count" => 1,
        "review_required_count" => 1,
        "blocked_count" => 2,
        "unknown_model_count" => 1,
        "validation_level_counts" => %{"analysis" => 1, "unknown" => 1},
        "model_ids_by_status" => %{"blocked" => ["propagator.two_body"]},
        "model_ids_by_validation_level" => %{"unknown" => ["missing.model"]},
        "model_ids_by_intended_use" => %{
          "operational_import" => ["propagator.two_body", "missing.model"]
        }
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_model_acceptance_summary)

    model_acceptance_source_report_properties =
      get_in(candidate_refresh_schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "model_acceptance_report",
        "properties"
      ])

    assert get_in(model_acceptance_source_report_properties, [
             "record_count",
             "minimum"
           ]) == 0

    assert get_in(model_acceptance_source_report_properties, [
             "validation_level_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(model_acceptance_source_report_properties, [
             "model_ids_by_status",
             "additionalProperties",
             "items",
             "type"
           ]) == "string"

    invalid_model_acceptance_record_count =
      put_in(
        artifact_with_model_acceptance_summary,
        [
          "provenance",
          "source_reports",
          "model_acceptance_report",
          "record_count"
        ],
        -1
      )

    assert {:error, invalid_model_acceptance_record_count_report} =
             Schema.validate_artifact(invalid_model_acceptance_record_count)

    assert Enum.any?(
             invalid_model_acceptance_record_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.model_acceptance_report.record_count")
           )

    invalid_model_acceptance_status_count =
      put_in(
        artifact_with_model_acceptance_summary,
        [
          "provenance",
          "source_reports",
          "model_acceptance_report",
          "status_counts",
          "blocked"
        ],
        -1
      )

    assert {:error, invalid_model_acceptance_status_count_report} =
             Schema.validate_artifact(invalid_model_acceptance_status_count)

    assert Enum.any?(
             invalid_model_acceptance_status_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.model_acceptance_report.status_counts.blocked")
           )

    invalid_model_acceptance_status_counts_shape =
      put_in(
        artifact_with_model_acceptance_summary,
        [
          "provenance",
          "source_reports",
          "model_acceptance_report",
          "status_counts"
        ],
        "blocked"
      )

    assert {:error, invalid_model_acceptance_status_counts_shape_report} =
             Schema.validate_artifact(invalid_model_acceptance_status_counts_shape)

    assert Enum.any?(
             invalid_model_acceptance_status_counts_shape_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.model_acceptance_report.status_counts")
           )

    invalid_model_acceptance_model_ids_shape =
      put_in(
        artifact_with_model_acceptance_summary,
        [
          "provenance",
          "source_reports",
          "model_acceptance_report",
          "model_ids_by_status"
        ],
        "blocked"
      )

    assert {:error, invalid_model_acceptance_model_ids_shape_report} =
             Schema.validate_artifact(invalid_model_acceptance_model_ids_shape)

    assert Enum.any?(
             invalid_model_acceptance_model_ids_shape_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.model_acceptance_report.model_ids_by_status")
           )

    artifact_with_validation_safety_case_summary =
      put_in(artifact, ["provenance", "source_reports", "validation_safety_case_summary"], %{
        "paths" => ["source_validation_safety_case_summary"],
        "contract" => "validation_safety_case_summary.v1",
        "count" => 1,
        "row_count" => 2,
        "status_counts" => %{"blocked" => 1},
        "evidence_status_counts" => %{"blocked" => 1, "review_required" => 1},
        "input_contract_counts" => %{"model_acceptance_report.v1" => 1},
        "evidence_refs_by_status" => %{
          "blocked" => ["model_acceptance_report.v1:model.blocked"]
        },
        "evidence_refs_by_contract" => %{
          "model_acceptance_report.v1" => ["model_acceptance_report.v1:model.blocked"]
        },
        "accepted_evidence_count" => 0,
        "review_required_evidence_count" => 1,
        "blocked_evidence_count" => 1,
        "model_blocked_count" => 1,
        "schema_warning_count" => 1,
        "fixture_failed_count" => 1
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_validation_safety_case_summary)

    validation_safety_case_source_report_properties =
      get_in(candidate_refresh_schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "validation_safety_case_summary",
        "properties"
      ])

    assert get_in(validation_safety_case_source_report_properties, [
             "blocked_evidence_count",
             "minimum"
           ]) == 0

    assert get_in(validation_safety_case_source_report_properties, [
             "evidence_status_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(validation_safety_case_source_report_properties, [
             "evidence_refs_by_status",
             "additionalProperties",
             "items",
             "type"
           ]) == "string"

    invalid_validation_safety_case_count =
      put_in(
        artifact_with_validation_safety_case_summary,
        [
          "provenance",
          "source_reports",
          "validation_safety_case_summary",
          "blocked_evidence_count"
        ],
        -1
      )

    assert {:error, invalid_validation_safety_case_count_report} =
             Schema.validate_artifact(invalid_validation_safety_case_count)

    assert Enum.any?(
             invalid_validation_safety_case_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.validation_safety_case_summary.blocked_evidence_count")
           )

    invalid_validation_safety_case_evidence_status_count =
      put_in(
        artifact_with_validation_safety_case_summary,
        [
          "provenance",
          "source_reports",
          "validation_safety_case_summary",
          "evidence_status_counts",
          "blocked"
        ],
        -1
      )

    assert {:error, invalid_validation_safety_case_evidence_status_count_report} =
             Schema.validate_artifact(invalid_validation_safety_case_evidence_status_count)

    assert Enum.any?(
             invalid_validation_safety_case_evidence_status_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.validation_safety_case_summary.evidence_status_counts.blocked")
           )

    invalid_validation_safety_case_evidence_status_shape =
      put_in(
        artifact_with_validation_safety_case_summary,
        [
          "provenance",
          "source_reports",
          "validation_safety_case_summary",
          "evidence_status_counts"
        ],
        "blocked"
      )

    assert {:error, invalid_validation_safety_case_evidence_status_shape_report} =
             Schema.validate_artifact(invalid_validation_safety_case_evidence_status_shape)

    assert Enum.any?(
             invalid_validation_safety_case_evidence_status_shape_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.validation_safety_case_summary.evidence_status_counts")
           )

    invalid_validation_safety_case_evidence_ref =
      put_in(
        artifact_with_validation_safety_case_summary,
        [
          "provenance",
          "source_reports",
          "validation_safety_case_summary",
          "evidence_refs_by_status",
          "blocked"
        ],
        ["model_acceptance_report.v1:model.blocked", 42]
      )

    assert {:error, invalid_validation_safety_case_evidence_ref_report} =
             Schema.validate_artifact(invalid_validation_safety_case_evidence_ref)

    assert Enum.any?(
             invalid_validation_safety_case_evidence_ref_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.validation_safety_case_summary.evidence_refs_by_status.blocked")
           )
  end

  test "validates quality, timeline, resource, and feedback source-report provenance contracts" do
    artifact = read_json!("study_results/candidate_refresh_resource_provenance_v1.json")
    assert {:ok, candidate_refresh_schema} = Schema.json_schema("candidate_refresh.v1")

    artifact_with_timeline_transition_application_summary =
      put_in(
        artifact,
        ["provenance", "source_reports", "timeline_transition_application_report"],
        %{
          "paths" => ["source_timeline_transition_application_report"],
          "contract" => "timeline_transition_application_report.v1",
          "count" => 1,
          "row_count" => 3,
          "application_count" => 3,
          "selected_activity_count" => 1,
          "selected_activity_id_counts" => %{"activity.transition.selected" => 1},
          "review_activity_id_counts" => %{"activity.transition.review" => 2},
          "review_required_count" => 2,
          "preserved_source_count" => 1,
          "recorded_replacement_count" => 1,
          "withheld_review_count" => 1,
          "duplicate_timeline_identity_count" => 1,
          "duplicate_source_timeline_identity_count" => 1,
          "duplicate_replacement_timeline_identity_count" => 0,
          "application_status_counts" => %{"review_required" => 2, "applied" => 1},
          "transition_decision_counts" => %{"preserve_source" => 1},
          "required_operator_action_counts" => %{"review_timeline_transition" => 2},
          "duplicate_timeline_identity_scope_counts" => %{"source" => 1}
        }
      )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_timeline_transition_application_summary)

    timeline_transition_application_source_report_properties =
      get_in(candidate_refresh_schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "timeline_transition_application_report",
        "properties"
      ])

    assert get_in(timeline_transition_application_source_report_properties, [
             "application_count",
             "minimum"
           ]) == 0

    assert get_in(timeline_transition_application_source_report_properties, [
             "application_status_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(timeline_transition_application_source_report_properties, [
             "duplicate_timeline_identity_scope_counts",
             "additionalProperties",
             "type"
           ]) == "integer"

    invalid_timeline_transition_application_count =
      put_in(
        artifact_with_timeline_transition_application_summary,
        [
          "provenance",
          "source_reports",
          "timeline_transition_application_report",
          "application_count"
        ],
        -1
      )

    assert {:error, invalid_timeline_transition_application_count_report} =
             Schema.validate_artifact(invalid_timeline_transition_application_count)

    assert Enum.any?(
             invalid_timeline_transition_application_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_transition_application_report.application_count")
           )

    invalid_timeline_transition_application_status_count =
      put_in(
        artifact_with_timeline_transition_application_summary,
        [
          "provenance",
          "source_reports",
          "timeline_transition_application_report",
          "application_status_counts",
          "review_required"
        ],
        -1
      )

    assert {:error, invalid_timeline_transition_application_status_count_report} =
             Schema.validate_artifact(invalid_timeline_transition_application_status_count)

    assert Enum.any?(
             invalid_timeline_transition_application_status_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_transition_application_report.application_status_counts.review_required")
           )

    invalid_timeline_transition_application_status_shape =
      put_in(
        artifact_with_timeline_transition_application_summary,
        [
          "provenance",
          "source_reports",
          "timeline_transition_application_report",
          "application_status_counts"
        ],
        "review_required"
      )

    assert {:error, invalid_timeline_transition_application_status_shape_report} =
             Schema.validate_artifact(invalid_timeline_transition_application_status_shape)

    assert Enum.any?(
             invalid_timeline_transition_application_status_shape_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_transition_application_report.application_status_counts")
           )

    artifact_with_quality_gate_summary =
      put_in(artifact, ["provenance", "source_reports", "quality_gate_report"], %{
        "paths" => ["source_quality_gate_report"],
        "contract" => "quality_gate_report.v1",
        "count" => 1,
        "row_count" => 3,
        "readiness_level_counts" => %{"blocked" => 1},
        "import_classification_counts" => %{"review_only" => 1},
        "status_counts" => %{"review_required" => 1},
        "gate_count" => 3,
        "passed_gate_count" => 1,
        "review_gate_count" => 1,
        "analysis_gate_count" => 1,
        "blocked_gate_count" => 1,
        "gate_status_counts" => %{"review_required" => 1, "blocked" => 1},
        "gate_classification_counts" => %{"review_only" => 1},
        "ready_for_import_count" => 1,
        "manifest_review_required_count" => 1,
        "blocked_import_count" => 1,
        "missing_import_count" => 1,
        "invalid_cadence_import_count" => 1,
        "freshness_status_counts" => %{"stale" => 1},
        "schema_validation_status_counts" => %{"fail" => 1},
        "import_status_counts" => %{"review_required_before_import" => 1},
        "cadence_import_status_counts" => %{"missing" => 1},
        "resource_availability_pressure_count" => 2,
        "resource_availability_reason_counts" => %{
          "ground_station_reserved" => 1,
          "payload_unavailable" => 1
        },
        "resource_availability_reason_ids" => [
          "ground_station_reserved",
          "payload_unavailable"
        ],
        "station_availability_reason_counts" => %{"ground_station_reserved" => 1},
        "station_availability_reason_ids" => ["ground_station_reserved"],
        "unavailable_resource_reason_ids" => ["payload_unavailable"],
        "resource_blocking_dimension_counts" => %{"communications" => 1},
        "quality_gate_row_ids_by_status" => %{
          "review_required" => ["quality_gate:review_row"]
        },
        "quality_gate_ids_by_status" => %{
          "review_required" => ["quality_gate:review"]
        },
        "review_required_quality_gate_row_ids" => ["quality_gate:review_row"],
        "blocked_quality_gate_row_ids" => ["quality_gate:blocked_row"],
        "ready_quality_gate_row_ids" => ["quality_gate:ready_row"],
        "analysis_only_quality_gate_row_ids" => ["quality_gate:analysis_row"],
        "stale_or_unknown_freshness_quality_gate_row_ids" => ["quality_gate:freshness_row"],
        "import_preparation_quality_gate_row_ids" => ["quality_gate:import_row"],
        "blocked_import_quality_gate_row_ids" => ["quality_gate:blocked_import_row"],
        "import_readiness_gate_ids" => ["quality_gate:import_gate"],
        "source_readiness_report_count" => 1
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_quality_gate_summary)

    quality_gate_source_report_properties =
      get_in(candidate_refresh_schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "quality_gate_report",
        "properties"
      ])

    assert get_in(quality_gate_source_report_properties, [
             "gate_count",
             "minimum"
           ]) == 0

    assert get_in(quality_gate_source_report_properties, [
             "gate_status_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(quality_gate_source_report_properties, [
             "quality_gate_row_ids_by_status",
             "additionalProperties",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    invalid_quality_gate_count =
      put_in(
        artifact_with_quality_gate_summary,
        ["provenance", "source_reports", "quality_gate_report", "gate_count"],
        -1
      )

    assert {:error, invalid_quality_gate_count_report} =
             Schema.validate_artifact(invalid_quality_gate_count)

    assert Enum.any?(
             invalid_quality_gate_count_report["errors"],
             &(&1["path"] == "$.provenance.source_reports.quality_gate_report.gate_count")
           )

    invalid_quality_gate_status_count =
      put_in(
        artifact_with_quality_gate_summary,
        [
          "provenance",
          "source_reports",
          "quality_gate_report",
          "gate_status_counts",
          "blocked"
        ],
        -1
      )

    assert {:error, invalid_quality_gate_status_count_report} =
             Schema.validate_artifact(invalid_quality_gate_status_count)

    assert Enum.any?(
             invalid_quality_gate_status_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.quality_gate_report.gate_status_counts.blocked")
           )

    invalid_quality_gate_status_shape =
      put_in(
        artifact_with_quality_gate_summary,
        ["provenance", "source_reports", "quality_gate_report", "gate_status_counts"],
        "blocked"
      )

    assert {:error, invalid_quality_gate_status_shape_report} =
             Schema.validate_artifact(invalid_quality_gate_status_shape)

    assert Enum.any?(
             invalid_quality_gate_status_shape_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.quality_gate_report.gate_status_counts")
           )

    invalid_quality_gate_row_id =
      put_in(
        artifact_with_quality_gate_summary,
        [
          "provenance",
          "source_reports",
          "quality_gate_report",
          "quality_gate_row_ids_by_status",
          "review_required"
        ],
        ["quality_gate:review_row", 42]
      )

    assert {:error, invalid_quality_gate_row_id_report} =
             Schema.validate_artifact(invalid_quality_gate_row_id)

    assert Enum.any?(
             invalid_quality_gate_row_id_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.quality_gate_report.quality_gate_row_ids_by_status.review_required[1]")
           )

    artifact_with_schema_validation_summary =
      put_in(artifact, ["provenance", "source_reports", "schema_validation_report"], %{
        "paths" => ["source_schema_validation_report"],
        "contract" => "schema_validation_report.v1",
        "count" => 2,
        "row_count" => 2,
        "status_counts" => %{"fail" => 1, "pass" => 1},
        "validated_contract_counts" => %{"candidate_refresh.v1" => 1},
        "validation_mode_counts" => %{"artifact" => 1},
        "error_count" => 2,
        "warning_count" => 1,
        "remediation_count" => 2,
        "remediation_action_counts" => %{"populate_id" => 1},
        "remediation_category_counts" => %{"missing_required_field" => 1},
        "remediation_path_counts" => %{"$.candidate_activities[0].id" => 1}
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_schema_validation_summary)

    schema_validation_source_report_properties =
      get_in(candidate_refresh_schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "schema_validation_report",
        "properties"
      ])

    assert get_in(schema_validation_source_report_properties, [
             "error_count",
             "minimum"
           ]) == 0

    assert get_in(schema_validation_source_report_properties, [
             "validated_contract_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(schema_validation_source_report_properties, [
             "remediation_path_counts",
             "additionalProperties",
             "type"
           ]) == "integer"

    invalid_schema_validation_error_count =
      put_in(
        artifact_with_schema_validation_summary,
        ["provenance", "source_reports", "schema_validation_report", "error_count"],
        -1
      )

    assert {:error, invalid_schema_validation_error_count_report} =
             Schema.validate_artifact(invalid_schema_validation_error_count)

    assert Enum.any?(
             invalid_schema_validation_error_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.schema_validation_report.error_count")
           )

    invalid_schema_validation_status_count =
      put_in(
        artifact_with_schema_validation_summary,
        [
          "provenance",
          "source_reports",
          "schema_validation_report",
          "status_counts",
          "fail"
        ],
        -1
      )

    assert {:error, invalid_schema_validation_status_count_report} =
             Schema.validate_artifact(invalid_schema_validation_status_count)

    assert Enum.any?(
             invalid_schema_validation_status_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.schema_validation_report.status_counts.fail")
           )

    invalid_schema_validation_status_shape =
      put_in(
        artifact_with_schema_validation_summary,
        ["provenance", "source_reports", "schema_validation_report", "status_counts"],
        "fail"
      )

    assert {:error, invalid_schema_validation_status_shape_report} =
             Schema.validate_artifact(invalid_schema_validation_status_shape)

    assert Enum.any?(
             invalid_schema_validation_status_shape_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.schema_validation_report.status_counts")
           )

    artifact_with_timeline_diff_summary =
      put_in(artifact, ["provenance", "source_reports", "timeline_diff_report"], %{
        "paths" => ["source_timeline_diff_report"],
        "contract" => "timeline_diff_report.v1",
        "count" => 1,
        "row_count" => 3,
        "duplicate_timeline_identity_count" => 1,
        "duplicate_source_timeline_identity_count" => 1,
        "duplicate_replacement_timeline_identity_count" => 1,
        "removed_downlink_count" => 1,
        "removed_observation_count" => 1,
        "changed_downlink_shortfall_count" => 1,
        "changed_contact_feedback_count" => 1,
        "changed_observation_count" => 1,
        "changed_observation_quality_feedback_count" => 1,
        "changed_command_feedback_count" => 1,
        "changed_maneuver_feedback_count" => 1,
        "diff_status_counts" => %{"changed" => 1},
        "required_operator_action_counts" => %{"review_removed_downlink" => 1},
        "duplicate_timeline_identity_scope_counts" => %{"source" => 1},
        "source_activity_id_counts" => %{"source_downlink" => 1},
        "replacement_activity_id_counts" => %{"replacement_downlink" => 1}
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_timeline_diff_summary)

    timeline_diff_source_report_properties =
      get_in(candidate_refresh_schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "timeline_diff_report",
        "properties"
      ])

    assert get_in(timeline_diff_source_report_properties, [
             "removed_downlink_count",
             "minimum"
           ]) == 0

    assert get_in(timeline_diff_source_report_properties, [
             "diff_status_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(timeline_diff_source_report_properties, [
             "source_activity_id_counts",
             "additionalProperties",
             "type"
           ]) == "integer"

    invalid_timeline_diff_removed_count =
      put_in(
        artifact_with_timeline_diff_summary,
        ["provenance", "source_reports", "timeline_diff_report", "removed_downlink_count"],
        -1
      )

    assert {:error, invalid_timeline_diff_removed_count_report} =
             Schema.validate_artifact(invalid_timeline_diff_removed_count)

    assert Enum.any?(
             invalid_timeline_diff_removed_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_diff_report.removed_downlink_count")
           )

    invalid_timeline_diff_status_count =
      put_in(
        artifact_with_timeline_diff_summary,
        [
          "provenance",
          "source_reports",
          "timeline_diff_report",
          "diff_status_counts",
          "changed"
        ],
        -1
      )

    assert {:error, invalid_timeline_diff_status_count_report} =
             Schema.validate_artifact(invalid_timeline_diff_status_count)

    assert Enum.any?(
             invalid_timeline_diff_status_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_diff_report.diff_status_counts.changed")
           )

    invalid_timeline_diff_status_shape =
      put_in(
        artifact_with_timeline_diff_summary,
        ["provenance", "source_reports", "timeline_diff_report", "diff_status_counts"],
        "changed"
      )

    assert {:error, invalid_timeline_diff_status_shape_report} =
             Schema.validate_artifact(invalid_timeline_diff_status_shape)

    assert Enum.any?(
             invalid_timeline_diff_status_shape_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_diff_report.diff_status_counts")
           )

    artifact_with_operational_timeline_summary =
      put_in(artifact, ["provenance", "source_reports", "operational_timeline_report"], %{
        "paths" => ["source_operational_timeline_report"],
        "contract" => "operational_timeline_report.v1",
        "count" => 1,
        "row_count" => 2,
        "input_keys" => ["contact_success_rate"],
        "contact_feedback_count" => 1,
        "command_feedback_count" => 1,
        "maneuver_feedback_count" => 1,
        "observation_feedback_count" => 1,
        "station_throughput_feedback_count" => 1,
        "operational_kind_counts" => %{"contact" => 1},
        "activity_id_counts" => %{"ops_contact_feedback" => 1},
        "activity_status_counts" => %{"planned" => 1},
        "approval_status_counts" => %{"not_evaluated" => 1},
        "required_operator_action_counts" => %{"review_activity_approval" => 1},
        "cadence_import_status_counts" => %{"missing" => 1},
        "timeline_integrity_issue_count" => 1,
        "dependency_integrity_issue_count" => 1,
        "exclusivity_integrity_issue_count" => 1,
        "timeline_integrity_issue_type_counts" => %{"dependency_gap" => 1},
        "station_reservation_evidence_row_count" => 1,
        "station_reservation_expiration_evidence_row_count" => 1
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_operational_timeline_summary)

    operational_timeline_source_report_properties =
      get_in(candidate_refresh_schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "operational_timeline_report",
        "properties"
      ])

    assert get_in(operational_timeline_source_report_properties, [
             "input_keys",
             "items",
             "type"
           ]) == "string"

    assert get_in(operational_timeline_source_report_properties, [
             "contact_feedback_count",
             "minimum"
           ]) == 0

    assert get_in(operational_timeline_source_report_properties, [
             "operational_kind_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    invalid_operational_timeline_input_key =
      put_in(
        artifact_with_operational_timeline_summary,
        [
          "provenance",
          "source_reports",
          "operational_timeline_report",
          "input_keys",
          Access.at(0)
        ],
        42
      )

    assert {:error, invalid_operational_timeline_input_key_report} =
             Schema.validate_artifact(invalid_operational_timeline_input_key)

    assert Enum.any?(
             invalid_operational_timeline_input_key_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.operational_timeline_report.input_keys[0]")
           )

    invalid_operational_timeline_feedback_count =
      put_in(
        artifact_with_operational_timeline_summary,
        [
          "provenance",
          "source_reports",
          "operational_timeline_report",
          "contact_feedback_count"
        ],
        -1
      )

    assert {:error, invalid_operational_timeline_feedback_count_report} =
             Schema.validate_artifact(invalid_operational_timeline_feedback_count)

    assert Enum.any?(
             invalid_operational_timeline_feedback_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.operational_timeline_report.contact_feedback_count")
           )

    invalid_operational_timeline_count =
      put_in(
        artifact_with_operational_timeline_summary,
        [
          "provenance",
          "source_reports",
          "operational_timeline_report",
          "operational_kind_counts",
          "contact"
        ],
        -1
      )

    assert {:error, invalid_operational_timeline_count_report} =
             Schema.validate_artifact(invalid_operational_timeline_count)

    assert Enum.any?(
             invalid_operational_timeline_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.operational_timeline_report.operational_kind_counts.contact")
           )

    invalid_operational_timeline_count_shape =
      put_in(
        artifact_with_operational_timeline_summary,
        [
          "provenance",
          "source_reports",
          "operational_timeline_report",
          "activity_status_counts"
        ],
        "planned"
      )

    assert {:error, invalid_operational_timeline_count_shape_report} =
             Schema.validate_artifact(invalid_operational_timeline_count_shape)

    assert Enum.any?(
             invalid_operational_timeline_count_shape_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.operational_timeline_report.activity_status_counts")
           )

    artifact_with_timeline_feedback_summary =
      put_in(artifact, ["provenance", "source_reports", "timeline_feedback_report"], %{
        "paths" => ["source_timeline_feedback_report"],
        "contract" => "timeline_feedback_report.v1",
        "count" => 1,
        "row_count" => 2,
        "input_keys" => ["source_timeline_feedback_report"],
        "status_counts" => %{"accepted" => 1},
        "feedback_kind_counts" => %{"activity_feedback" => 1},
        "match_strategy_counts" => %{"activity_id" => 1},
        "activity_id_counts" => %{"act_downlink" => 1},
        "cadence_import_status_counts" => %{"ready" => 1},
        "station_reservation_evidence_row_count" => 1,
        "station_reservation_expiration_evidence_row_count" => 1
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_timeline_feedback_summary)

    timeline_feedback_source_report_properties =
      get_in(candidate_refresh_schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "timeline_feedback_report",
        "properties"
      ])

    assert get_in(timeline_feedback_source_report_properties, [
             "input_keys",
             "items",
             "type"
           ]) == "string"

    assert get_in(timeline_feedback_source_report_properties, [
             "feedback_kind_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(timeline_feedback_source_report_properties, [
             "station_reservation_evidence_row_count",
             "minimum"
           ]) == 0

    invalid_timeline_feedback_input_key =
      put_in(
        artifact_with_timeline_feedback_summary,
        [
          "provenance",
          "source_reports",
          "timeline_feedback_report",
          "input_keys",
          Access.at(0)
        ],
        42
      )

    assert {:error, invalid_timeline_feedback_input_key_report} =
             Schema.validate_artifact(invalid_timeline_feedback_input_key)

    assert Enum.any?(
             invalid_timeline_feedback_input_key_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_feedback_report.input_keys[0]")
           )

    invalid_timeline_feedback_count =
      put_in(
        artifact_with_timeline_feedback_summary,
        [
          "provenance",
          "source_reports",
          "timeline_feedback_report",
          "feedback_kind_counts",
          "activity_feedback"
        ],
        -1
      )

    assert {:error, invalid_timeline_feedback_count_report} =
             Schema.validate_artifact(invalid_timeline_feedback_count)

    assert Enum.any?(
             invalid_timeline_feedback_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_feedback_report.feedback_kind_counts.activity_feedback")
           )

    invalid_timeline_feedback_count_shape =
      put_in(
        artifact_with_timeline_feedback_summary,
        [
          "provenance",
          "source_reports",
          "timeline_feedback_report",
          "match_strategy_counts"
        ],
        "activity_id"
      )

    assert {:error, invalid_timeline_feedback_count_shape_report} =
             Schema.validate_artifact(invalid_timeline_feedback_count_shape)

    assert Enum.any?(
             invalid_timeline_feedback_count_shape_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_feedback_report.match_strategy_counts")
           )

    invalid_timeline_feedback_station_reservation_count =
      put_in(
        artifact_with_timeline_feedback_summary,
        [
          "provenance",
          "source_reports",
          "timeline_feedback_report",
          "station_reservation_evidence_row_count"
        ],
        -1
      )

    assert {:error, invalid_timeline_feedback_station_reservation_count_report} =
             Schema.validate_artifact(invalid_timeline_feedback_station_reservation_count)

    assert Enum.any?(
             invalid_timeline_feedback_station_reservation_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_feedback_report.station_reservation_evidence_row_count")
           )

    artifact_with_link_capacity_summary =
      put_in(artifact, ["provenance", "source_reports", "link_capacity_report"], %{
        "paths" => ["source_link_capacity_report"],
        "contract" => "link_capacity_report.v1",
        "count" => 1,
        "row_count" => 1,
        "ground_station_counts" => %{"equator_prime" => 1},
        "selected_contact_id_counts" => %{"dl_selected" => 1},
        "actual_throughput_contact_id_counts" => %{"dl_actual" => 1}
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_link_capacity_summary)

    invalid_link_capacity_contact_count =
      put_in(
        artifact_with_link_capacity_summary,
        [
          "provenance",
          "source_reports",
          "link_capacity_report",
          "selected_contact_id_counts",
          "dl_selected"
        ],
        -1
      )

    assert {:error, invalid_link_capacity_contact_count_report} =
             Schema.validate_artifact(invalid_link_capacity_contact_count)

    assert Enum.any?(
             invalid_link_capacity_contact_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.link_capacity_report.selected_contact_id_counts.dl_selected")
           )

    artifact_with_constraint_summary =
      put_in(artifact, ["provenance", "source_reports", "constraint_report"], %{
        "paths" => ["source_constraint_report"],
        "contract" => "constraint_report.v1",
        "count" => 1,
        "row_count" => 2,
        "ground_station_counts" => %{"equator_prime" => 1},
        "constraint_metric_counts" => %{"battery_margin" => 1},
        "constraint_resource_counts" => %{"battery_1" => 1},
        "constraint_spacecraft_counts" => %{"leo_1" => 1}
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_constraint_summary)

    invalid_constraint_resource_count =
      put_in(
        artifact_with_constraint_summary,
        [
          "provenance",
          "source_reports",
          "constraint_report",
          "constraint_resource_counts",
          "battery_1"
        ],
        -1
      )

    assert {:error, invalid_constraint_resource_count_report} =
             Schema.validate_artifact(invalid_constraint_resource_count)

    assert Enum.any?(
             invalid_constraint_resource_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.constraint_report.constraint_resource_counts.battery_1")
           )

    artifact_with_resource_projection_summary =
      put_in(artifact, ["provenance", "source_reports", "resource_projection_report"], %{
        "paths" => ["source_resource_projection_report"],
        "contract" => "resource_projection_report.v1",
        "count" => 1,
        "row_count" => 2,
        "ground_station_counts" => %{"equator_prime" => 1},
        "resource_projection_spacecraft_counts" => %{"leo_1" => 2},
        "resource_pressure_type_counts" => %{"downlink_shortfall" => 1},
        "resource_pressure_activity_id_counts" => %{"dl_pressure_1" => 1}
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_resource_projection_summary)

    invalid_resource_projection_type_count =
      put_in(
        artifact_with_resource_projection_summary,
        [
          "provenance",
          "source_reports",
          "resource_projection_report",
          "resource_pressure_type_counts",
          "downlink_shortfall"
        ],
        -1
      )

    assert {:error, invalid_resource_projection_type_count_report} =
             Schema.validate_artifact(invalid_resource_projection_type_count)

    assert Enum.any?(
             invalid_resource_projection_type_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.resource_projection_report.resource_pressure_type_counts.downlink_shortfall")
           )

    artifact_with_resource_filter_summary =
      put_in(artifact, ["provenance", "source_reports", "resource_filter_report"], %{
        "paths" => ["source_resource_filter_report"],
        "contract" => "resource_filter_report.v1",
        "count" => 1,
        "row_count" => 1,
        "invalid_resource_summary_input_ids" => ["bad_resource_summary"],
        "resource_filter_spacecraft_counts" => %{"sat_1" => 1},
        "resource_filter_resource_counts" => %{"payload_1" => 1},
        "resource_filter_blocking_dimension_counts" => %{"payload" => 1}
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_resource_filter_summary)

    invalid_resource_filter_dimension_count =
      put_in(
        artifact_with_resource_filter_summary,
        [
          "provenance",
          "source_reports",
          "resource_filter_report",
          "resource_filter_blocking_dimension_counts",
          "payload"
        ],
        -1
      )

    assert {:error, invalid_resource_filter_dimension_count_report} =
             Schema.validate_artifact(invalid_resource_filter_dimension_count)

    assert Enum.any?(
             invalid_resource_filter_dimension_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.resource_filter_report.resource_filter_blocking_dimension_counts.payload")
           )

    invalid_resource_filter_summary_id =
      put_in(
        artifact_with_resource_filter_summary,
        [
          "provenance",
          "source_reports",
          "resource_filter_report",
          "invalid_resource_summary_input_ids",
          Access.at(0)
        ],
        "bad summary"
      )

    assert {:error, invalid_resource_filter_summary_id_report} =
             Schema.validate_artifact(invalid_resource_filter_summary_id)

    assert Enum.any?(
             invalid_resource_filter_summary_id_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.resource_filter_report.invalid_resource_summary_input_ids[0]")
           )

    artifact_with_contact_contention_summary =
      put_in(artifact, ["provenance", "source_reports", "contact_contention_report"], %{
        "paths" => ["source_contact_contention_report"],
        "contract" => "contact_contention_report.v1",
        "count" => 1,
        "row_count" => 1,
        "conflict_group_count" => 1,
        "invalid_contact_input_count" => 1,
        "invalid_contact_input_ids" => ["bad_contact"],
        "resource_scope_counts" => %{"ground_station" => 1},
        "contact_contention_ground_station_counts" => %{"equator_prime" => 1},
        "contact_contention_contact_id_counts" => %{"dl_primary" => 1, "dl_backup" => 1},
        "direction_counts" => %{"downlink" => 2},
        "contact_ids_by_direction" => %{
          "downlink" => ["dl_backup", "dl_primary"]
        },
        "direction_routing" => %{
          "downlink" => %{
            "contact_count" => 2,
            "contact_ids" => ["dl_backup", "dl_primary"]
          }
        },
        "required_operator_action_counts" => %{
          "review_contact_contention" => 1,
          "review_invalid_contact_contention_input" => 1
        }
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_contact_contention_summary)

    stale_contact_contention_direction_route =
      put_in(
        artifact_with_contact_contention_summary,
        [
          "provenance",
          "source_reports",
          "contact_contention_report",
          "direction_routing",
          "downlink",
          "contact_count"
        ],
        99
      )

    assert {:error, stale_contact_contention_direction_route_report} =
             Schema.validate_artifact(stale_contact_contention_direction_route)

    assert Enum.any?(
             stale_contact_contention_direction_route_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_contention_report.direction_routing")
           )

    invalid_contact_contention_contact_count =
      put_in(
        artifact_with_contact_contention_summary,
        [
          "provenance",
          "source_reports",
          "contact_contention_report",
          "contact_contention_contact_id_counts",
          "dl_primary"
        ],
        -1
      )

    assert {:error, invalid_contact_contention_contact_count_report} =
             Schema.validate_artifact(invalid_contact_contention_contact_count)

    assert Enum.any?(
             invalid_contact_contention_contact_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_contention_report.contact_contention_contact_id_counts.dl_primary")
           )

    non_positive_contact_contention_direction =
      put_in(
        artifact_with_contact_contention_summary,
        [
          "provenance",
          "source_reports",
          "contact_contention_report",
          "direction_counts",
          "downlink"
        ],
        0
      )

    assert {:error, non_positive_contact_contention_direction_report} =
             Schema.validate_artifact(non_positive_contact_contention_direction)

    assert Enum.any?(
             non_positive_contact_contention_direction_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_contention_report.direction_counts.downlink")
           )

    noncanonical_contact_contention_direction =
      update_in(
        artifact_with_contact_contention_summary,
        [
          "provenance",
          "source_reports",
          "contact_contention_report",
          "direction_counts"
        ],
        fn counts -> counts |> Map.delete("downlink") |> Map.put("Down Link", 2) end
      )

    assert {:error, noncanonical_contact_contention_direction_report} =
             Schema.validate_artifact(noncanonical_contact_contention_direction)

    assert Enum.any?(
             noncanonical_contact_contention_direction_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_contention_report.direction_counts.Down Link")
           )

    over_cardinality_contact_contention_direction =
      artifact_with_contact_contention_summary
      |> put_in(
        [
          "provenance",
          "source_reports",
          "contact_contention_report",
          "direction_counts",
          "downlink"
        ],
        1
      )
      |> put_in(
        [
          "provenance",
          "source_reports",
          "contact_contention_report",
          "direction_counts",
          "uplink"
        ],
        1
      )

    assert {:error, over_cardinality_contact_contention_direction_report} =
             Schema.validate_artifact(over_cardinality_contact_contention_direction)

    assert Enum.any?(
             over_cardinality_contact_contention_direction_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_contention_report.contact_ids_by_direction.downlink")
           )

    invalid_contact_contention_input_id =
      put_in(
        artifact_with_contact_contention_summary,
        [
          "provenance",
          "source_reports",
          "contact_contention_report",
          "invalid_contact_input_ids",
          Access.at(0)
        ],
        "bad contact"
      )

    assert {:error, invalid_contact_contention_input_id_report} =
             Schema.validate_artifact(invalid_contact_contention_input_id)

    assert Enum.any?(
             invalid_contact_contention_input_id_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_contention_report.invalid_contact_input_ids[0]")
           )

    mismatched_contact_contention_input_count =
      put_in(
        artifact_with_contact_contention_summary,
        [
          "provenance",
          "source_reports",
          "contact_contention_report",
          "invalid_contact_input_count"
        ],
        2
      )

    assert {:error, mismatched_contact_contention_input_count_report} =
             Schema.validate_artifact(mismatched_contact_contention_input_count)

    assert Enum.any?(
             mismatched_contact_contention_input_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_contention_report.invalid_contact_input_ids")
           )

    mismatched_contact_contention_action_count =
      put_in(
        artifact_with_contact_contention_summary,
        [
          "provenance",
          "source_reports",
          "contact_contention_report",
          "required_operator_action_counts",
          "review_contact_contention"
        ],
        2
      )

    assert {:error, mismatched_contact_contention_action_count_report} =
             Schema.validate_artifact(mismatched_contact_contention_action_count)

    assert Enum.any?(
             mismatched_contact_contention_action_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_contention_report.required_operator_action_counts.review_contact_contention")
           )

    overcounted_contact_contention_scope =
      put_in(
        artifact_with_contact_contention_summary,
        [
          "provenance",
          "source_reports",
          "contact_contention_report",
          "resource_scope_counts",
          "ground_station"
        ],
        2
      )

    assert {:error, overcounted_contact_contention_scope_report} =
             Schema.validate_artifact(overcounted_contact_contention_scope)

    assert Enum.any?(
             overcounted_contact_contention_scope_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_contention_report.resource_scope_counts")
           )

    overcounted_contact_contention_station =
      put_in(
        artifact_with_contact_contention_summary,
        [
          "provenance",
          "source_reports",
          "contact_contention_report",
          "contact_contention_ground_station_counts",
          "equator_prime"
        ],
        2
      )

    assert {:error, overcounted_contact_contention_station_report} =
             Schema.validate_artifact(overcounted_contact_contention_station)

    assert Enum.any?(
             overcounted_contact_contention_station_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_contention_report.contact_contention_ground_station_counts")
           )

    overcounted_contact_contention_contact =
      put_in(
        artifact_with_contact_contention_summary,
        [
          "provenance",
          "source_reports",
          "contact_contention_report",
          "contact_contention_contact_id_counts",
          "dl_primary"
        ],
        3
      )

    assert {:error, overcounted_contact_contention_contact_report} =
             Schema.validate_artifact(overcounted_contact_contention_contact)

    assert Enum.any?(
             overcounted_contact_contention_contact_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_contention_report.contact_contention_contact_id_counts")
           )

    artifact_with_candidate_rejection_summary =
      put_in(artifact, ["provenance", "source_reports", "candidate_rejection_report"], %{
        "paths" => ["source_candidate_rejection_report"],
        "contract" => "candidate_rejection_report.v1",
        "count" => 1,
        "row_count" => 1,
        "candidate_rejection_candidate_id_counts" => %{"dl_reserved" => 1},
        "candidate_rejection_ground_station_counts" => %{"unused_station" => 1}
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_candidate_rejection_summary)

    invalid_candidate_rejection_station_count =
      put_in(
        artifact_with_candidate_rejection_summary,
        [
          "provenance",
          "source_reports",
          "candidate_rejection_report",
          "candidate_rejection_ground_station_counts",
          "unused_station"
        ],
        -1
      )

    assert {:error, invalid_candidate_rejection_station_count_report} =
             Schema.validate_artifact(invalid_candidate_rejection_station_count)

    assert Enum.any?(
             invalid_candidate_rejection_station_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.candidate_rejection_report.candidate_rejection_ground_station_counts.unused_station")
           )

    artifact_with_objective_summary =
      put_in(artifact, ["provenance", "source_reports", "objective_satisfaction_report"], %{
        "paths" => ["source_objective_satisfaction_report"],
        "contract" => "objective_satisfaction_report.v1",
        "count" => 1,
        "row_count" => 3,
        "ground_station_counts" => %{"equator_prime" => 1},
        "target_counts" => %{"target_alpha" => 1},
        "collection_counts" => %{"collection_day_1" => 1}
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_objective_summary)

    invalid_objective_target_count =
      put_in(
        artifact_with_objective_summary,
        [
          "provenance",
          "source_reports",
          "objective_satisfaction_report",
          "target_counts",
          "target_alpha"
        ],
        -1
      )

    assert {:error, invalid_objective_target_count_report} =
             Schema.validate_artifact(invalid_objective_target_count)

    assert Enum.any?(
             invalid_objective_target_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.objective_satisfaction_report.target_counts.target_alpha")
           )

    artifact_with_contact_filter_summary =
      put_in(artifact, ["provenance", "source_reports", "contact_filter_report"], %{
        "paths" => ["source_contact_filter_report"],
        "contract" => "contact_filter_report.v1",
        "count" => 1,
        "row_count" => 1,
        "invalid_contact_input_ids" => ["bad_contact"],
        "station_suppression_count" => 1,
        "station_suppression_ground_station_counts" => %{"equator_prime" => 1},
        "station_suppression_availability_counts" => %{"unavailable" => 1},
        "station_suppression_status_counts" => %{"unavailable" => 1}
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_contact_filter_summary)

    invalid_contact_filter_status_count =
      put_in(
        artifact_with_contact_filter_summary,
        [
          "provenance",
          "source_reports",
          "contact_filter_report",
          "station_suppression_status_counts",
          "unavailable"
        ],
        -1
      )

    assert {:error, invalid_contact_filter_status_count_report} =
             Schema.validate_artifact(invalid_contact_filter_status_count)

    assert Enum.any?(
             invalid_contact_filter_status_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_filter_report.station_suppression_status_counts.unavailable")
           )

    invalid_contact_filter_input_id =
      put_in(
        artifact_with_contact_filter_summary,
        [
          "provenance",
          "source_reports",
          "contact_filter_report",
          "invalid_contact_input_ids",
          Access.at(0)
        ],
        "bad contact"
      )

    assert {:error, invalid_contact_filter_input_id_report} =
             Schema.validate_artifact(invalid_contact_filter_input_id)

    assert Enum.any?(
             invalid_contact_filter_input_id_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.contact_filter_report.invalid_contact_input_ids[0]")
           )
  end

  test "validates timeline lifecycle, publication, and reservation evidence provenance contracts" do
    artifact = read_json!("study_results/candidate_refresh_resource_provenance_v1.json")

    artifact_with_timeline_activity_state_summary =
      put_in(artifact, ["provenance", "source_reports", "timeline_activity_state"], %{
        "paths" => ["source_timeline_activity_status_state"],
        "contract" => "timeline_activity_status_state.v1",
        "count" => 2,
        "row_count" => 2,
        "invalid_activity_input_count" => 2,
        "invalid_activity_input_reason_counts" => %{"missing_activity_type" => 2},
        "invalid_activity_input_reasons" => ["missing_activity_type"]
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_timeline_activity_state_summary)

    artifact_with_timeline_activity_lifecycle_state_summary =
      put_in(
        artifact,
        ["provenance", "source_reports", "timeline_activity_lifecycle_state"],
        %{
          "paths" => ["source_timeline_activity_lifecycle_state"],
          "contract" => "timeline_activity_lifecycle_state.v1",
          "count" => 1,
          "row_count" => 1,
          "review_required_count" => 1,
          "invalid_activity_input_count" => 1,
          "invalid_activity_input_reason_counts" => %{"missing_activity_type" => 1},
          "invalid_activity_input_reasons" => ["missing_activity_type"],
          "transition_decision_counts" => %{"review" => 1},
          "status_transition_decision_counts" => %{"record" => 1},
          "approval_transition_decision_counts" => %{"review" => 1},
          "required_operator_action_counts" => %{"review_activity_approval" => 1},
          "import_action_counts" => %{"review_timeline_diff" => 1},
          "planned_status_category_counts" => %{"planned" => 1},
          "realized_status_category_counts" => %{"executed" => 1},
          "planned_approval_category_counts" => %{"review_required" => 1},
          "realized_approval_category_counts" => %{"protected" => 1},
          "status_transition_category_counts" => %{"execution_recorded" => 1},
          "approval_transition_category_counts" => %{"approval_granted" => 1},
          "transition_application_provenance_count" => 1,
          "transition_application_provenance_helper_counts" => %{
            "apply_lifecycle_event" => 1
          },
          "transition_application_provenance_category_counts" => %{
            "execution_recorded" => 1
          },
          "transition_application_provenance_operator_action_reason_counts" => %{
            "activity_execution_recorded" => 1
          },
          "protection_decision_counts" => %{"preserve" => 1},
          "protection_category_counts" => %{"executed" => 1},
          "activity_id_counts" => %{"cmd_main" => 1},
          "timeline_id_counts" => %{"timeline:cmd_main" => 1},
          "review_activity_id_counts" => %{"cmd_main" => 1},
          "action_routing" => %{
            "review_activity_approval" => %{
              "review_count" => 1,
              "activity_ids" => ["cmd_main"],
              "timeline_ids" => ["timeline:cmd_main"],
              "status_transition_categories" => ["execution_recorded"],
              "approval_transition_categories" => ["approval_granted"],
              "protection_categories" => ["executed"]
            }
          }
        }
      )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_timeline_activity_lifecycle_state_summary)

    assert {:ok, candidate_refresh_schema} = Schema.json_schema("candidate_refresh.v1")

    timeline_activity_lifecycle_source_report_properties =
      get_in(candidate_refresh_schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "timeline_activity_lifecycle_state",
        "properties"
      ])

    assert get_in(timeline_activity_lifecycle_source_report_properties, [
             "review_required_count",
             "minimum"
           ]) == 0

    assert get_in(timeline_activity_lifecycle_source_report_properties, [
             "transition_decision_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(timeline_activity_lifecycle_source_report_properties, [
             "action_routing",
             "additionalProperties",
             "properties",
             "activity_ids",
             "items",
             "pattern"
           ])

    assert get_in(timeline_activity_lifecycle_source_report_properties, [
             "action_routing",
             "additionalProperties",
             "properties",
             "protection_categories",
             "items",
             "type"
           ]) == "string"

    invalid_timeline_activity_input_count =
      put_in(
        artifact_with_timeline_activity_state_summary,
        [
          "provenance",
          "source_reports",
          "timeline_activity_state",
          "invalid_activity_input_count"
        ],
        -1
      )

    assert {:error, invalid_timeline_activity_input_count_report} =
             Schema.validate_artifact(invalid_timeline_activity_input_count)

    assert Enum.any?(
             invalid_timeline_activity_input_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_activity_state.invalid_activity_input_count")
           )

    invalid_timeline_activity_input_reason_count =
      put_in(
        artifact_with_timeline_activity_state_summary,
        [
          "provenance",
          "source_reports",
          "timeline_activity_state",
          "invalid_activity_input_reason_counts",
          "missing_activity_type"
        ],
        -1
      )

    assert {:error, invalid_timeline_activity_input_reason_count_report} =
             Schema.validate_artifact(invalid_timeline_activity_input_reason_count)

    assert Enum.any?(
             invalid_timeline_activity_input_reason_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_activity_state.invalid_activity_input_reason_counts.missing_activity_type")
           )

    invalid_timeline_activity_input_reason =
      put_in(
        artifact_with_timeline_activity_lifecycle_state_summary,
        [
          "provenance",
          "source_reports",
          "timeline_activity_lifecycle_state",
          "invalid_activity_input_reasons",
          Access.at(0)
        ],
        42
      )

    assert {:error, invalid_timeline_activity_input_reason_report} =
             Schema.validate_artifact(invalid_timeline_activity_input_reason)

    assert Enum.any?(
             invalid_timeline_activity_input_reason_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_activity_lifecycle_state.invalid_activity_input_reasons[0]")
           )

    invalid_timeline_activity_lifecycle_review_count =
      put_in(
        artifact_with_timeline_activity_lifecycle_state_summary,
        [
          "provenance",
          "source_reports",
          "timeline_activity_lifecycle_state",
          "review_required_count"
        ],
        -1
      )

    assert {:error, invalid_timeline_activity_lifecycle_review_count_report} =
             Schema.validate_artifact(invalid_timeline_activity_lifecycle_review_count)

    assert Enum.any?(
             invalid_timeline_activity_lifecycle_review_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_activity_lifecycle_state.review_required_count")
           )

    invalid_timeline_activity_lifecycle_transition_count =
      put_in(
        artifact_with_timeline_activity_lifecycle_state_summary,
        [
          "provenance",
          "source_reports",
          "timeline_activity_lifecycle_state",
          "transition_decision_counts",
          "review"
        ],
        -1
      )

    assert {:error, invalid_timeline_activity_lifecycle_transition_count_report} =
             Schema.validate_artifact(invalid_timeline_activity_lifecycle_transition_count)

    assert Enum.any?(
             invalid_timeline_activity_lifecycle_transition_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_activity_lifecycle_state.transition_decision_counts.review")
           )

    invalid_timeline_activity_lifecycle_route_id =
      put_in(
        artifact_with_timeline_activity_lifecycle_state_summary,
        [
          "provenance",
          "source_reports",
          "timeline_activity_lifecycle_state",
          "action_routing",
          "review_activity_approval",
          "activity_ids",
          Access.at(0)
        ],
        "bad id"
      )

    assert {:error, invalid_timeline_activity_lifecycle_route_id_report} =
             Schema.validate_artifact(invalid_timeline_activity_lifecycle_route_id)

    assert Enum.any?(
             invalid_timeline_activity_lifecycle_route_id_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_activity_lifecycle_state.action_routing.review_activity_approval.activity_ids[0]")
           )

    artifact_with_timeline_activity_precondition_summary =
      put_in(
        artifact,
        ["provenance", "source_reports", "timeline_activity_precondition_summary"],
        %{
          "paths" => ["source_timeline_activity_precondition_summary"],
          "contract" => "timeline_activity_precondition_summary.v1",
          "count" => 2,
          "row_count" => 3,
          "blocked_precondition_count" => 2,
          "review_precondition_count" => 1,
          "invalid_activity_input_count" => 1,
          "source_summary_model_counts" => %{
            "artifact_only_timeline_activity_precondition_summary" => 2
          },
          "source_summary_schema_contract_counts" => %{
            "timeline_activity_precondition_summary.v1" => 2
          },
          "precondition_status_counts" => %{"blocked" => 2, "review_required" => 1},
          "blocked_precondition_type_counts" => %{"payload_unavailable" => 1},
          "review_precondition_type_counts" => %{"degraded_mode" => 1},
          "invalid_activity_input_reason_counts" => %{"missing_activity_type" => 1},
          "invalid_activity_input_reasons" => ["missing_activity_type"],
          "activity_id_counts" => %{"cmd_preflight" => 2},
          "timeline_id_counts" => %{"timeline:cmd_preflight" => 2},
          "dependency_activity_id_counts" => %{"health_check_1" => 2},
          "dependency_timeline_id_counts" => %{"timeline:health_check_1" => 2},
          "exclusive_with_activity_id_counts" => %{"dl_conflict" => 1},
          "exclusive_with_timeline_id_counts" => %{"timeline:dl_conflict" => 1},
          "allow_overlap_counts" => %{"true" => 1},
          "trust_boundary_status" => "declared",
          "trust_boundaries" => ["ops_activity_precondition"]
        }
      )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_timeline_activity_precondition_summary)

    assert {:ok, candidate_refresh_schema} = Schema.json_schema("candidate_refresh.v1")

    timeline_activity_precondition_source_report_properties =
      get_in(candidate_refresh_schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "timeline_activity_precondition_summary",
        "properties"
      ])

    assert get_in(timeline_activity_precondition_source_report_properties, [
             "blocked_precondition_count",
             "minimum"
           ]) == 0

    assert get_in(timeline_activity_precondition_source_report_properties, [
             "precondition_status_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(timeline_activity_precondition_source_report_properties, [
             "invalid_activity_input_reasons",
             "items",
             "type"
           ]) == "string"

    invalid_timeline_activity_precondition_blocked_count =
      put_in(
        artifact_with_timeline_activity_precondition_summary,
        [
          "provenance",
          "source_reports",
          "timeline_activity_precondition_summary",
          "blocked_precondition_count"
        ],
        -1
      )

    assert {:error, invalid_timeline_activity_precondition_blocked_count_report} =
             Schema.validate_artifact(invalid_timeline_activity_precondition_blocked_count)

    assert Enum.any?(
             invalid_timeline_activity_precondition_blocked_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_activity_precondition_summary.blocked_precondition_count")
           )

    invalid_timeline_activity_precondition_status_count =
      put_in(
        artifact_with_timeline_activity_precondition_summary,
        [
          "provenance",
          "source_reports",
          "timeline_activity_precondition_summary",
          "precondition_status_counts",
          "blocked"
        ],
        -1
      )

    assert {:error, invalid_timeline_activity_precondition_status_count_report} =
             Schema.validate_artifact(invalid_timeline_activity_precondition_status_count)

    assert Enum.any?(
             invalid_timeline_activity_precondition_status_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_activity_precondition_summary.precondition_status_counts.blocked")
           )

    invalid_timeline_activity_precondition_reason =
      put_in(
        artifact_with_timeline_activity_precondition_summary,
        [
          "provenance",
          "source_reports",
          "timeline_activity_precondition_summary",
          "invalid_activity_input_reasons",
          Access.at(0)
        ],
        42
      )

    assert {:error, invalid_timeline_activity_precondition_reason_report} =
             Schema.validate_artifact(invalid_timeline_activity_precondition_reason)

    assert Enum.any?(
             invalid_timeline_activity_precondition_reason_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_activity_precondition_summary.invalid_activity_input_reasons[0]")
           )

    artifact_with_timeline_lifecycle_state_summary =
      put_in(artifact, ["provenance", "source_reports", "timeline_lifecycle_state_summary"], %{
        "paths" => ["source_timeline_lifecycle_state_summary"],
        "contract" => "timeline_lifecycle_state_summary.v1",
        "count" => 1,
        "row_count" => 2,
        "planned_activity_count" => 2,
        "realized_activity_count" => 1,
        "recordable_count" => 1,
        "preserved_count" => 1,
        "review_required_count" => 1,
        "duplicate_timeline_identity_count" => 1,
        "invalid_activity_input_count" => 1,
        "invalid_activity_input_ids" => ["timeline_row:5:bad_missing_type"],
        "transition_decision_counts" => %{"record" => 1, "review" => 1},
        "required_operator_action_counts" => %{"review_activity_approval" => 1},
        "import_action_counts" => %{"review_timeline_diff" => 1},
        "planned_status_category_counts" => %{"planned" => 1},
        "realized_status_category_counts" => %{"executed" => 1},
        "planned_approval_category_counts" => %{"review_required" => 1},
        "realized_approval_category_counts" => %{"protected" => 1},
        "status_transition_category_counts" => %{"execution_recorded" => 1},
        "approval_transition_category_counts" => %{"approval_granted" => 1},
        "transition_application_provenance_count" => 1,
        "transition_application_provenance_helper_counts" => %{
          "apply_lifecycle_event" => 1
        },
        "transition_application_provenance_category_counts" => %{
          "execution_recorded" => 1
        },
        "transition_application_provenance_operator_action_reason_counts" => %{
          "activity_execution_recorded" => 1
        },
        "recordable_timeline_ids" => ["timeline:cmd_recordable"],
        "preserved_timeline_ids" => ["timeline:obs_done"],
        "review_timeline_ids" => ["timeline:cmd_pending"],
        "review_activity_ids" => ["cmd_pending"],
        "review_timeline_ids_by_required_operator_action" => %{
          "review_activity_approval" => ["timeline:cmd_pending"]
        },
        "review_timeline_ids_by_status_transition_category" => %{
          "execution_recorded" => ["timeline:cmd_recordable"]
        },
        "review_timeline_ids_by_approval_transition_category" => %{
          "approval_granted" => ["timeline:cmd_pending"]
        },
        "review_routing" => %{
          "review_activity_approval" => %{
            "review_count" => 1,
            "activity_ids" => ["cmd_pending"],
            "timeline_ids" => ["timeline:cmd_pending"],
            "status_transition_categories" => ["execution_recorded"],
            "approval_transition_categories" => ["approval_granted"]
          }
        }
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_timeline_lifecycle_state_summary)

    assert {:ok, candidate_refresh_schema} = Schema.json_schema("candidate_refresh.v1")

    timeline_lifecycle_state_source_report_properties =
      get_in(candidate_refresh_schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "timeline_lifecycle_state_summary",
        "properties"
      ])

    assert get_in(timeline_lifecycle_state_source_report_properties, [
             "review_required_count",
             "minimum"
           ]) == 0

    assert get_in(timeline_lifecycle_state_source_report_properties, [
             "transition_decision_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(timeline_lifecycle_state_source_report_properties, [
             "review_timeline_ids",
             "items",
             "pattern"
           ])

    assert get_in(timeline_lifecycle_state_source_report_properties, [
             "review_timeline_ids_by_required_operator_action",
             "additionalProperties",
             "items",
             "pattern"
           ])

    assert get_in(timeline_lifecycle_state_source_report_properties, [
             "review_routing",
             "additionalProperties",
             "properties",
             "activity_ids",
             "items",
             "pattern"
           ])

    invalid_timeline_lifecycle_state_review_count =
      put_in(
        artifact_with_timeline_lifecycle_state_summary,
        [
          "provenance",
          "source_reports",
          "timeline_lifecycle_state_summary",
          "review_required_count"
        ],
        -1
      )

    assert {:error, invalid_timeline_lifecycle_state_review_count_report} =
             Schema.validate_artifact(invalid_timeline_lifecycle_state_review_count)

    assert Enum.any?(
             invalid_timeline_lifecycle_state_review_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_lifecycle_state_summary.review_required_count")
           )

    invalid_timeline_lifecycle_state_transition_count =
      put_in(
        artifact_with_timeline_lifecycle_state_summary,
        [
          "provenance",
          "source_reports",
          "timeline_lifecycle_state_summary",
          "transition_decision_counts",
          "review"
        ],
        -1
      )

    assert {:error, invalid_timeline_lifecycle_state_transition_count_report} =
             Schema.validate_artifact(invalid_timeline_lifecycle_state_transition_count)

    assert Enum.any?(
             invalid_timeline_lifecycle_state_transition_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_lifecycle_state_summary.transition_decision_counts.review")
           )

    invalid_timeline_lifecycle_state_review_id =
      put_in(
        artifact_with_timeline_lifecycle_state_summary,
        [
          "provenance",
          "source_reports",
          "timeline_lifecycle_state_summary",
          "review_timeline_ids",
          Access.at(0)
        ],
        "bad id"
      )

    assert {:error, invalid_timeline_lifecycle_state_review_id_report} =
             Schema.validate_artifact(invalid_timeline_lifecycle_state_review_id)

    assert Enum.any?(
             invalid_timeline_lifecycle_state_review_id_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_lifecycle_state_summary.review_timeline_ids[0]")
           )

    invalid_timeline_lifecycle_state_review_id_map =
      put_in(
        artifact_with_timeline_lifecycle_state_summary,
        [
          "provenance",
          "source_reports",
          "timeline_lifecycle_state_summary",
          "review_timeline_ids_by_required_operator_action",
          "review_activity_approval",
          Access.at(0)
        ],
        "bad id"
      )

    assert {:error, invalid_timeline_lifecycle_state_review_id_map_report} =
             Schema.validate_artifact(invalid_timeline_lifecycle_state_review_id_map)

    assert Enum.any?(
             invalid_timeline_lifecycle_state_review_id_map_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_lifecycle_state_summary.review_timeline_ids_by_required_operator_action.review_activity_approval[0]")
           )

    invalid_timeline_lifecycle_state_route_id =
      put_in(
        artifact_with_timeline_lifecycle_state_summary,
        [
          "provenance",
          "source_reports",
          "timeline_lifecycle_state_summary",
          "review_routing",
          "review_activity_approval",
          "activity_ids",
          Access.at(0)
        ],
        "bad id"
      )

    assert {:error, invalid_timeline_lifecycle_state_route_id_report} =
             Schema.validate_artifact(invalid_timeline_lifecycle_state_route_id)

    assert Enum.any?(
             invalid_timeline_lifecycle_state_route_id_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_lifecycle_state_summary.review_routing.review_activity_approval.activity_ids[0]")
           )

    artifact_with_timeline_integrity_summary =
      put_in(artifact, ["provenance", "source_reports", "timeline_integrity_report"], %{
        "paths" => ["source_timeline_integrity_report"],
        "contract" => "timeline_integrity_report.v1",
        "count" => 1,
        "row_count" => 2,
        "timeline_integrity_issue_count" => 2,
        "timeline_integrity_review_count" => 1,
        "dependency_issue_count" => 1,
        "exclusivity_issue_count" => 1,
        "timeline_integrity_status_counts" => %{"review_required" => 2},
        "timeline_integrity_issue_type_counts" => %{"missing_dependency_activity" => 1},
        "required_operator_action_counts" => %{"review_timeline_integrity" => 1},
        "operator_action_reason_counts" => %{"timeline_integrity_issue" => 1},
        "review_activity_id_counts" => %{"cmd_main" => 1},
        "review_timeline_id_counts" => %{"timeline:cmd_main" => 1},
        "missing_dependency_activity_id_counts" => %{"missing_gate" => 1},
        "missing_dependency_timeline_id_counts" => %{"timeline:missing_gate" => 1},
        "self_dependency_activity_id_counts" => %{"cmd_self" => 1},
        "self_dependency_timeline_id_counts" => %{"timeline:cmd_self" => 1},
        "dependency_cycle_activity_id_counts" => %{"cmd_cycle" => 1},
        "dependency_cycle_timeline_id_counts" => %{"timeline:cmd_cycle" => 1},
        "dependency_order_violation_activity_id_counts" => %{"cmd_order" => 1},
        "dependency_order_violation_timeline_id_counts" => %{"timeline:cmd_order" => 1},
        "exclusivity_violation_activity_id_counts" => %{"cmd_main" => 1},
        "exclusivity_violation_timeline_id_counts" => %{"timeline:cmd_main" => 1},
        "exclusivity_violation_group_counts" => %{"conflict_group" => 1}
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_timeline_integrity_summary)

    assert {:ok, candidate_refresh_schema} = Schema.json_schema("candidate_refresh.v1")

    timeline_integrity_source_report_properties =
      get_in(candidate_refresh_schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "timeline_integrity_report",
        "properties"
      ])

    assert get_in(timeline_integrity_source_report_properties, [
             "timeline_integrity_issue_count",
             "minimum"
           ]) == 0

    assert get_in(timeline_integrity_source_report_properties, [
             "timeline_integrity_issue_type_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(timeline_integrity_source_report_properties, [
             "review_activity_id_counts",
             "additionalProperties",
             "type"
           ]) == "integer"

    invalid_timeline_integrity_issue_count =
      put_in(
        artifact_with_timeline_integrity_summary,
        [
          "provenance",
          "source_reports",
          "timeline_integrity_report",
          "timeline_integrity_issue_count"
        ],
        -1
      )

    assert {:error, invalid_timeline_integrity_issue_count_report} =
             Schema.validate_artifact(invalid_timeline_integrity_issue_count)

    assert Enum.any?(
             invalid_timeline_integrity_issue_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_integrity_report.timeline_integrity_issue_count")
           )

    invalid_timeline_integrity_issue_type_count =
      put_in(
        artifact_with_timeline_integrity_summary,
        [
          "provenance",
          "source_reports",
          "timeline_integrity_report",
          "timeline_integrity_issue_type_counts",
          "missing_dependency_activity"
        ],
        -1
      )

    assert {:error, invalid_timeline_integrity_issue_type_count_report} =
             Schema.validate_artifact(invalid_timeline_integrity_issue_type_count)

    assert Enum.any?(
             invalid_timeline_integrity_issue_type_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_integrity_report.timeline_integrity_issue_type_counts.missing_dependency_activity")
           )

    invalid_timeline_integrity_issue_type_shape =
      put_in(
        artifact_with_timeline_integrity_summary,
        [
          "provenance",
          "source_reports",
          "timeline_integrity_report",
          "timeline_integrity_issue_type_counts"
        ],
        "missing_dependency_activity"
      )

    assert {:error, invalid_timeline_integrity_issue_type_shape_report} =
             Schema.validate_artifact(invalid_timeline_integrity_issue_type_shape)

    assert Enum.any?(
             invalid_timeline_integrity_issue_type_shape_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_integrity_report.timeline_integrity_issue_type_counts")
           )

    artifact_with_timeline_dependency_impact_summary =
      put_in(
        artifact,
        ["provenance", "source_reports", "timeline_dependency_impact_summary"],
        %{
          "paths" => ["source_timeline_dependency_impact_summary"],
          "contract" => "timeline_dependency_impact_summary.v1",
          "count" => 1,
          "row_count" => 2,
          "source_activity_count" => 2,
          "replacement_activity_count" => 2,
          "changed_source_activity_count" => 1,
          "changed_source_timeline_count" => 1,
          "dependent_activity_count" => 2,
          "source_dependent_activity_count" => 1,
          "replacement_dependent_activity_count" => 1,
          "dependency_impact_status_counts" => %{"review_required" => 2},
          "dependency_impact_scope_counts" => %{"source" => 1},
          "required_operator_action_counts" => %{"review_timeline_integrity" => 2},
          "impacted_source_activity_id_counts" => %{"health_gate" => 1},
          "impacted_source_timeline_id_counts" => %{"timeline:health_gate" => 1},
          "impacted_dependency_activity_id_counts" => %{"dependency_gate" => 1},
          "impacted_dependency_timeline_id_counts" => %{"timeline:dependency_gate" => 1},
          "impacted_exclusive_activity_id_counts" => %{"exclusive_gate" => 1},
          "impacted_exclusive_timeline_id_counts" => %{"timeline:exclusive_gate" => 1},
          "dependent_activity_id_counts" => %{"cmd_combo" => 2},
          "dependent_timeline_id_counts" => %{"timeline:cmd_combo" => 2}
        }
      )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_timeline_dependency_impact_summary)

    assert {:ok, candidate_refresh_schema} = Schema.json_schema("candidate_refresh.v1")

    timeline_dependency_impact_source_report_properties =
      get_in(candidate_refresh_schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "timeline_dependency_impact_summary",
        "properties"
      ])

    assert get_in(timeline_dependency_impact_source_report_properties, [
             "changed_source_activity_count",
             "minimum"
           ]) == 0

    assert get_in(timeline_dependency_impact_source_report_properties, [
             "dependency_impact_status_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(timeline_dependency_impact_source_report_properties, [
             "dependent_activity_id_counts",
             "additionalProperties",
             "type"
           ]) == "integer"

    invalid_timeline_dependency_impact_changed_count =
      put_in(
        artifact_with_timeline_dependency_impact_summary,
        [
          "provenance",
          "source_reports",
          "timeline_dependency_impact_summary",
          "changed_source_activity_count"
        ],
        -1
      )

    assert {:error, invalid_timeline_dependency_impact_changed_count_report} =
             Schema.validate_artifact(invalid_timeline_dependency_impact_changed_count)

    assert Enum.any?(
             invalid_timeline_dependency_impact_changed_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_dependency_impact_summary.changed_source_activity_count")
           )

    invalid_timeline_dependency_impact_status_count =
      put_in(
        artifact_with_timeline_dependency_impact_summary,
        [
          "provenance",
          "source_reports",
          "timeline_dependency_impact_summary",
          "dependency_impact_status_counts",
          "review_required"
        ],
        -1
      )

    assert {:error, invalid_timeline_dependency_impact_status_count_report} =
             Schema.validate_artifact(invalid_timeline_dependency_impact_status_count)

    assert Enum.any?(
             invalid_timeline_dependency_impact_status_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_dependency_impact_summary.dependency_impact_status_counts.review_required")
           )

    invalid_timeline_dependency_impact_status_shape =
      put_in(
        artifact_with_timeline_dependency_impact_summary,
        [
          "provenance",
          "source_reports",
          "timeline_dependency_impact_summary",
          "dependency_impact_status_counts"
        ],
        "review_required"
      )

    assert {:error, invalid_timeline_dependency_impact_status_shape_report} =
             Schema.validate_artifact(invalid_timeline_dependency_impact_status_shape)

    assert Enum.any?(
             invalid_timeline_dependency_impact_status_shape_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_dependency_impact_summary.dependency_impact_status_counts")
           )

    artifact_with_timeline_publication_summary =
      put_in(artifact, ["provenance", "source_reports", "timeline_publication_summary"], %{
        "paths" => ["source_timeline_publication_summary"],
        "contract" => "timeline_publication_summary.v1",
        "count" => 1,
        "row_count" => 1,
        "publication_status_counts" => %{"review_required" => 1},
        "downstream_invalidation_status_counts" => %{"clear" => 1},
        "dependency_impact_status_counts" => %{"review_required" => 1},
        "publication_authority_counts" => %{"mission_operations" => 1},
        "source_artifact_type_counts" => %{"operational_timeline_report.v1" => 1},
        "timeline_publication_source_artifact_type_counts" => %{
          "operational_timeline_report.v1" => 1
        },
        "publication_ids" => ["timeline_publication:branch"],
        "source_artifact_ids" => ["timeline:branch_plan"],
        "supersedes_artifact_ids" => ["timeline:previous_plan"],
        "downstream_product_ids" => ["cadence_import:branch_plan"],
        "invalidated_downstream_product_ids" => ["cadence_import:branch_plan"],
        "dependency_impact_row_count" => 1,
        "impacted_dependency_activity_ids" => ["branch_dependency"],
        "impacted_dependency_timeline_ids" => ["timeline:branch_dependency"],
        "impacted_exclusive_with_activity_ids" => ["branch_exclusive"],
        "impacted_exclusive_with_timeline_ids" => ["timeline:branch_exclusive"],
        "timeline_diff_row_count" => 2,
        "timeline_diff_changed_count" => 1,
        "timeline_diff_review_required_count" => 1,
        "changed_field_counts" => %{"starts_at_s" => 1},
        "changed_timeline_ids" => ["timeline:branch_changed"],
        "review_timeline_ids" => ["timeline:branch_review"],
        "timeline_ids_by_changed_field" => %{
          "starts_at_s" => ["timeline:branch_changed"]
        }
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_timeline_publication_summary)

    assert {:ok, candidate_refresh_schema} = Schema.json_schema("candidate_refresh.v1")

    timeline_publication_source_report_properties =
      get_in(candidate_refresh_schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "timeline_publication_summary",
        "properties"
      ])

    assert get_in(timeline_publication_source_report_properties, [
             "publication_ids",
             "items",
             "pattern"
           ])

    assert get_in(timeline_publication_source_report_properties, [
             "downstream_invalidation_status_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(timeline_publication_source_report_properties, [
             "dependency_impact_row_count",
             "minimum"
           ]) == 0

    assert get_in(timeline_publication_source_report_properties, [
             "changed_field_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(timeline_publication_source_report_properties, [
             "timeline_ids_by_changed_field",
             "additionalProperties",
             "items",
             "pattern"
           ])

    invalid_timeline_publication_dependency_count =
      put_in(
        artifact_with_timeline_publication_summary,
        [
          "provenance",
          "source_reports",
          "timeline_publication_summary",
          "dependency_impact_row_count"
        ],
        -1
      )

    assert {:error, invalid_timeline_publication_dependency_count_report} =
             Schema.validate_artifact(invalid_timeline_publication_dependency_count)

    assert Enum.any?(
             invalid_timeline_publication_dependency_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_publication_summary.dependency_impact_row_count")
           )

    invalid_timeline_publication_changed_field_count =
      put_in(
        artifact_with_timeline_publication_summary,
        [
          "provenance",
          "source_reports",
          "timeline_publication_summary",
          "changed_field_counts",
          "starts_at_s"
        ],
        -1
      )

    assert {:error, invalid_timeline_publication_changed_field_count_report} =
             Schema.validate_artifact(invalid_timeline_publication_changed_field_count)

    assert Enum.any?(
             invalid_timeline_publication_changed_field_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_publication_summary.changed_field_counts.starts_at_s")
           )

    invalid_timeline_publication_source_artifact_type_count =
      put_in(
        artifact_with_timeline_publication_summary,
        [
          "provenance",
          "source_reports",
          "timeline_publication_summary",
          "timeline_publication_source_artifact_type_counts",
          "operational_timeline_report.v1"
        ],
        -1
      )

    assert {:error, invalid_timeline_publication_source_artifact_type_count_report} =
             Schema.validate_artifact(invalid_timeline_publication_source_artifact_type_count)

    assert Enum.any?(
             invalid_timeline_publication_source_artifact_type_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_publication_summary.timeline_publication_source_artifact_type_counts.operational_timeline_report.v1")
           )

    invalid_timeline_publication_id =
      put_in(
        artifact_with_timeline_publication_summary,
        [
          "provenance",
          "source_reports",
          "timeline_publication_summary",
          "publication_ids",
          Access.at(0)
        ],
        "bad id"
      )

    assert {:error, invalid_timeline_publication_id_report} =
             Schema.validate_artifact(invalid_timeline_publication_id)

    assert Enum.any?(
             invalid_timeline_publication_id_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.timeline_publication_summary.publication_ids[0]")
           )

    artifact_with_station_calendar_summary =
      put_in(artifact, ["provenance", "source_reports", "station_calendar_report"], %{
        "paths" => ["source_station_calendar_report"],
        "contract" => "station_calendar_report.v1",
        "count" => 1,
        "row_count" => 1,
        "affected_contact_count" => 1,
        "affected_contact_ground_station_counts" => %{"equator_prime" => 1},
        "affected_contact_availability_counts" => %{"unavailable" => 1},
        "provider_calendar_contention_provider_counts" => %{"ops_calendar" => 1},
        "provider_calendar_contention_ground_station_counts" => %{"equator_prime" => 1}
      })

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact_with_station_calendar_summary)

    invalid_station_calendar_availability_count =
      put_in(
        artifact_with_station_calendar_summary,
        [
          "provenance",
          "source_reports",
          "station_calendar_report",
          "affected_contact_availability_counts",
          "unavailable"
        ],
        -1
      )

    assert {:error, invalid_station_calendar_availability_count_report} =
             Schema.validate_artifact(invalid_station_calendar_availability_count)

    assert Enum.any?(
             invalid_station_calendar_availability_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.station_calendar_report.affected_contact_availability_counts.unavailable")
           )

    invalid_station_calendar_provider_count =
      put_in(
        artifact_with_station_calendar_summary,
        [
          "provenance",
          "source_reports",
          "station_calendar_report",
          "provider_calendar_contention_provider_counts",
          "ops_calendar"
        ],
        -1
      )

    assert {:error, invalid_station_calendar_provider_count_report} =
             Schema.validate_artifact(invalid_station_calendar_provider_count)

    assert Enum.any?(
             invalid_station_calendar_provider_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.station_calendar_report.provider_calendar_contention_provider_counts.ops_calendar")
           )

    invalid_source_path =
      put_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "quality_gate_report",
          "paths",
          Access.at(0)
        ],
        42
      )

    assert {:error, invalid_source_path_report} = Schema.validate_artifact(invalid_source_path)

    assert Enum.any?(
             invalid_source_path_report["errors"],
             &(&1["path"] == "$.provenance.source_reports.quality_gate_report.paths[0]")
           )

    invalid_row_count =
      put_in(
        artifact,
        ["provenance", "source_reports", "quality_gate_report", "row_count"],
        -1
      )

    assert {:error, invalid_row_count_report} = Schema.validate_artifact(invalid_row_count)

    assert Enum.any?(
             invalid_row_count_report["errors"],
             &(&1["path"] == "$.provenance.source_reports.quality_gate_report.row_count")
           )

    valid_reservation_evidence_count =
      put_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "quality_gate_report",
          "station_reservation_evidence_row_count"
        ],
        1
      )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(valid_reservation_evidence_count)

    invalid_reservation_evidence_count =
      put_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "quality_gate_report",
          "station_reservation_expiration_evidence_row_count"
        ],
        -1
      )

    assert {:error, invalid_reservation_evidence_count_report} =
             Schema.validate_artifact(invalid_reservation_evidence_count)

    assert Enum.any?(
             invalid_reservation_evidence_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.quality_gate_report.station_reservation_expiration_evidence_row_count")
           )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
