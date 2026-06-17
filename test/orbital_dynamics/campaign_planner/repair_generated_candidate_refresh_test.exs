Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairGeneratedCandidateRefreshTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{CandidateRefresh, Schema}

  test "repair-generated candidate refresh inherits mission-state fallback inputs" do
    refresh_request =
      branch_candidate_refresh_request()
      |> update_in(["candidate_refresh"], fn refresh ->
        refresh
        |> Map.delete("targets")
        |> Map.delete("resource_summaries")
      end)

    mission_state =
      mission_state_with_refresh_inputs()
      |> put_in([:targets], [
        %{
          id: "target_a",
          latitude_deg: 0.0,
          longitude_deg: 0.0,
          minimum_elevation_deg: 10.0,
          priority: 6.0
        }
      ])
      |> put_in([:resource_summaries], [
        %{
          spacecraft_id: "sat_1",
          fuel_margin: 0.8,
          storage_capacity_mb: 1000.0,
          storage_used_mb: 100.0
        }
      ])

    artifact =
      repair(
        %{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
        },
        mission_state: mission_state,
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 0.0,
        generated_at: ~U[2026-05-14 00:00:00Z],
        candidate_refresh_request: refresh_request
      )

    assert %{
             "type" => "candidate_refresh.v1",
             "scope" => "repair_generated"
           } = artifact["assumptions"]["candidate_source"]

    assert %{
             "target_priority" => 6.0,
             "target_priority_source" => "source_window.target_priority"
           } =
             Enum.find(
               artifact["source_candidate_activities"],
               &(&1["type"] == "observe" and &1["target_id"] == "target_a")
             )

    assert [
             %{
               "schema_contract" => "resource_summary.v1",
               "spacecraft_id" => "sat_1",
               "storage_margin" => 0.9
             }
           ] = artifact["source_resource_summaries"]

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair-generated candidate refresh preserves mission-state objective priorities" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:objectives, [
        %{
          id: "urgent:target_a",
          type: "urgent_target",
          target_id: "target_a",
          spacecraft_id: "sat_1",
          priority: 9.0
        }
      ])

    artifact =
      repair(
        %{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
        },
        mission_state: mission_state,
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 0.0,
        generated_at: ~U[2026-05-14 00:00:00Z],
        candidate_refresh_request: branch_candidate_refresh_request()
      )

    assert %{
             "target_priority" => 9.0,
             "target_priority_source" => "candidate_refresh.objectives.observation_priority",
             "target_priority_objective_ids" => ["urgent:target_a"],
             "target_priority_objective_type" => "urgent_target"
           } =
             Enum.find(
               artifact["source_candidate_activities"],
               &(&1["type"] == "observe" and &1["target_id"] == "target_a")
             )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair-generated candidate refresh surfaces resource suppressions for review" do
    refresh_request =
      branch_candidate_refresh_request()
      |> put_in(["candidate_refresh", "resource_summaries"], [
        %{
          "spacecraft_id" => "sat_1",
          "downlink_margin" => 0.05,
          "payload_available" => true,
          "antenna_available" => true,
          "assumptions" => %{"model" => "operator_summary"}
        }
      ])
      |> put_in(["candidate_refresh", "resource_filter_policy"], %{
        "min_downlink_margin" => 0.2
      })

    artifact =
      repair(
        %{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 0.0,
        generated_at: ~U[2026-05-14 00:00:00Z],
        candidate_refresh_request: refresh_request
      )

    assert %{
             "schema_contract" => "resource_filter_report.v1",
             "input_candidate_count" => input_candidate_count,
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "type" => "downlink",
                 "scenario_id" => "leo_1",
                 "spacecraft_id" => "sat_1",
                 "ground_station_id" => "equator_prime",
                 "suppressed_reason" => "downlink_margin_below_policy",
                 "resource_blocking_dimension" => "downlink",
                 "downlink_margin" => 0.05
               }
             ]
           } = artifact["source_resource_filter_report"]

    assert input_candidate_count > 0

    refute Enum.any?(
             artifact["source_candidate_activities"],
             &(&1["id"] == "leo_1_downlink_equator_prime_1")
           )

    assert Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "resource_suppression" and
                 &1["source"] ==
                   "campaign_repair.source_resource_filter_report.suppressed_candidates" and
                 &1["activity_id"] == "leo_1_downlink_equator_prime_1" and
                 &1["required_operator_action"] == "review_suppressed_contact")
           )

    assert Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &(&1["import_action"] == "review_resource_suppression" and
                 &1["source_review_type"] == "resource_suppression" and
                 &1["activity_id"] == "leo_1_downlink_equator_prime_1")
           )

    assert "resource summary filters suppressed refreshed candidates" in artifact["warnings"]

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(artifact["source_resource_filter_report"])

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair can execute a candidate_refresh_request before selecting replacements" do
    source_reports = passive_candidate_refresh_source_reports()

    refresh_request =
      branch_candidate_refresh_request()
      |> put_in(
        ["candidate_refresh", "source_candidate_rejection_report"],
        source_reports["source_candidate_rejection_report"]
      )
      |> put_in(
        ["candidate_refresh", "source_provider_counteroffer_report"],
        source_reports["source_provider_counteroffer_report"]
      )
      |> put_in(
        ["candidate_refresh", "source_operational_readiness_report"],
        source_reports["source_operational_readiness_report"]
      )
      |> put_in(
        ["candidate_refresh", "source_schema_validation_report"],
        source_reports["source_schema_validation_report"]
      )
      |> put_in(
        ["candidate_refresh", "source_model_acceptance_report"],
        passive_model_acceptance_report()
      )
      |> put_in(
        ["candidate_refresh", "source_freshness_report"],
        %{
          "schema_contract" => "freshness_report.v1",
          "status" => "fresh",
          "stale_reasons" => [],
          "unknown_reasons" => []
        }
      )
      |> put_in(
        ["candidate_refresh", "accepted_planning_state", "source_model_acceptance_report"],
        passive_model_acceptance_report()
      )
      |> put_in(
        [
          "candidate_refresh",
          "accepted_planning_state",
          "source_candidate_rejection_report"
        ],
        source_reports["source_candidate_rejection_report"]
      )
      |> put_in(
        [
          "candidate_refresh",
          "accepted_planning_state",
          "source_provider_counteroffer_report"
        ],
        source_reports["source_provider_counteroffer_report"]
      )
      |> put_in(
        [
          "candidate_refresh",
          "accepted_planning_state",
          "source_operational_readiness_report"
        ],
        source_reports["source_operational_readiness_report"]
      )
      |> put_in(
        ["candidate_refresh", "accepted_planning_state", "source_schema_validation_report"],
        source_reports["source_schema_validation_report"]
      )
      |> put_in(
        ["candidate_refresh", "accepted_planning_state", "source_refresh_budget_report"],
        %{
          "schema_contract" => "refresh_budget_report.v1",
          "input_candidate_count" => 1,
          "kept_candidate_count" => 1,
          "dropped_candidate_count" => 0
        }
      )
      |> put_in(
        [
          "candidate_refresh",
          "accepted_planning_state",
          "source_station_reservation_hold_import_readiness_summary"
        ],
        source_reports["source_station_reservation_hold_import_readiness_summary"]
      )
      |> put_in(
        ["candidate_refresh", "mission_state"],
        Map.put(
          source_reports,
          "source_quality_gate_report",
          passive_quality_gate_report()
        )
        |> Map.put("source_model_acceptance_report", passive_model_acceptance_report())
      )

    artifact =
      repair(
        %{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 0.0,
        generated_at: ~U[2026-05-14 00:00:00Z],
        approval_policy: %{policy_bundle_id: "contact_command_review_v1"},
        candidate_refresh_request: refresh_request
      )

    assert [
             %{
               "activity_id" => "dl_1",
               "repair_action" => "moved",
               "replacement_activity_id" => "leo_1_downlink_equator_prime_1"
             }
           ] = artifact["deltas"]

    assert Enum.any?(
             artifact["source_candidate_activities"],
             &(&1["id"] == "leo_1_downlink_equator_prime_1")
           )

    assert %{
             "type" => "candidate_refresh.v1",
             "snapshot_id" => "ops-state-branch",
             "scope" => "repair_generated"
           } = artifact["assumptions"]["candidate_source"]

    assert artifact["assumptions"]["candidate_source"]["source_report_input_paths"]
           |> Enum.sort() == [
             "accepted_planning_state.source_candidate_rejection_report",
             "accepted_planning_state.source_model_acceptance_report",
             "accepted_planning_state.source_operational_readiness_report",
             "accepted_planning_state.source_provider_counteroffer_report",
             "accepted_planning_state.source_refresh_budget_report",
             "accepted_planning_state.source_schema_validation_report",
             "accepted_planning_state.source_station_reservation_hold_import_readiness_summary",
             "mission_state.source_candidate_diff_report",
             "mission_state.source_candidate_rejection_report",
             "mission_state.source_constraint_report",
             "mission_state.source_contact_allocation_report",
             "mission_state.source_contact_contention_report",
             "mission_state.source_contact_contention_resolution_report",
             "mission_state.source_contact_filter_report",
             "mission_state.source_freshness_report",
             "mission_state.source_link_capacity_report",
             "mission_state.source_model_acceptance_report",
             "mission_state.source_objective_satisfaction_report",
             "mission_state.source_objective_tradeoff_report",
             "mission_state.source_operational_readiness_report",
             "mission_state.source_provider_counteroffer_report",
             "mission_state.source_quality_gate_report",
             "mission_state.source_refresh_budget_report",
             "mission_state.source_resource_filter_report",
             "mission_state.source_resource_projection_report",
             "mission_state.source_schema_validation_report",
             "mission_state.source_score_term_report",
             "mission_state.source_station_calendar_report",
             "mission_state.source_station_reservation_hold_import_readiness_summary",
             "mission_state.source_station_reservation_report",
             "mission_state.source_timeline_diff_report",
             "source_candidate_rejection_report",
             "source_freshness_report",
             "source_model_acceptance_report",
             "source_operational_readiness_report",
             "source_provider_counteroffer_report",
             "source_schema_validation_report"
           ]

    assert %{
             "branch_local_reservation_hold_import_readiness_pressure" => true,
             "reservation_hold_count" => 4,
             "reservation_hold_import_readiness_status_counts" => %{"review_required" => 2},
             "reservation_hold_required_import_action_counts" => %{
               "review_station_provider_contention" => 2,
               "review_station_reservation_overlap" => 2
             },
             "source_report_paths" => station_reservation_source_paths,
             "assumptions" => %{
               "provider_reservation" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary"
             }
           } = CandidateRefresh.station_reservation_replay_summary(artifact)

    assert "accepted_planning_state.source_station_reservation_hold_import_readiness_summary" in station_reservation_source_paths

    assert artifact["provenance"]["candidate_source"]["scope"] == "repair_generated"
    assert artifact["repair_metadata"]["candidate_source"]["candidate_count"] > 0

    assert artifact["source_contact_filter_report"]["schema_contract"] ==
             "contact_filter_report.v1"

    assert artifact["source_contact_allocation_report"]["schema_contract"] ==
             "contact_allocation_report.v1"

    assert artifact["source_freshness_report"]["schema_contract"] == "freshness_report.v1"

    assert Enum.any?(artifact["source_contact_intents"], fn intent ->
             intent["activity_id"] == "leo_1_downlink_equator_prime_1" and
               intent["approval_status"] == "operator_review_required" and
               get_in(intent, ["policy_decision", "policy_bundle_id"]) ==
                 "contact_command_review_v1"
           end)

    assert %{
             "contact_intent_review_count" => 1,
             "review_type_counts" => %{"contact_intent_review" => 1}
           } = artifact["operator_review_package"]

    assert %{
             "review_type" => "contact_intent_review",
             "source" => "campaign_repair.source_contact_intents",
             "activity_id" => "leo_1_downlink_equator_prime_1",
             "required_operator_action" => "review_contact_intent",
             "approval_status" => "operator_review_required",
             "source_policy_decision" => %{
               "policy_bundle_id" => "contact_command_review_v1",
               "classification" => "operator_review_required"
             },
             "source_contact_intent" => %{
               "schema_contract" => "contact_intent.v1",
               "activity_id" => "leo_1_downlink_equator_prime_1"
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "contact_intent_review")
             )

    assert %{
             "import_action_counts" => %{"review_contact_intent" => 1}
           } = artifact["cadence_import_manifest"]

    contact_intent_import =
      Enum.find(
        artifact["cadence_import_manifest"]["rows"],
        &(&1["import_action"] == "review_contact_intent")
      )

    assert contact_intent_import["import_action"] == "review_contact_intent"
    assert contact_intent_import["source_review_type"] == "contact_intent_review"

    source_review_row = contact_intent_import["source_review_row"]

    assert %{
             "source" => "campaign_repair.source_contact_intents",
             "activity_id" => "leo_1_downlink_equator_prime_1",
             "source_contact_intent" => %{
               "schema_contract" => "contact_intent.v1",
               "activity_id" => "leo_1_downlink_equator_prime_1"
             },
             "source_policy_decision" => %{
               "policy_bundle_id" => "contact_command_review_v1"
             },
             "required_operator_action" => "review_contact_intent"
           } = source_review_row

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair records canonical candidate refresh source report input paths" do
    source_reports = passive_candidate_refresh_source_reports()

    canonical_mission_state_reports =
      source_reports
      |> Map.take([
        "source_candidate_rejection_report",
        "source_provider_counteroffer_report",
        "source_schema_validation_report",
        "source_operational_readiness_report",
        "source_station_calendar_report",
        "source_station_reservation_report",
        "source_contact_allocation_report",
        "source_timeline_diff_report",
        "source_objective_tradeoff_report"
      ])
      |> Map.new(fn {"source_" <> report_key, report} -> {report_key, report} end)

    refresh_request =
      branch_candidate_refresh_request()
      |> put_in(["candidate_refresh", "mission_state"], canonical_mission_state_reports)
      |> put_in(["candidate_refresh", "source_relay_data_path_summary"], %{
        "schema_contract" => "relay_data_path_summary.v1",
        "source" => "relay.fixture"
      })
      |> put_in(
        ["candidate_refresh", "mission_state", "operational_import_eligibility_summary"],
        %{
          "schema_contract" => "operational_import_eligibility_summary.v1",
          "source" => "readiness.fixture"
        }
      )
      |> put_in(
        [
          "candidate_refresh",
          "mission_state",
          "source_operational_quality_gate_schema_validation_summary"
        ],
        %{
          "schema_contract" => "operational_quality_gate_schema_validation_summary.v1",
          "source" => "quality_gate.fixture"
        }
      )
      |> put_in(
        ["candidate_refresh", "accepted_planning_state", "constraint_report"],
        source_reports["source_constraint_report"]
      )
      |> put_in(
        ["candidate_refresh", "score_term_report"],
        source_reports["source_score_term_report"]
      )

    artifact =
      repair(
        %{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 0.0,
        generated_at: ~U[2026-05-14 00:00:00Z],
        approval_policy: %{policy_bundle_id: "contact_command_review_v1"},
        candidate_refresh_request: refresh_request
      )

    source_report_input_paths =
      get_in(artifact, ["assumptions", "candidate_source", "source_report_input_paths"])

    for source_path <- [
          "score_term_report",
          "accepted_planning_state.constraint_report",
          "mission_state.candidate_rejection_report",
          "mission_state.provider_counteroffer_report",
          "mission_state.schema_validation_report",
          "mission_state.operational_readiness_report",
          "mission_state.station_calendar_report",
          "mission_state.station_reservation_report",
          "mission_state.contact_allocation_report",
          "mission_state.timeline_diff_report",
          "mission_state.objective_tradeoff_report",
          "source_relay_data_path_summary",
          "mission_state.operational_import_eligibility_summary",
          "mission_state.source_operational_quality_gate_schema_validation_summary"
        ] do
      assert source_path in source_report_input_paths
    end

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  defp passive_candidate_refresh_source_reports do
    %{
      "source_candidate_diff_report" => %{
        "schema_contract" => "candidate_diff_report.v1",
        "retained_candidates" => [],
        "new_candidates" => [],
        "invalidated_candidates" => []
      },
      "source_candidate_rejection_report" => %{
        "schema_contract" => "candidate_rejection_report.v1",
        "rows" => []
      },
      "source_schema_validation_report" => %{
        "schema_contract" => "schema_validation_report.v1",
        "validation_mode" => "artifact",
        "validated_contract" => "candidate_refresh.v1",
        "status" => "pass",
        "error_count" => 0,
        "warning_count" => 0,
        "remediation_count" => 0,
        "errors" => [],
        "warnings" => [],
        "remediation" => []
      },
      "source_freshness_report" => %{
        "schema_contract" => "freshness_report.v1",
        "status" => "fresh",
        "stale_reasons" => [],
        "unknown_reasons" => []
      },
      "source_refresh_budget_report" => %{
        "schema_contract" => "refresh_budget_report.v1",
        "input_candidate_count" => 1,
        "kept_candidate_count" => 1,
        "dropped_candidate_count" => 0
      },
      "source_operational_readiness_report" => %{
        "schema_contract" => "operational_readiness_report.v1",
        "schema_version" => 1,
        "model" => "OrbitalDynamics.OperationalReadiness.V1",
        "report_id" => "operational_readiness:planned_activity.v1:passive_source",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "passive_source",
        "readiness_level" => "operator_review",
        "import_classification" => "review_only",
        "status" => "review_required",
        "gate_count" => 4,
        "passed_gate_count" => 2,
        "review_gate_count" => 2,
        "analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "gates" => [],
        "evidence" => %{},
        "assumptions" => %{},
        "model_limits" => ["artifact_only"]
      },
      "source_provider_counteroffer_report" => %{
        "schema_contract" => "provider_counteroffer_report.v1",
        "source" => "station_calendar_report.affected_contacts",
        "source_artifact_type" => "station_calendar_report.v1",
        "source_artifact_id" => "station_calendar_report",
        "counteroffer_count" => 1,
        "reviewable_count" => 1,
        "counteroffer_status_counts" => %{"proposed" => 1},
        "required_operator_action_counts" => %{"review_provider_counteroffer" => 1},
        "rows" => [
          %{
            "id" => "provider_counteroffer:1:provider_offer_1",
            "provider_counteroffer_id" => "provider_offer_1",
            "provider_counteroffer_status" => "proposed",
            "reviewable" => true,
            "required_operator_action" => "review_provider_counteroffer"
          }
        ],
        "assumptions" => %{},
        "model_limits" => ["artifact_only"]
      },
      "source_station_calendar_report" => %{
        "schema_contract" => "station_calendar_report.v1",
        "affected_contacts" => [],
        "provider_calendar_contention_groups" => []
      },
      "source_station_reservation_report" => %{
        "schema_contract" => "station_reservation_report.v1",
        "source" => "station_calendar_report.reservation_evidence",
        "affected_contacts" => [
          %{
            "contact_id" => "dl_reserved_intruder",
            "station_reservation_match_status" => "overlap",
            "station_calendar_reservation_ids" => ["reservation_partner"],
            "station_calendar_reservation_statuses" => ["confirmed"],
            "station_calendar_reservation_expires_at_s" => [360.0],
            "required_operator_action" => "review_station_reservation_overlap",
            "trust_boundary" => "reservation_report_rows"
          }
        ],
        "provider_calendar_contention_groups" => [],
        "trust_boundary" => "reservation_report"
      },
      "source_station_reservation_hold_import_readiness_summary" => %{
        "model" => "artifact_only_station_reservation_hold_import_readiness_summary",
        "source_artifact_type" => "station_reservation_report.v1",
        "source" => "station_calendar_report.reservation_evidence",
        "reservation_hold_count" => 2,
        "import_readiness_status" => "review_required",
        "import_classification" => "review_only",
        "ready_for_import_count" => 0,
        "review_required_before_import_count" => 2,
        "no_import_required_count" => 0,
        "reservation_hold_import_status_counts" => %{
          "review_required_before_import" => 2
        },
        "required_import_action_counts" => %{
          "review_station_provider_contention" => 1,
          "review_station_reservation_overlap" => 1
        },
        "reservation_hold_ids" => ["reservation_expired", "reservation_missing"],
        "reservation_hold_ids_by_import_status" => %{
          "review_required_before_import" => ["reservation_expired", "reservation_missing"]
        },
        "reservation_hold_ids_by_required_import_action" => %{
          "review_station_provider_contention" => ["reservation_missing"],
          "review_station_reservation_overlap" => ["reservation_expired"]
        },
        "reservation_hold_contact_ids_by_import_status" => %{
          "review_required_before_import" => ["dl_reserved_intruder"]
        },
        "import_readiness_rows" => [
          %{
            "reservation_review_row_type" => "affected_contact",
            "contact_id" => "dl_reserved_intruder",
            "reservation_ids" => ["reservation_expired"],
            "reservation_statuses" => ["held"],
            "reserved_by" => ["ops_calendar"],
            "station_reservation_hold_import_status" => "review_required_before_import",
            "required_operator_action" => "review_station_reservation_overlap"
          },
          %{
            "reservation_review_row_type" => "provider_calendar_contention_group",
            "reservation_ids" => ["reservation_missing"],
            "reservation_statuses" => ["held"],
            "reserved_by" => ["partner_calendar"],
            "station_reservation_hold_import_status" => "review_required_before_import",
            "required_operator_action" => "review_station_provider_contention"
          }
        ],
        "assumptions" => %{
          "execution_boundary" => "artifact_only_no_provider_or_cadence_writes",
          "provider_write" => "not_performed_by_summary",
          "cadence_write" => "not_performed_by_summary",
          "reservation_acceptance" => "not_performed_by_summary"
        }
      },
      "source_contact_filter_report" => %{
        "schema_contract" => "contact_filter_report.v1",
        "suppressed_candidates" => [],
        "invalid_contact_inputs" => []
      },
      "source_contact_allocation_report" => %{
        "schema_contract" => "contact_allocation_report.v1",
        "rows" => []
      },
      "source_contact_contention_report" => %{
        "schema_contract" => "contact_contention_report.v1",
        "conflict_groups" => [],
        "invalid_contact_inputs" => []
      },
      "source_contact_contention_resolution_report" => %{
        "schema_contract" => "contact_contention_resolution_report.v1",
        "recommendations" => []
      },
      "source_link_capacity_report" => %{
        "schema_contract" => "link_capacity_report.v1",
        "rows" => []
      },
      "source_resource_projection_report" => %{
        "schema_contract" => "resource_projection_report.v1",
        "projected_resources" => []
      },
      "source_resource_filter_report" => %{
        "schema_contract" => "resource_filter_report.v1",
        "suppressed_candidates" => [],
        "invalid_resource_summary_inputs" => []
      },
      "source_timeline_diff_report" => %{
        "schema_contract" => "timeline_diff_report.v1",
        "rows" => []
      },
      "source_constraint_report" => %{
        "schema_contract" => "constraint_report.v1",
        "rows" => []
      },
      "source_objective_satisfaction_report" => %{
        "schema_contract" => "objective_satisfaction_report.v1",
        "rows" => []
      },
      "source_objective_tradeoff_report" => %{
        "schema_contract" => "objective_tradeoff_report.v1",
        "tradeoffs" => []
      },
      "source_score_term_report" => %{
        "schema_contract" => "score_term_report.v1",
        "rows" => []
      }
    }
  end

  defp passive_quality_gate_report do
    %{
      "schema_contract" => "quality_gate_report.v1",
      "model" => "artifact_only_operational_quality_gate_report",
      "report_id" => "quality_gate:planned_activity.v1:passive_source",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "passive_source",
      "source_readiness_report_id" => "operational_readiness:planned_activity.v1:passive_source",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "status" => "review_required",
      "gate_count" => 1,
      "passed_gate_count" => 0,
      "review_gate_count" => 1,
      "analysis_gate_count" => 0,
      "blocked_gate_count" => 0,
      "gate_status_counts" => %{"review_required" => 1},
      "gate_classification_counts" => %{"review_only" => 1},
      "rows" => [
        %{
          "id" => "quality_gate:passive_source:operator_review:1",
          "rank" => 1,
          "gate_id" => "operator_review",
          "status" => "review_required",
          "classification" => "review_only",
          "reason" => "operator review required"
        }
      ],
      "assumptions" => %{"source" => "test.quality_gate_report"},
      "model_limits" => ["artifact_only"]
    }
  end

  defp passive_model_acceptance_report do
    %{
      "schema_contract" => "model_acceptance_report.v1",
      "schema_version" => 1,
      "report_id" => "model_acceptance:operational_import:passive_source",
      "model" => "registry_model_acceptance_classifier",
      "intended_use" => "operational_import",
      "status" => "review_required",
      "model_count" => 1,
      "accepted_count" => 0,
      "review_required_count" => 1,
      "blocked_count" => 0,
      "unknown_model_count" => 0,
      "validation_level_counts" => %{"artifact_contract" => 1},
      "records" => [],
      "rows" => [
        %{
          "id" => "model_acceptance:passive_source",
          "rank" => 1,
          "model_id" => "passive_source",
          "validation_level" => "artifact_contract",
          "status" => "review_required",
          "reason" => "model acceptance requires review"
        }
      ],
      "assumptions" => %{"source" => "test.model_acceptance_report"},
      "model_limits" => ["artifact_only"]
    }
  end
end
