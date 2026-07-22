Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyBranchGeneratedCandidateRefreshTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{CandidateRefresh, Schema}

  test "strategy can execute a branch candidate refresh request before repair" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_500.0, "output_step_s" => 60.0},
        "activities" => [downlink("dl_1", 100.0, 160.0)],
        "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
      })

    artifact =
      strategy(prior_plan,
        branches: [
          %{id: "baseline"},
          %{
            id: "outage",
            events: [
              %{
                type: "ground_station_outage",
                ground_station_id: "equator_prime",
                starts_at_s: 90.0,
                ends_at_s: 200.0
              }
            ],
            candidate_refresh_request: branch_candidate_refresh_request()
          }
        ],
        current_epoch_s: 0.0
      )

    outage = branch(artifact, "outage")

    assert [
             %{
               "activity_id" => "dl_1",
               "repair_action" => "moved",
               "replacement_activity_id" => "leo_1_downlink_equator_prime_1"
             }
           ] =
             outage["repair_result"]["deltas"]
             |> Enum.filter(&(&1["activity_id"] == "dl_1"))

    assert Enum.any?(
             outage["repair_result"]["source_candidate_activities"],
             &(&1["id"] == "leo_1_downlink_equator_prime_1")
           )

    assert %{
             "type" => "candidate_refresh.v1",
             "snapshot_id" => "ops-state-branch",
             "scope" => "branch_generated"
           } = outage["assumptions"]["candidate_source"]

    assert outage["provenance"]["candidate_source"]["scope"] == "branch_generated"
  end

  test "branch candidate sources preserve source-summary input paths" do
    candidate_refresh_request =
      branch_candidate_refresh_request()
      |> update_in(["candidate_refresh"], fn refresh ->
        Map.merge(refresh, %{
          "source_provider_counteroffer_plan_impact_summary" => %{
            "model" => "artifact_only_provider_counteroffer_plan_impact_summary",
            "source_artifact_type" => "provider_counteroffer_report.v1",
            "counteroffer_count" => 1,
            "reviewable_count" => 1,
            "impact_rows" => [
              %{
                "provider_counteroffer_id" => "counteroffer_branch",
                "provider_counteroffer_status" => "proposed",
                "plan_impact_status" => "review_required",
                "required_operator_action" => "review_provider_counteroffer",
                "reviewable" => true
              }
            ]
          },
          "source_schema_validation_batch_report" => [
            %{
              "schema_contract" => "schema_validation_batch_report.v1",
              "validation_mode" => "artifact_directory",
              "status" => "fail",
              "reports" => [
                %{
                  "path" => "study_results/bad_candidate_refresh.json",
                  "report" => %{
                    "schema_contract" => "schema_validation_report.v1",
                    "validation_mode" => "artifact_file",
                    "validated_contract" => "candidate_refresh.v1",
                    "status" => "fail",
                    "error_count" => 1,
                    "warning_count" => 0,
                    "errors" => [
                      %{"path" => "$.candidate_activities", "message" => "is required"}
                    ],
                    "remediation" => [
                      %{
                        "path" => "$.candidate_activities",
                        "category" => "missing_required_field",
                        "action" => "populate candidate activities"
                      }
                    ]
                  }
                }
              ]
            }
          ],
          "source_resource_projection_flow_summary" => %{
            "schema_contract" => "resource_projection_flow_summary.v1",
            "projected_resources" => [],
            "invalid_activity_inputs" => [],
            "invalid_resource_summary_inputs" => []
          },
          "source_contact_allocation_provider_reservation_request_summary" => %{
            "model" => "artifact_only_contact_allocation_provider_reservation_request_summary",
            "source_artifact_type" => "contact_allocation_report.v1",
            "provider_reservation_request_rows" => [
              %{
                "contact_id" => "dl_provider_request",
                "allocation_status" => "allocated",
                "ground_station_id" => "equator_prime",
                "station_reservation_id" => "reservation_branch",
                "station_reservation_match_status" => "matched"
              }
            ],
            "provider_reservation_review_rows" => []
          }
        })
      end)

    artifact =
      strategy(base_plan(%{}),
        branches: [
          %{id: "baseline"},
          %{
            id: "outage",
            events: [
              %{
                type: "ground_station_outage",
                ground_station_id: "equator_prime",
                starts_at_s: 90.0,
                ends_at_s: 200.0
              }
            ],
            candidate_refresh_request: candidate_refresh_request
          }
        ],
        current_epoch_s: 0.0
      )

    candidate_source = get_in(branch(artifact, "outage"), ["assumptions", "candidate_source"])

    for source_path <- [
          "source_provider_counteroffer_plan_impact_summary",
          "source_schema_validation_batch_report",
          "source_resource_projection_flow_summary",
          "source_contact_allocation_provider_reservation_request_summary"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert "source_provider_counteroffer_plan_impact_summary" in CandidateRefresh.provider_counteroffer_replay_summary(
             candidate_source
           )[
             "source_report_paths"
           ]

    assert "source_schema_validation_batch_report[0].reports[0].report" in CandidateRefresh.schema_validation_replay_summary(
             candidate_source
           )[
             "source_report_paths"
           ]

    assert "source_resource_projection_flow_summary" in CandidateRefresh.resource_projection_replay_summary(
             candidate_source
           )[
             "source_report_paths"
           ]

    assert "source_contact_allocation_provider_reservation_request_summary" in CandidateRefresh.contact_allocation_replay_summary(
             candidate_source
           )[
             "source_report_paths"
           ]
  end

  test "strategy derives branch refresh requests from rich mission state" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> put_in([:candidate_refresh_defaults, :candidate_limit_policy], %{
        max_candidate_activities: 1
      })

    artifact =
      strategy(base_plan(%{"activities" => [downlink("dl_1", 100.0, 160.0)]}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert %{
             "type" => "candidate_refresh.v1",
             "snapshot_id" => "ops-rich",
             "scope" => "branch_generated"
           } = urgent["assumptions"]["candidate_source"]

    assert urgent["repair_result"]["repair_metadata"]["candidate_window_count"] > 0

    assert %{
             "schema_contract" => "refresh_budget_report.v1",
             "max_candidate_activities" => 1,
             "dropped_candidate_count" => 1,
             "kept_candidate_count" => 1
           } = urgent["repair_result"]["source_refresh_budget_report"]

    assert %{
             "branch_id" => "urgent",
             "review_type" => "refresh_budget_review",
             "source" => "campaign_strategy.branches.repair_result.source_refresh_budget_report",
             "required_operator_action" => "review_refresh_budget",
             "dropped_candidate_count" => 1,
             "source_refresh_budget_report" => %{"schema_contract" => "refresh_budget_report.v1"}
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "refresh_budget_review" and &1["branch_id"] == "urgent")
             )

    assert %{
             "branch_id" => "urgent",
             "import_action" => "review_refresh_budget",
             "source_review_type" => "refresh_budget_review",
             "dropped_candidate_count" => 1,
             "import_status" => "review_required_before_import"
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_refresh_budget" and &1["branch_id"] == "urgent")
             )

    assert length(urgent["repair_result"]["source_candidate_activities"]) == 1

    assert Enum.any?(
             urgent["repair_result"]["source_candidate_activities"],
             &(&1["type"] == "observe" and &1["target_id"] == "target_a")
           )

    assert urgent["provenance"]["candidate_source"]["scope"] == "branch_generated"
  end

  test "strategy carries mission-state result artifact source reports into branch refresh requests" do
    result_artifact_reports =
      passive_candidate_refresh_source_reports()
      |> Map.new(fn {key, report} ->
        {String.replace_prefix(key, "source_", ""), report}
      end)
      |> Map.put("candidate_diff_report", %{
        "schema_contract" => "candidate_diff_report.v1",
        "retained_candidates" => [
          %{
            "id" => "dl_branch_retained",
            "ground_station_id" => "equator_prime",
            "diff_reason" => "present_in_prior_candidate_set_with_semantic_changes",
            "semantic_change_reasons" => ["contact_window_shifted"],
            "candidate_diff_changed_fields" => ["starts_at_s"]
          }
        ],
        "new_candidates" => [
          %{
            "id" => "dl_branch_new",
            "source_window" => %{"ground_station_id" => "equator_prime"},
            "diff_reason" => "not_present_in_prior_candidate_set"
          }
        ],
        "invalidated_candidates" => [
          %{
            "id" => "dl_branch_stale",
            "source_window" => %{"ground_station_id" => "polar_prime"},
            "invalidated_reason" => "not_present_in_refreshed_candidate_set",
            "semantic_change_reasons" => ["station_reservation_changed"],
            "candidate_diff_changed_fields" => ["station_reservation_status"]
          }
        ]
      })
      |> Map.put("candidate_rejection_report", %{
        "schema_contract" => "candidate_rejection_report.v1",
        "rejected_count" => 2,
        "reviewable_count" => 1,
        "invalid_candidate_input_count" => 1,
        "rows" => [
          %{
            "candidate_id" => "dl_branch_rejected",
            "ground_station_id" => "equator_prime",
            "primary_rejection_reason" => "station_reserved",
            "required_operator_action" => "review_candidate_rejection"
          },
          %{
            "candidate_id" => "dl_branch_invalid",
            "ground_station_id" => "polar_prime",
            "primary_rejection_reason" => "invalid_candidate_input",
            "required_operator_action" => "none"
          }
        ],
        "trust_boundary" => "branch_candidate_rejection_report"
      })
      |> Map.put("operational_import_eligibility_summary", %{
        "schema_contract" => "operational_import_eligibility_summary.v1",
        "import_status" => "review_required_before_import",
        "ready_for_import_count" => 0,
        "review_required_count" => 1,
        "blocked_count" => 0,
        "rows" => [
          %{
            "id" => "branch_import_eligibility_review",
            "import_status" => "review_required_before_import",
            "required_operator_action" => "review_operational_readiness"
          }
        ],
        "trust_boundary" => "branch_import_eligibility_summary"
      })
      |> Map.put("timeline_diff_report", %{
        "schema_contract" => "timeline_diff_report.v1",
        "rows" => [
          %{
            "id" => "branch_duplicate_source",
            "diff_status" => "duplicate",
            "duplicate_timeline_identity_scope" => "source",
            "required_operator_action" => "review_duplicate_timeline_identity"
          },
          %{
            "id" => "branch_removed_downlink",
            "diff_status" => "removed",
            "source_activity_type" => "downlink",
            "source_ground_station_id" => "equator_prime",
            "source_required_downlink_mb" => 360.0,
            "required_operator_action" => "review_removed_activity"
          },
          %{
            "id" => "branch_removed_observation",
            "diff_status" => "removed",
            "source_activity_type" => "observe",
            "source_target_id" => "target_a",
            "required_operator_action" => "review_removed_activity"
          },
          %{
            "id" => "branch_changed_downlink",
            "diff_status" => "changed",
            "source_activity_type" => "downlink",
            "replacement_activity_type" => "downlink",
            "replacement_ground_station_id" => "equator_prime",
            "selected_downlink_shortfall_mb" => 120.0,
            "required_operator_action" => "review_timeline_change"
          },
          %{
            "id" => "branch_changed_contact",
            "diff_status" => "changed",
            "replacement_activity_type" => "tracking",
            "replacement_ground_station_id" => "dss_43",
            "contact_success_factor" => 0.25,
            "required_operator_action" => "review_timeline_change"
          },
          %{
            "id" => "branch_changed_observation",
            "diff_status" => "changed",
            "replacement_activity_type" => "observe",
            "replacement_target_id" => "target_b",
            "observation_success_factor" => 0.5,
            "image_quality_status" => "marginal",
            "required_operator_action" => "review_timeline_change"
          },
          %{
            "id" => "branch_changed_command",
            "diff_status" => "changed",
            "replacement_activity_type" => "command",
            "replacement_command_window_id" => "cmd_health_1",
            "command_success_factor" => 0.0,
            "required_operator_action" => "review_timeline_change"
          },
          %{
            "id" => "branch_changed_maneuver",
            "diff_status" => "changed",
            "replacement_activity_type" => "maneuver",
            "replacement_maneuver_id" => "burn_trim_1",
            "maneuver_success_factor" => 0.2,
            "required_operator_action" => "review_timeline_change"
          }
        ],
        "trust_boundary" => "branch_timeline_diff_report"
      })
      |> Map.put("station_calendar_report", %{
        "schema_contract" => "station_calendar_report.v1",
        "affected_contacts" => [
          %{
            "id" => "branch_station_calendar:dl_unavailable",
            "contact_id" => "dl_unavailable",
            "ground_station_id" => "equator_prime",
            "station_calendar_status" => "unavailable"
          },
          %{
            "id" => "branch_station_calendar:dl_reserved",
            "contact_id" => "dl_reserved",
            "ground_station_id" => "dss_43",
            "station_availability" => "reserved",
            "station_calendar_status" => "reserved"
          }
        ],
        "provider_calendar_contention_groups" => [
          %{
            "id" => "branch_station_calendar_provider_contention:equator_prime:1",
            "provider_ids" => ["ops_calendar", "partner_calendar"],
            "ground_station_id" => "equator_prime",
            "source_station_calendar_entries" => [
              %{"id" => "provider_a", "ground_station_id" => "equator_prime"},
              %{"id" => "provider_b", "ground_station_id" => "dss_43"}
            ]
          }
        ],
        "trust_boundary" => "branch_station_calendar_report"
      })
      |> Map.put("constraint_report", %{
        "schema_contract" => "constraint_report.v1",
        "rows" => [
          %{
            "constraint_id" => "branch_downlink_shortfall",
            "metric" => "selected_downlink_shortfall_mb",
            "scenario_id" => "leo_1",
            "status" => "warning",
            "value" => 40.0,
            "ground_station_id" => "equator_prime",
            "trust_boundary" => "branch_constraint_rows"
          },
          %{
            "constraint_id" => "branch_battery_margin",
            "metric" => "battery_margin",
            "scenario_id" => "leo_1",
            "spacecraft_id" => "scout_1",
            "status" => "fail",
            "resource_id" => "battery_1",
            "value" => -0.2,
            "trust_boundary" => "branch_constraint_rows"
          }
        ],
        "trust_boundary" => "branch_constraint_report"
      })
      |> Map.put("objective_satisfaction_report", %{
        "schema_contract" => "objective_satisfaction_report.v1",
        "rows" => [
          %{
            "objective" => "downlink_completion",
            "status" => "partial",
            "required_downlink_mb" => 30.0,
            "ground_station_id" => "equator_prime",
            "trust_boundary" => "branch_objective_rows"
          },
          %{
            "objective" => "target_coverage",
            "status" => "unmet",
            "target_id" => "target_a",
            "required_revisits" => 1.0,
            "trust_boundary" => "branch_objective_rows"
          },
          %{
            "objective" => "collection_latency",
            "status" => "partial",
            "collection_id" => "collection_alpha",
            "max_latency_s" => 600.0,
            "trust_boundary" => "branch_objective_rows"
          }
        ],
        "trust_boundary" => "branch_objective_report"
      })
      |> Map.put("objective_tradeoff_report", %{
        "schema_contract" => "objective_tradeoff_report.v1",
        "tradeoffs" => [
          %{
            "tradeoff_id" => "branch_tradeoff_downlink",
            "required_downlink_mb" => 20.0,
            "ground_station_id" => "equator_prime",
            "trust_boundary" => "branch_tradeoff_rows"
          },
          %{
            "tradeoff_id" => "branch_tradeoff_target",
            "target_id" => "target_a",
            "required_revisits" => 1.0,
            "trust_boundary" => "branch_tradeoff_rows"
          },
          %{
            "tradeoff_id" => "branch_tradeoff_latency",
            "collection_id" => "collection_alpha",
            "collection_latency_gap_s" => 300.0,
            "trust_boundary" => "branch_tradeoff_rows"
          }
        ],
        "trust_boundary" => "branch_tradeoff_report"
      })
      |> Map.put("score_term_report", %{
        "schema_contract" => "score_term_report.v1",
        "rows" => [
          %{
            "term_key" => "downlink_shortfall_mb",
            "value" => 20.0,
            "ground_station_id" => "equator_prime",
            "trust_boundary" => "branch_score_rows"
          },
          %{
            "term_key" => "target_gap_count",
            "value" => 1.0,
            "target_id" => "target_a",
            "trust_boundary" => "branch_score_rows"
          },
          %{
            "term_key" => "collection_latency_gap_s",
            "value" => 300.0,
            "collection_id" => "collection_alpha",
            "trust_boundary" => "branch_score_rows"
          }
        ],
        "trust_boundary" => "branch_score_report"
      })
      |> Map.put("contact_filter_report", %{
        "schema_contract" => "contact_filter_report.v1",
        "suppressed_candidates" => [
          %{
            "id" => "dl_branch_station_reserved",
            "ground_station_id" => "equator_prime",
            "suppressed_reason" => "ground_station_reserved"
          },
          %{
            "id" => "dl_branch_invalid_contact",
            "suppressed_reason" => "invalid_contact_input",
            "required_operator_action" => "review_invalid_contact_filter_input"
          }
        ],
        "trust_boundary" => "branch_contact_filter_report"
      })
      |> Map.put("resource_filter_report", %{
        "schema_contract" => "resource_filter_report.v1",
        "suppressed_candidates" => [
          %{
            "id" => "obs_branch_payload_block",
            "spacecraft_id" => "leo_1",
            "resource_id" => "payload_1",
            "suppressed_reason" => "payload_unavailable",
            "resource_blocking_dimension" => "payload"
          },
          %{
            "id" => "dl_branch_margin_block",
            "spacecraft_id" => "leo_1",
            "resource_summary_id" => "downlink_budget",
            "suppressed_reason" => "downlink_margin_low",
            "resource_blocking_dimension" => "communications"
          }
        ],
        "invalid_resource_summary_inputs" => [%{"resource_summary_id" => "bad_branch_summary"}],
        "trust_boundary" => "branch_resource_filter_report"
      })
      |> Map.put("resource_projection_report", %{
        "schema_contract" => "resource_projection_report.v1",
        "projected_resources" => [
          %{
            "spacecraft_id" => "leo_1",
            "resource_pressure_status" => "downlink_shortfall",
            "resource_pressure_types" => ["downlink_shortfall", "storage_pressure"],
            "first_resource_pressure_activity_id" => "dl_branch_pressure",
            "first_resource_pressure_ground_station_id" => "equator_prime"
          },
          %{
            "spacecraft_id" => "leo_2",
            "resource_pressure_status" => "storage_shortfall",
            "resource_pressure_types" => ["storage_shortfall"],
            "source_activity_ids" => ["imaging_branch"],
            "ground_station_id" => "polar_prime"
          }
        ],
        "invalid_activity_inputs" => [%{"activity_id" => "bad_branch_activity"}],
        "invalid_resource_summary_inputs" => [%{"spacecraft_id" => "bad_branch_resource"}],
        "trust_boundary" => "branch_resource_projection_report"
      })
      |> Map.put("link_capacity_report", %{
        "schema_contract" => "link_capacity_report.v1",
        "rows" => [
          %{
            "ground_station_id" => "equator_prime",
            "capacity_adjusted_throughput_mb" => 65.0,
            "selected_capacity_adjusted_throughput_mb" => 25.0,
            "unused_capacity_adjusted_throughput_mb" => 40.0,
            "selected_downlink_shortfall_mb" => 12.0,
            "actual_throughput_mb" => 21.0,
            "selected_contact_ids" => ["contact_alpha", "contact_beta"],
            "actual_throughput_contact_id" => "contact_alpha",
            "downlink_requirement_status" => "selected_shortfall",
            "actual_downlink_requirement_status" => "actual_met"
          },
          %{
            "ground_station_id" => "polar_prime",
            "capacity_adjusted_throughput_mb" => 20.0,
            "selected_capacity_adjusted_throughput_mb" => 15.0,
            "unused_capacity_adjusted_throughput_mb" => 5.0,
            "actual_downlink_shortfall_mb" => 7.0,
            "selected_contact_id" => "contact_gamma",
            "actual_throughput_contact_ids" => ["contact_gamma"],
            "downlink_requirement_status" => "selected_met",
            "actual_downlink_requirement_status" => "actual_shortfall"
          }
        ],
        "trust_boundary" => "branch_link_capacity_report"
      })
      |> Map.put("contact_allocation_report", %{
        "schema_contract" => "contact_allocation_report.v1",
        "rows" => [
          %{
            "contact_id" => "selected_branch_contact",
            "allocation_status" => "allocated",
            "capacity_pack_status" => "selected_by_reduced_station_capacity_pack",
            "ground_station_id" => "equator_prime",
            "required_capacity_fraction" => 0.25
          },
          %{
            "contact_id" => "deferred_branch_contact",
            "allocation_status" => "deferred",
            "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
            "ground_station_id" => "equator_prime",
            "required_capacity_fraction" => 0.35
          }
        ],
        "trust_boundary" => "branch_contact_allocation_report"
      })
      |> Map.put("contact_contention_report", %{
        "schema_contract" => "contact_contention_report.v1",
        "conflict_groups" => [
          %{
            "id" => "branch_contention_equator",
            "resource_scope" => "ground_station",
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "contact_ids" => ["dl_branch_primary", "dl_branch_backup"],
            "required_operator_action" => "review_contact_contention"
          }
        ],
        "invalid_contact_inputs" => [
          %{
            "id" => "invalid_branch_contention",
            "required_operator_action" => "review_invalid_contact_contention_input"
          }
        ],
        "trust_boundary" => "branch_contact_contention_report"
      })
      |> Map.put("contact_contention_resolution_report", %{
        "schema_contract" => "contact_contention_resolution_report.v1",
        "recommendations" => [
          %{
            "group_id" => "branch_contention_equator",
            "ground_station_id" => "equator_prime",
            "selected_contact_id" => "dl_branch_primary",
            "deferred_contact_ids" => ["dl_branch_backup"],
            "resolution_status" => "deferred",
            "selection_reason" => "highest_score",
            "source_contact_candidates" => [
              %{
                "id" => "dl_branch_primary",
                "ground_station_id" => "equator_prime",
                "required_capacity_percent" => "25"
              },
              %{
                "id" => "dl_branch_backup",
                "ground_station_id" => "equator_prime",
                "required_capacity_fraction" => 0.4
              }
            ]
          }
        ],
        "trust_boundary" => "branch_contact_contention_resolution_report"
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_command_window_report, %{
        "schema_contract" => "command_window_report.v1",
        "rows" => [
          %{
            "id" => "branch_cmd_failed",
            "activity_id" => "branch_cmd_failed",
            "command_success" => false,
            "provenance" => %{"trust_boundary" => "branch_command_window"}
          },
          %{
            "id" => "branch_cmd_partial",
            "activity_id" => "branch_cmd_partial",
            "command_success_factor" => 0.5,
            "provenance" => %{"trust_boundary" => "branch_command_window"}
          },
          %{
            "id" => "branch_cmd_no_feedback",
            "activity_id" => "branch_cmd_no_feedback",
            "command_result" => "success"
          }
        ]
      })
      |> Map.put(:source_maneuver_review_report, %{
        "schema_contract" => "maneuver_review_report.v1",
        "rows" => [
          %{
            "maneuver_id" => "branch_burn_success_uncertainty",
            "maneuver_success_factor" => 0.4,
            "execution_uncertainty" => %{"timing_3sigma_s" => 75.0},
            "provenance" => %{"trust_boundary" => "branch_maneuver_review"}
          },
          %{
            "maneuver_id" => "branch_burn_missing_uncertainty",
            "maneuver_success" => false,
            "execution_uncertainty_status" => "missing",
            "provenance" => %{"trust_boundary" => "branch_maneuver_review"}
          },
          %{
            "maneuver_id" => "branch_burn_no_feedback"
          }
        ]
      })
      |> Map.put(:source_timeline_transition_application_report, %{
        "schema_contract" => "timeline_transition_application_report.v1",
        "applications" => [
          %{
            "id" => "branch_timeline_application:selected",
            "application_status" => "selected",
            "transition_decision" => "apply",
            "required_operator_action" => "none"
          },
          %{
            "id" => "branch_timeline_application:review",
            "application_status" => "operator_review_required",
            "transition_decision" => "review",
            "required_operator_action" => "review_timeline_change",
            "timeline_identity_collision" => true,
            "duplicate_timeline_identity_scope" => "source"
          },
          %{
            "id" => "branch_timeline_application:withheld",
            "application_status" => "withheld_review",
            "transition_decision" => "withhold",
            "required_operator_action" => "review_duplicate_timeline_identity",
            "duplicate_timeline_identity_scope" => "replacement"
          }
        ],
        "provenance" => %{"trust_boundary" => "branch_transition_application"}
      })
      |> Map.put(:source_quality_gate_report, %{
        "schema_contract" => "quality_gate_report.v1",
        "source_readiness_report_id" => "operational_readiness:branch_activity",
        "readiness_level" => "blocked",
        "import_classification" => "review_only",
        "status" => "review_required",
        "rows" => [
          %{
            "id" => "quality_gate:branch_operational_mode",
            "status" => "analysis_only",
            "classification" => "analysis_only",
            "analysis_mode" => "simulation"
          },
          %{
            "id" => "quality_gate:branch_adapter_boundary",
            "status" => "review_required",
            "classification" => "review_only",
            "adapter_boundary_status_counts" => %{"missing" => 1}
          },
          %{
            "id" => "quality_gate:branch_resource_availability",
            "status" => "blocked",
            "classification" => "blocked",
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
            "station_availability_reason_ids" => ["ground_station_reserved"],
            "unavailable_resource_reason_ids" => ["payload_unavailable"],
            "resource_blocking_dimension_counts" => %{"communications" => 1}
          }
        ],
        "provenance" => %{"trust_boundary" => "branch_quality_gate_report"}
      })
      |> Map.put(:source_model_acceptance_report, %{
        "schema_contract" => "model_acceptance_report.v1",
        "intended_use" => "operational_import",
        "status" => "blocked",
        "model_count" => 4,
        "accepted_count" => 1,
        "review_required_count" => 1,
        "blocked_count" => 2,
        "unknown_model_count" => 1,
        "rows" => [
          %{
            "model_id" => "orbit_data.simple_json",
            "validation_level" => "artifact_contract",
            "status" => "accepted"
          },
          %{
            "model_id" => "event.access_windows",
            "validation_level" => "analysis",
            "status" => "review_required"
          },
          %{
            "model_id" => "propagator.two_body",
            "validation_level" => "educational",
            "status" => "blocked"
          },
          %{
            "model_id" => "missing.model",
            "validation_level" => "unknown",
            "status" => "blocked"
          }
        ],
        "records" => [
          %{"record_id" => "acceptance:orbit_data.simple_json"},
          %{"record_id" => "acceptance:event.access_windows"},
          %{"record_id" => "acceptance:propagator.two_body"}
        ],
        "provenance" => %{"trust_boundary" => "branch_model_acceptance_report"}
      })
      |> Map.put(
        :source_result_artifact,
        Map.merge(result_artifact_reports, %{
          "schema_contract" => "result_artifact.v1",
          "artifact_type" => "mission_state_result_artifact",
          "study_id" => "live_branch_refresh_sources",
          "provenance" => %{"trust_boundary" => "live_branch_refresh_wrapper"}
        })
      )

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    source_report_input_paths =
      get_in(urgent, ["assumptions", "candidate_source", "source_report_input_paths"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = urgent["assumptions"]["candidate_source"]

    for source_path <- [
          "mission_state.source_station_calendar_report",
          "mission_state.source_contact_filter_report",
          "mission_state.source_contact_allocation_report",
          "mission_state.source_contact_contention_report",
          "mission_state.source_contact_contention_resolution_report",
          "mission_state.source_link_capacity_report",
          "mission_state.source_freshness_report",
          "mission_state.source_refresh_budget_report",
          "mission_state.source_resource_projection_report",
          "mission_state.source_resource_filter_report",
          "mission_state.source_operational_readiness_report",
          "mission_state.source_command_window_report",
          "mission_state.source_maneuver_review_report",
          "mission_state.source_timeline_transition_application_report",
          "mission_state.source_quality_gate_report",
          "mission_state.source_model_acceptance_report",
          "mission_state.source_candidate_diff_report",
          "mission_state.source_station_reservation_report",
          "mission_state.source_station_reservation_hold_import_readiness_summary",
          "mission_state.source_timeline_diff_report"
        ] do
      assert source_path in source_report_input_paths
    end

    for source_path <- [
          "mission_state.source_result_artifact.station_calendar_report",
          "mission_state.source_result_artifact.contact_filter_report",
          "mission_state.source_result_artifact.contact_allocation_report",
          "mission_state.source_result_artifact.contact_contention_report",
          "mission_state.source_result_artifact.contact_contention_resolution_report",
          "mission_state.source_result_artifact.link_capacity_report",
          "mission_state.source_result_artifact.freshness_report",
          "mission_state.source_result_artifact.refresh_budget_report",
          "mission_state.source_result_artifact.resource_projection_report",
          "mission_state.source_result_artifact.resource_filter_report",
          "mission_state.source_result_artifact.operational_readiness_report",
          "mission_state.source_result_artifact.operational_import_eligibility_summary",
          "mission_state.source_result_artifact.provider_counteroffer_report",
          "mission_state.source_result_artifact.candidate_diff_report",
          "mission_state.source_result_artifact.candidate_rejection_report",
          "mission_state.source_result_artifact.station_reservation_report",
          "mission_state.source_result_artifact.station_reservation_hold_import_readiness_summary",
          "mission_state.source_result_artifact.timeline_diff_report",
          "mission_state.source_result_artifact.constraint_report",
          "mission_state.source_result_artifact.objective_satisfaction_report",
          "mission_state.source_result_artifact.objective_tradeoff_report",
          "mission_state.source_result_artifact.score_term_report"
        ] do
      assert source_path in source_report_input_paths
    end

    assert %{
             "source_report_candidate_diff_diff_reason_counts" => %{
               "not_present_in_prior_candidate_set" => 1,
               "present_in_prior_candidate_set_with_semantic_changes" => 1
             },
             "source_report_candidate_diff_invalidated_reason_counts" => %{
               "not_present_in_refreshed_candidate_set" => 1
             },
             "source_report_candidate_diff_changed_field_counts" => %{
               "starts_at_s" => 1,
               "station_reservation_status" => 1
             },
             "source_report_candidate_diff_candidate_id_counts" => %{
               "dl_branch_new" => 1,
               "dl_branch_retained" => 1,
               "dl_branch_stale" => 1
             },
             "source_report_candidate_diff_ground_station_counts" => %{
               "equator_prime" => 2,
               "polar_prime" => 1
             }
           } =
             get_in(urgent, [
               "assumptions",
               "candidate_source",
               "candidate_refresh_request_source_report_summary"
             ])

    candidate_diff_replay_summary =
      CandidateRefresh.candidate_diff_replay_summary(candidate_source)

    assert %{
             "contract" => "candidate_diff_report.v1",
             "source_report_paths" => candidate_diff_source_paths,
             "diff_reason_counts" => %{
               "not_present_in_prior_candidate_set" => 1,
               "present_in_prior_candidate_set_with_semantic_changes" => 1
             },
             "invalidated_reason_counts" => %{
               "not_present_in_refreshed_candidate_set" => 1
             },
             "semantic_change_reason_counts" => %{
               "contact_window_shifted" => 1,
               "station_reservation_changed" => 1
             },
             "candidate_diff_changed_field_counts" => %{
               "starts_at_s" => 1,
               "station_reservation_status" => 1
             },
             "candidate_diff_candidate_id_counts" => %{
               "dl_branch_new" => 1,
               "dl_branch_retained" => 1,
               "dl_branch_stale" => 1
             },
             "candidate_diff_ground_station_counts" => %{
               "equator_prime" => 2,
               "polar_prime" => 1
             },
             "branch_local_diff_pressure" => true,
             "branch_local_new_candidate_pressure" => true,
             "branch_local_invalidated_candidate_pressure" => true,
             "branch_local_semantic_change_pressure" => true
           } = candidate_diff_replay_summary

    assert "mission_state.source_candidate_diff_report" in candidate_diff_source_paths

    candidate_rejection_replay_summary =
      CandidateRefresh.candidate_rejection_replay_summary(candidate_source)

    assert %{
             "contract" => "candidate_rejection_report.v1",
             "source_report_paths" => candidate_rejection_source_paths,
             "rejected_count" => 2,
             "reviewable_count" => 1,
             "invalid_candidate_input_count" => 1,
             "rejection_reason_counts" => %{
               "invalid_candidate_input" => 1,
               "station_reserved" => 1
             },
             "required_operator_action_counts" => %{
               "none" => 1,
               "review_candidate_rejection" => 1
             },
             "candidate_rejection_candidate_id_counts" => %{
               "dl_branch_invalid" => 1,
               "dl_branch_rejected" => 1
             },
             "candidate_rejection_ground_station_counts" => %{
               "equator_prime" => 1,
               "polar_prime" => 1
             },
             "branch_local_rejection_pressure" => true,
             "branch_local_review_pressure" => true,
             "branch_local_invalid_input_pressure" => true
           } = candidate_rejection_replay_summary

    assert "mission_state.source_candidate_rejection_report" in candidate_rejection_source_paths

    freshness_replay_summary =
      CandidateRefresh.freshness_replay_summary(candidate_source)

    assert %{
             "contract" => "freshness_report.v1",
             "source_report_count" => 2,
             "source_report_row_count" => 2,
             "source_report_paths" => freshness_source_paths,
             "status_counts" => %{"fresh" => 2},
             "stale_reason_count" => 0,
             "unknown_reason_count" => 0,
             "branch_local_stale_pressure" => false,
             "branch_local_unknown_pressure" => false,
             "branch_local_freshness_pressure" => false
           } = freshness_replay_summary

    assert "mission_state.source_freshness_report" in freshness_source_paths
    assert "mission_state.source_result_artifact.freshness_report" in freshness_source_paths

    refresh_budget_replay_summary =
      CandidateRefresh.refresh_budget_replay_summary(candidate_source)

    assert %{
             "contract" => "refresh_budget_report.v1",
             "source_report_count" => 2,
             "source_report_row_count" => 2,
             "source_report_paths" => refresh_budget_source_paths,
             "input_candidate_count" => 2,
             "kept_candidate_count" => 2,
             "dropped_candidate_count" => 0,
             "invalid_candidate_limit_policy_count" => 0,
             "invalid_candidate_limit_policy_reason_counts" => %{},
             "kept_candidate_ids" => [],
             "dropped_candidate_ids" => [],
             "branch_local_budget_pressure" => false,
             "branch_local_dropped_candidate_pressure" => false,
             "branch_local_invalid_limit_pressure" => false,
             "branch_local_candidate_limit_applied" => false
           } = refresh_budget_replay_summary

    assert "mission_state.source_refresh_budget_report" in refresh_budget_source_paths

    assert "mission_state.source_result_artifact.refresh_budget_report" in refresh_budget_source_paths

    contact_filter_replay_summary =
      CandidateRefresh.contact_filter_replay_summary(candidate_source)

    assert %{
             "contract" => "contact_filter_report.v1",
             "source_report_count" => 2,
             "source_report_row_count" => 4,
             "source_report_paths" => contact_filter_source_paths,
             "suppressed_candidate_count" => 4,
             "invalid_contact_input_count" => 2,
             "suppressed_reason_counts" => %{
               "ground_station_reserved" => 2,
               "invalid_contact_input" => 2
             },
             "station_suppression_count" => 2,
             "station_suppression_ground_station_counts" => %{"equator_prime" => 2},
             "station_suppression_availability_counts" => %{"reserved" => 2},
             "station_suppression_status_counts" => %{"reserved" => 2},
             "branch_local_contact_filter_pressure" => true,
             "branch_local_candidate_suppression_pressure" => true,
             "branch_local_invalid_contact_input_pressure" => true,
             "branch_local_station_suppression_pressure" => true
           } = contact_filter_replay_summary

    assert "mission_state.source_contact_filter_report" in contact_filter_source_paths

    assert "mission_state.source_result_artifact.contact_filter_report" in contact_filter_source_paths

    resource_filter_replay_summary =
      CandidateRefresh.resource_filter_replay_summary(candidate_source)

    assert %{
             "contract" => "resource_filter_report.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 3,
             "source_report_paths" => resource_filter_source_paths,
             "suppressed_candidate_count" => 2,
             "invalid_resource_summary_input_count" => 1,
             "suppressed_reason_counts" => %{
               "downlink_margin_low" => 1,
               "payload_unavailable" => 1
             },
             "resource_filter_spacecraft_counts" => %{"leo_1" => 2},
             "resource_filter_resource_counts" => %{
               "downlink_budget" => 1,
               "payload_1" => 1
             },
             "resource_filter_blocking_dimension_counts" => %{
               "communications" => 1,
               "payload" => 1
             },
             "branch_local_resource_filter_pressure" => true,
             "branch_local_candidate_suppression_pressure" => true,
             "branch_local_invalid_resource_summary_pressure" => true,
             "branch_local_resource_blocking_pressure" => true
           } = resource_filter_replay_summary

    assert "mission_state.source_resource_filter_report" in resource_filter_source_paths

    resource_projection_replay_summary =
      CandidateRefresh.resource_projection_replay_summary(candidate_source)

    assert %{
             "contract" => "resource_projection_report.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 4,
             "source_report_paths" => resource_projection_source_paths,
             "projected_resource_count" => 2,
             "invalid_activity_input_count" => 1,
             "invalid_resource_summary_input_count" => 1,
             "resource_pressure_status_counts" => %{
               "downlink_shortfall" => 1,
               "storage_shortfall" => 1
             },
             "ground_station_counts" => %{
               "equator_prime" => 1,
               "polar_prime" => 1
             },
             "resource_projection_spacecraft_counts" => %{
               "leo_1" => 1,
               "leo_2" => 1
             },
             "resource_pressure_type_counts" => %{
               "downlink_shortfall" => 1,
               "storage_pressure" => 1,
               "storage_shortfall" => 1
             },
             "resource_pressure_activity_id_counts" => %{
               "dl_branch_pressure" => 1,
               "imaging_branch" => 1
             },
             "branch_local_resource_projection_pressure" => true,
             "branch_local_projected_resource_pressure" => true,
             "branch_local_invalid_resource_projection_pressure" => true,
             "branch_local_activity_pressure" => true
           } = resource_projection_replay_summary

    assert "mission_state.source_resource_projection_report" in resource_projection_source_paths

    storage_downlink_pressure_replay_summary =
      CandidateRefresh.storage_downlink_pressure_replay_summary(candidate_source)

    assert %{
             "source_report_count" => 3,
             "source_report_row_count" => 8,
             "source_report_families" => [
               "contact_allocation_report",
               "link_capacity_report",
               "resource_projection_report"
             ],
             "source_report_contracts" => [
               "contact_allocation_report.v1",
               "link_capacity_report.v1",
               "resource_projection_report.v1"
             ],
             "source_report_counts_by_family" => %{
               "contact_allocation_report" => 1,
               "link_capacity_report" => 1,
               "resource_projection_report" => 1
             },
             "source_report_row_counts_by_family" => %{
               "contact_allocation_report" => 2,
               "link_capacity_report" => 2,
               "resource_projection_report" => 4
             },
             "source_report_paths" => storage_downlink_source_paths,
             "contact_allocation_status_counts" => %{"allocated" => 1, "deferred" => 1},
             "capacity_pack_status_counts" => %{
               "deferred_by_reduced_station_capacity_pack" => 1,
               "selected_by_reduced_station_capacity_pack" => 1
             },
             "capacity_pack_required_capacity_fraction" => 0.6,
             "capacity_pack_selected_required_capacity_fraction" => 0.25,
             "capacity_pack_deferred_required_capacity_fraction" => 0.35,
             "capacity_pack_required_capacity_fraction_by_ground_station" => %{
               "equator_prime" => 0.6
             },
             "selected_shortfall_row_count" => 1,
             "actual_shortfall_row_count" => 1,
             "downlink_requirement_status_counts" => %{
               "actual_met" => 1,
               "actual_shortfall" => 1,
               "selected_met" => 1,
               "selected_shortfall" => 1
             },
             "capacity_adjusted_throughput_mb_total" => 85.0,
             "selected_capacity_adjusted_throughput_mb_total" => 40.0,
             "unused_capacity_adjusted_throughput_mb_total" => 45.0,
             "selected_contact_id_counts" => %{
               "contact_alpha" => 1,
               "contact_beta" => 1,
               "contact_gamma" => 1
             },
             "actual_throughput_contact_id_counts" => %{
               "contact_alpha" => 1,
               "contact_gamma" => 1
             },
             "resource_projection_spacecraft_counts" => %{"leo_1" => 1, "leo_2" => 1},
             "ground_station_counts" => %{
               "equator_prime" => 2,
               "polar_prime" => 2
             },
             "resource_pressure_activity_id_counts" => %{
               "dl_branch_pressure" => 1,
               "imaging_branch" => 1
             },
             "storage_pressure_status_counts" => %{"storage_shortfall" => 1},
             "storage_pressure_type_counts" => %{
               "storage_pressure" => 1,
               "storage_shortfall" => 1
             },
             "downlink_pressure_status_counts" => %{"downlink_shortfall" => 1},
             "downlink_pressure_type_counts" => %{"downlink_shortfall" => 1},
             "branch_local_storage_downlink_pressure" => true,
             "branch_local_storage_pressure" => true,
             "branch_local_downlink_pressure" => true,
             "branch_local_capacity_pack_pressure" => true,
             "branch_local_downlink_shortfall_pressure" => true,
             "branch_local_capacity_adjusted_throughput_pressure" => true,
             "branch_local_resource_activity_pressure" => true
           } = storage_downlink_pressure_replay_summary

    for source_path <- [
          "mission_state.source_contact_allocation_report",
          "mission_state.source_link_capacity_report",
          "mission_state.source_resource_projection_report"
        ] do
      assert source_path in storage_downlink_source_paths
    end

    link_capacity_replay_summary =
      CandidateRefresh.link_capacity_replay_summary(candidate_source)

    assert %{
             "contract" => "link_capacity_report.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 2,
             "source_report_paths" => link_capacity_source_paths,
             "selected_shortfall_row_count" => 1,
             "actual_shortfall_row_count" => 1,
             "actual_throughput_row_count" => 1,
             "capacity_adjusted_throughput_row_count" => 2,
             "capacity_adjusted_throughput_mb_total" => 85.0,
             "selected_capacity_adjusted_throughput_mb_total" => 40.0,
             "unused_capacity_adjusted_throughput_mb_total" => 45.0,
             "ground_station_counts" => %{"equator_prime" => 1, "polar_prime" => 1},
             "selected_contact_id_counts" => %{
               "contact_alpha" => 1,
               "contact_beta" => 1,
               "contact_gamma" => 1
             },
             "actual_throughput_contact_id_counts" => %{
               "contact_alpha" => 1,
               "contact_gamma" => 1
             },
             "downlink_requirement_status_counts" => %{
               "actual_met" => 1,
               "actual_shortfall" => 1,
               "selected_met" => 1,
               "selected_shortfall" => 1
             },
             "branch_local_link_capacity_pressure" => true,
             "branch_local_capacity_adjusted_throughput_pressure" => true,
             "branch_local_downlink_shortfall_pressure" => true,
             "branch_local_actual_throughput_pressure" => true
           } = link_capacity_replay_summary

    assert "mission_state.source_link_capacity_report" in link_capacity_source_paths

    contact_allocation_replay_summary =
      CandidateRefresh.contact_allocation_replay_summary(candidate_source)

    assert %{
             "contract" => "contact_allocation_report.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 2,
             "source_report_paths" => contact_allocation_source_paths,
             "blocked_row_count" => 0,
             "deferred_row_count" => 1,
             "allocation_status_counts" => %{"allocated" => 1, "deferred" => 1},
             "capacity_pack_status_counts" => %{
               "deferred_by_reduced_station_capacity_pack" => 1,
               "selected_by_reduced_station_capacity_pack" => 1
             },
             "capacity_pack_contact_status_counts" => %{
               "deferred_by_reduced_station_capacity_pack" => 1,
               "selected_by_reduced_station_capacity_pack" => 1
             },
             "capacity_pack_required_capacity_fraction" => 0.6,
             "capacity_pack_selected_required_capacity_fraction" => 0.25,
             "capacity_pack_deferred_required_capacity_fraction" => 0.35,
             "capacity_pack_required_capacity_fraction_by_status" => %{
               "deferred_by_reduced_station_capacity_pack" => 0.35,
               "selected_by_reduced_station_capacity_pack" => 0.25
             },
             "capacity_pack_required_capacity_fraction_by_ground_station" => %{
               "equator_prime" => 0.6
             },
             "branch_local_contact_allocation_pressure" => true,
             "branch_local_blocked_allocation_pressure" => false,
             "branch_local_deferred_allocation_pressure" => true,
             "branch_local_station_pressure" => false,
             "branch_local_capacity_pack_pressure" => true
           } = contact_allocation_replay_summary

    assert "mission_state.source_contact_allocation_report" in contact_allocation_source_paths

    contact_contention_replay_summary =
      CandidateRefresh.contact_contention_replay_summary(candidate_source)

    assert %{
             "contract" => "contact_contention_report.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 2,
             "source_report_paths" => contact_contention_source_paths,
             "conflict_group_count" => 1,
             "invalid_contact_input_count" => 1,
             "resource_scope_counts" => %{"ground_station" => 1},
             "contact_contention_ground_station_counts" => %{"equator_prime" => 1},
             "contact_contention_contact_id_counts" => %{
               "dl_branch_backup" => 1,
               "dl_branch_primary" => 1
             },
             "required_operator_action_counts" => %{
               "review_contact_contention" => 1,
               "review_invalid_contact_contention_input" => 1
             },
             "branch_local_contact_contention_pressure" => true,
             "branch_local_contact_contention_conflict_pressure" => true,
             "branch_local_invalid_contact_input_pressure" => true,
             "branch_local_contact_contention_review_pressure" => true
           } = contact_contention_replay_summary

    assert "mission_state.source_contact_contention_report" in contact_contention_source_paths

    contact_contention_resolution_replay_summary =
      CandidateRefresh.contact_contention_resolution_replay_summary(candidate_source)

    assert %{
             "contract" => "contact_contention_resolution_report.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 1,
             "source_report_paths" => contact_contention_resolution_source_paths,
             "recommendation_count" => 1,
             "deferred_contact_count" => 1,
             "resolution_status_counts" => %{"deferred" => 1},
             "selection_reason_counts" => %{"highest_score" => 1},
             "capacity_pack_required_capacity_fraction" => 0.65,
             "capacity_pack_selected_required_capacity_fraction" => 0.25,
             "capacity_pack_deferred_required_capacity_fraction" => 0.4,
             "capacity_pack_required_capacity_fraction_by_ground_station" => %{
               "equator_prime" => 0.65
             },
             "capacity_pack_selected_required_capacity_fraction_by_ground_station" => %{
               "equator_prime" => 0.25
             },
             "capacity_pack_deferred_required_capacity_fraction_by_ground_station" => %{
               "equator_prime" => 0.4
             },
             "branch_local_contact_contention_resolution_pressure" => true,
             "branch_local_deferred_contact_pressure" => true,
             "branch_local_capacity_pack_pressure" => true
           } = contact_contention_resolution_replay_summary

    assert "mission_state.source_contact_contention_resolution_report" in contact_contention_resolution_source_paths

    operational_readiness_replay_summary =
      CandidateRefresh.operational_readiness_replay_summary(candidate_source)

    assert %{
             "contract" => "operational_readiness_report.v1",
             "source_report_count" => 2,
             "source_report_row_count" => 2,
             "source_report_paths" => operational_readiness_source_paths,
             "readiness_level_counts" => %{"operator_review" => 2},
             "import_classification_counts" => %{"review_only" => 2},
             "status_counts" => %{"review_required" => 2},
             "gate_count" => 8,
             "passed_gate_count" => 4,
             "review_gate_count" => 4,
             "analysis_gate_count" => 0,
             "blocked_gate_count" => 0,
             "branch_local_review_pressure" => true,
             "branch_local_import_pressure" => false,
             "branch_local_resource_pressure" => false
           } = operational_readiness_replay_summary

    assert "mission_state.source_operational_readiness_report" in operational_readiness_source_paths

    assert "mission_state.source_result_artifact.operational_readiness_report" in operational_readiness_source_paths

    quality_gate_replay_summary =
      CandidateRefresh.quality_gate_replay_summary(candidate_source)

    assert %{
             "contract" => "quality_gate_report.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 3,
             "source_report_paths" => quality_gate_source_paths,
             "readiness_level_counts" => %{"blocked" => 1},
             "import_classification_counts" => %{"blocked" => 1},
             "status_counts" => %{"blocked" => 1},
             "gate_count" => 3,
             "passed_gate_count" => 0,
             "review_gate_count" => 1,
             "analysis_gate_count" => 1,
             "analysis_mode_counts" => %{"simulation" => 1},
             "blocked_gate_count" => 1,
             "gate_status_counts" => %{
               "analysis_only" => 1,
               "blocked" => 1,
               "review_required" => 1
             },
             "gate_classification_counts" => %{
               "analysis_only" => 1,
               "blocked" => 1,
               "review_only" => 1
             },
             "ready_for_import_count" => 0,
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
             "station_availability_reason_ids" => ["ground_station_reserved"],
             "station_availability_reason_counts" => %{"ground_station_reserved" => 1},
             "unavailable_resource_reason_ids" => ["payload_unavailable"],
             "resource_blocking_dimension_counts" => %{"communications" => 1},
             "source_readiness_report_count" => 1,
             "branch_local_review_pressure" => true,
             "branch_local_import_pressure" => true
           } = quality_gate_replay_summary

    assert "mission_state.source_quality_gate_report" in quality_gate_source_paths

    model_acceptance_replay_summary =
      CandidateRefresh.model_acceptance_replay_summary(candidate_source)

    assert %{
             "contract" => "model_acceptance_report.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 4,
             "source_report_record_count" => 3,
             "source_report_paths" => model_acceptance_source_paths,
             "intended_use_counts" => %{"operational_import" => 1},
             "status_counts" => %{"blocked" => 1},
             "model_count" => 4,
             "accepted_count" => 1,
             "review_required_count" => 1,
             "blocked_count" => 2,
             "unknown_model_count" => 1,
             "validation_level_counts" => %{
               "analysis" => 1,
               "artifact_contract" => 1,
               "educational" => 1,
               "unknown" => 1
             },
             "model_ids_by_status" => %{
               "accepted" => ["orbit_data.simple_json"],
               "blocked" => ["propagator.two_body", "missing.model"],
               "review_required" => ["event.access_windows"]
             },
             "model_ids_by_validation_level" => %{
               "analysis" => ["event.access_windows"],
               "artifact_contract" => ["orbit_data.simple_json"],
               "educational" => ["propagator.two_body"],
               "unknown" => ["missing.model"]
             },
             "model_ids_by_intended_use" => %{
               "operational_import" => [
                 "orbit_data.simple_json",
                 "event.access_windows",
                 "propagator.two_body",
                 "missing.model"
               ]
             },
             "trust_boundary_status" => "declared",
             "branch_local_review_pressure" => true,
             "branch_local_blocking_pressure" => true,
             "branch_local_unknown_model_pressure" => true
           } = model_acceptance_replay_summary

    assert "mission_state.source_model_acceptance_report" in model_acceptance_source_paths

    provider_counteroffer_replay_summary =
      CandidateRefresh.provider_counteroffer_replay_summary(candidate_source)

    assert %{
             "contract" => "provider_counteroffer_report.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 1,
             "source_report_paths" => provider_counteroffer_source_paths,
             "reviewable_count" => 1,
             "counteroffer_status_counts" => %{"proposed" => 1},
             "required_operator_action_counts" => %{"review_provider_counteroffer" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["live_branch_refresh_wrapper"],
             "branch_local_counteroffer_pressure" => true,
             "branch_local_counteroffer_review_pressure" => true,
             "branch_local_counteroffer_cost_pressure" => false,
             "branch_local_counteroffer_timing_pressure" => false,
             "branch_local_counteroffer_lock_pressure" => false,
             "branch_local_plan_impact_pressure" => false
           } = provider_counteroffer_replay_summary

    assert "mission_state.source_provider_counteroffer_report" in provider_counteroffer_source_paths

    station_reservation_replay_summary =
      CandidateRefresh.station_reservation_replay_summary(candidate_source)

    assert %{
             "contract" => "station_reservation_report.v1",
             "branch_local_station_reservation_pressure" => true,
             "branch_local_reservation_review_pressure" => true,
             "branch_local_reservation_hold_import_readiness_pressure" => true,
             "station_reservation_match_status_counts" => %{"overlap" => overlap_count},
             "reservation_ids" => reservation_ids,
             "source_report_paths" => station_reservation_source_paths
           } = station_reservation_replay_summary

    assert station_reservation_replay_summary["reservation_hold_count"] >= 2

    assert get_in(
             station_reservation_replay_summary,
             ["reservation_hold_import_readiness_status_counts", "review_required"]
           ) >= 1

    assert get_in(
             station_reservation_replay_summary,
             [
               "reservation_hold_required_import_action_counts",
               "review_station_provider_contention"
             ]
           ) >= 1

    assert get_in(
             station_reservation_replay_summary,
             [
               "reservation_hold_required_import_action_counts",
               "review_station_reservation_overlap"
             ]
           ) >= 1

    assert overlap_count >= 1
    assert "reservation_partner" in reservation_ids

    assert "mission_state.source_station_reservation_report" in station_reservation_source_paths

    assert "mission_state.source_station_reservation_hold_import_readiness_summary" in station_reservation_source_paths

    assert "mission_state.source_result_artifact.station_reservation_hold_import_readiness_summary" in station_reservation_source_paths

    station_calendar_replay_summary =
      CandidateRefresh.station_calendar_replay_summary(candidate_source)

    assert %{
             "contract" => "station_calendar_report.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 3,
             "source_report_paths" => station_calendar_source_paths,
             "affected_contact_count" => 2,
             "provider_calendar_contention_group_count" => 1,
             "provider_calendar_contention_provider_counts" => %{
               "ops_calendar" => 1,
               "partner_calendar" => 1
             },
             "provider_calendar_contention_ground_station_counts" => %{
               "dss_43" => 1,
               "equator_prime" => 1
             },
             "station_calendar_status_counts" => %{
               "reserved" => 1,
               "unavailable" => 1
             },
             "affected_contact_ground_station_counts" => %{
               "dss_43" => 1,
               "equator_prime" => 1
             },
             "affected_contact_availability_counts" => %{
               "reserved" => 1,
               "unavailable" => 1
             },
             "trust_boundary_status" => "declared",
             "branch_local_station_calendar_pressure" => true,
             "branch_local_affected_contact_pressure" => true,
             "branch_local_provider_contention_pressure" => true,
             "branch_local_station_availability_pressure" => true
           } = station_calendar_replay_summary

    assert "mission_state.source_station_calendar_report" in station_calendar_source_paths

    timeline_diff_replay_summary =
      CandidateRefresh.timeline_diff_replay_summary(candidate_source)

    assert %{
             "contract" => "timeline_diff_report.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 8,
             "source_report_paths" => timeline_diff_source_paths,
             "duplicate_timeline_identity_count" => 1,
             "duplicate_source_timeline_identity_count" => 1,
             "duplicate_replacement_timeline_identity_count" => 0,
             "removed_downlink_count" => 1,
             "removed_observation_count" => 1,
             "changed_downlink_shortfall_count" => 1,
             "changed_contact_feedback_count" => 1,
             "changed_observation_count" => 1,
             "changed_observation_quality_feedback_count" => 1,
             "changed_command_feedback_count" => 1,
             "changed_maneuver_feedback_count" => 1,
             "diff_status_counts" => %{
               "changed" => 5,
               "duplicate" => 1,
               "removed" => 2
             },
             "required_operator_action_counts" => %{
               "review_duplicate_timeline_identity" => 1,
               "review_removed_activity" => 2,
               "review_timeline_change" => 5
             },
             "duplicate_timeline_identity_scope_counts" => %{
               "source" => 1
             },
             "branch_local_timeline_diff_pressure" => true,
             "branch_local_duplicate_identity_pressure" => true,
             "branch_local_removed_activity_pressure" => true,
             "branch_local_changed_activity_pressure" => true,
             "branch_local_operator_review_pressure" => true
           } = timeline_diff_replay_summary

    assert "mission_state.source_timeline_diff_report" in timeline_diff_source_paths

    constraint_replay_summary =
      CandidateRefresh.constraint_replay_summary(candidate_source)

    assert %{
             "contract" => "constraint_report.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 2,
             "source_report_paths" => constraint_source_paths,
             "downlink_gap_row_count" => 1,
             "resource_margin_row_count" => 1,
             "status_counts" => %{"fail" => 1, "warning" => 1},
             "ground_station_counts" => %{"equator_prime" => 1},
             "constraint_metric_counts" => %{
               "battery_margin" => 1,
               "selected_downlink_shortfall_mb" => 1
             },
             "constraint_resource_counts" => %{"battery_1" => 1},
             "constraint_spacecraft_counts" => %{"scout_1" => 1},
             "branch_local_constraint_pressure" => true,
             "branch_local_downlink_gap_pressure" => true,
             "branch_local_resource_margin_pressure" => true,
             "branch_local_constraint_routing_pressure" => true
           } = constraint_replay_summary

    assert "mission_state.source_constraint_report" in constraint_source_paths

    objective_gap_replay_summary =
      CandidateRefresh.objective_gap_replay_summary(candidate_source)

    assert %{
             "contracts" => [
               "objective_satisfaction_report.v1",
               "objective_tradeoff_report.v1",
               "score_term_report.v1"
             ],
             "source_report_count" => 3,
             "source_report_row_count" => 9,
             "source_report_paths" => objective_gap_source_paths,
             "routed_gap_signal_count" => 10,
             "downlink_gap_row_count" => 3,
             "target_gap_row_count" => 3,
             "collection_latency_gap_row_count" => 4,
             "objective_satisfaction_gap_row_count" => 3,
             "objective_satisfaction_status_counts" => %{
               "partial" => 2,
               "unmet" => 1
             },
             "objective_satisfaction_objective_type_counts" => %{
               "collection_latency" => 1,
               "downlink_completion" => 1,
               "target_coverage" => 1
             },
             "objective_tradeoff_downlink_gap_row_count" => 1,
             "objective_tradeoff_target_gap_row_count" => 1,
             "objective_tradeoff_collection_latency_gap_row_count" => 2,
             "score_term_downlink_gap_row_count" => 1,
             "score_term_target_gap_row_count" => 1,
             "score_term_collection_latency_gap_row_count" => 1,
             "score_term_key_counts" => %{
               "collection_latency_gap_s" => 1,
               "downlink_shortfall_mb" => 1,
               "target_gap_count" => 1
             },
             "ground_station_counts" => %{"equator_prime" => 3},
             "target_counts" => %{"target_a" => 3},
             "collection_counts" => %{"collection_alpha" => 3},
             "trust_boundary_status_counts" => %{"declared" => 3},
             "branch_local_objective_gap_pressure" => true,
             "branch_local_downlink_gap_pressure" => true,
             "branch_local_target_gap_pressure" => true,
             "branch_local_collection_latency_gap_pressure" => true,
             "branch_local_objective_status_pressure" => true,
             "branch_local_score_term_pressure" => true,
             "branch_local_routing_pressure" => true
           } = objective_gap_replay_summary

    assert Enum.sort(objective_gap_source_paths) == [
             "mission_state.source_objective_satisfaction_report",
             "mission_state.source_objective_tradeoff_report",
             "mission_state.source_score_term_report"
           ]

    objective_gap_pressure_count =
      Enum.count(
        urgent["risk_indicators"],
        &(&1["type"] == "objective_gap_pressure" and
            &1["feedback_source"] == "candidate_source.objective_gap_replay_summary")
      )

    assert objective_gap_pressure_count == 1

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "objective_gap_pressure" and
                 &1["contracts"] == [
                   "objective_satisfaction_report.v1",
                   "objective_tradeoff_report.v1",
                   "score_term_report.v1"
                 ] and
                 &1["source_report_count"] == 3 and
                 &1["source_report_row_count"] == 9 and
                 &1["routed_gap_signal_count"] == 10 and
                 &1["downlink_gap_row_count"] == 3 and
                 &1["target_gap_row_count"] == 3 and
                 &1["collection_latency_gap_row_count"] == 4 and
                 &1["objective_satisfaction_status_counts"] == %{
                   "partial" => 2,
                   "unmet" => 1
                 } and
                 &1["score_term_key_counts"] == %{
                   "collection_latency_gap_s" => 1,
                   "downlink_shortfall_mb" => 1,
                   "target_gap_count" => 1
                 } and
                 &1["ground_station_counts"] == %{"equator_prime" => 3} and
                 &1["target_counts"] == %{"target_a" => 3} and
                 &1["collection_counts"] == %{"collection_alpha" => 3} and
                 &1["trust_boundary_status_counts"] == %{"declared" => 3} and
                 &1["assumptions"]["score_recalculation"] == "not_performed_by_summary")
           )

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    assert urgent["score_terms"]["objective_gap_pressure_penalty"] ==
             -objective_gap_pressure_count * risk_weight

    assert "objective_gap_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == "urgent" and
                 &1["term_key"] == "objective_gap_pressure_penalty" and &1["value"] < 0.0)
           )

    urgent_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))

    assert "objective_gap_pressure" in urgent_row["risk_types"]

    assert urgent_row["branch_objective_gap_source_report_paths"] == [
             "mission_state.source_objective_satisfaction_report",
             "mission_state.source_objective_tradeoff_report",
             "mission_state.source_score_term_report"
           ]

    assert urgent_row["branch_objective_gap_score_term_keys"] == [
             "collection_latency_gap_s",
             "downlink_shortfall_mb",
             "target_gap_count"
           ]

    assert urgent_row["branch_objective_gap_statuses"] == ["partial", "unmet"]
    assert urgent_row["branch_objective_gap_target_ids"] == ["target_a"]
    assert urgent_row["branch_objective_gap_collection_ids"] == ["collection_alpha"]

    command_window_replay_summary =
      CandidateRefresh.command_window_replay_summary(candidate_source)

    assert %{
             "contract" => "command_window_report.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 3,
             "source_report_paths" => command_window_source_paths,
             "command_feedback_count" => 2,
             "input_keys" => ["command_success_rate"],
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["branch_command_window"],
             "branch_local_command_window_pressure" => true,
             "branch_local_command_feedback_pressure" => true
           } = command_window_replay_summary

    assert "mission_state.source_command_window_report" in command_window_source_paths

    maneuver_review_replay_summary =
      CandidateRefresh.maneuver_review_replay_summary(candidate_source)

    assert %{
             "contract" => "maneuver_review_report.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 3,
             "source_report_paths" => maneuver_review_source_paths,
             "maneuver_success_feedback_count" => 2,
             "execution_uncertainty_declared_count" => 1,
             "execution_uncertainty_missing_count" => 1,
             "input_keys" => [
               "maneuver_execution_uncertainty",
               "maneuver_success_rate"
             ],
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["branch_maneuver_review"],
             "branch_local_maneuver_review_pressure" => true,
             "branch_local_maneuver_feedback_pressure" => true,
             "branch_local_execution_uncertainty_pressure" => true
           } = maneuver_review_replay_summary

    assert "mission_state.source_maneuver_review_report" in maneuver_review_source_paths

    timeline_transition_application_replay_summary =
      CandidateRefresh.timeline_transition_application_replay_summary(candidate_source)

    assert %{
             "contract" => "timeline_transition_application_report.v1",
             "source_report_count" => 1,
             "source_application_count" => 3,
             "source_report_paths" => timeline_transition_application_source_paths,
             "selected_activity_count" => 1,
             "review_required_count" => 2,
             "preserved_source_count" => 0,
             "recorded_replacement_count" => 0,
             "withheld_review_count" => 2,
             "duplicate_timeline_identity_count" => 2,
             "duplicate_source_timeline_identity_count" => 1,
             "duplicate_replacement_timeline_identity_count" => 1,
             "application_status_counts" => %{
               "operator_review_required" => 1,
               "selected" => 1,
               "withheld_review" => 1
             },
             "transition_decision_counts" => %{
               "apply" => 1,
               "review" => 1,
               "withhold" => 1
             },
             "required_operator_action_counts" => %{
               "none" => 1,
               "review_duplicate_timeline_identity" => 1,
               "review_timeline_change" => 1
             },
             "duplicate_timeline_identity_scope_counts" => %{
               "replacement" => 1,
               "source" => 1
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["branch_transition_application"],
             "branch_local_timeline_transition_application_pressure" => true,
             "branch_local_selected_activity_pressure" => true,
             "branch_local_review_required_pressure" => true,
             "branch_local_preserved_transition_pressure" => false,
             "branch_local_duplicate_identity_pressure" => true,
             "branch_local_operator_review_pressure" => true
           } = timeline_transition_application_replay_summary

    assert "mission_state.source_timeline_transition_application_report" in timeline_transition_application_source_paths

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
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
end
