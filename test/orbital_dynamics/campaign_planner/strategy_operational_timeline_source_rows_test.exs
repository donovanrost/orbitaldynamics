Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyOperationalTimelineSourceRowsTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{CandidateRefresh, Schema}

  test "strategy derives branch-local refresh from direct operational timeline rows" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          command("cmd_timeline", "leo_1", 100.0, 130.0),
          downlink("dl_timeline", 200.0, 260.0)
          |> Map.put("estimated_throughput_mb", 100.0),
          observe("obs_timeline", "leo_1", "target_a", 300.0, 340.0, 8.0)
        ],
        "operational_timeline_report" => %{
          "schema_contract" => "operational_timeline_report.v1",
          "source" => "cadence.operational_timeline",
          "row_count" => 3,
          "provenance" => %{"trust_boundary" => "cadence_timeline_export"},
          "rows" => [
            %{
              "id" => "timeline_row:cmd_timeline",
              "activity_id" => "cmd_timeline",
              "activity_type" => "command",
              "scenario_id" => "leo_1",
              "starts_at_s" => 100.0,
              "ends_at_s" => 130.0,
              "status" => "planned",
              "timeline_id" => "timeline:leo_1:command:cmd_timeline",
              "ground_station_id" => "equator_prime",
              "direction" => "uplink",
              "dependency_activity_ids" => ["cmd_prepare"],
              "dependency_order_violation_activity_ids" => ["cmd_prepare"],
              "command_success_factor" => 0.4,
              "command_result" => ["accepted", "failed"],
              "feedback_weight" => 2.0,
              "feedback_weight_source" => "cadence.timeline_sample_count"
            },
            %{
              "id" => "timeline_row:dl_timeline",
              "activity_id" => "dl_timeline",
              "activity_type" => "downlink",
              "scenario_id" => "leo_1",
              "starts_at_s" => 200.0,
              "ends_at_s" => 260.0,
              "status" => "planned",
              "timeline_id" => "timeline:leo_1:downlink:dl_timeline",
              "ground_station_id" => "equator_prime",
              "direction" => "downlink",
              "exclusive_with_activity_ids" => ["dl_partner"],
              "exclusivity_group" => "equator_prime_downlink",
              "exclusivity_violation_activity_ids" => ["dl_partner"],
              "exclusivity_violation_group" => "equator_prime_downlink",
              "contact_success_factor" => 0.5,
              "contact_result" => ["accepted", "dropped"],
              "actual_throughput_mb" => 40.0,
              "estimated_throughput_mb" => 100.0,
              "required_downlink_mb" => 80.0
            },
            %{
              "id" => "timeline_row:obs_timeline",
              "activity_id" => "obs_timeline",
              "activity_type" => "observe",
              "scenario_id" => "leo_1",
              "target_id" => "target_a",
              "starts_at_s" => 300.0,
              "ends_at_s" => 340.0,
              "status" => "planned",
              "timeline_id" => "timeline:leo_1:observe:obs_timeline",
              "observation_success_factor" => 0.45,
              "observation_result" => ["accepted", "clouded"],
              "image_quality_score" => 0.45,
              "image_quality_status" => "marginal",
              "image_quality_source" => "cadence.timeline_quality"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    command_branch = branch(artifact, "derived_operational_timeline_feedback_cmd_timeline")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_timeline",
             "command_success_factor" => 0.4,
             "command_result" => "accepted,failed",
             "dependency_activity_ids" => ["cmd_prepare"],
             "dependency_order_violation_activity_ids" => ["cmd_prepare"],
             "feedback_source" => "prior_plan.operational_timeline_report.rows",
             "feedback_scope" => "operational_timeline",
             "feedback_weight" => 2.0,
             "feedback_weight_source" => "cadence.timeline_sample_count",
             "trust_boundary" => "cadence_timeline_export"
           } = Enum.find(command_branch["events"], &(&1["type"] == "command_success_feedback"))

    assert Enum.any?(
             command_branch["events"],
             &(&1["type"] == "timeline_integrity_feedback" and
                 &1["activity_id"] == "cmd_timeline" and
                 &1["dependency_order_violation_activity_ids"] == ["cmd_prepare"] and
                 &1["feedback_source"] == "prior_plan.operational_timeline_report.rows")
           )

    assert Enum.any?(
             command_branch["risk_indicators"],
             &(&1["type"] == "timeline_integrity_issue" and
                 &1["dependency_order_violation_activity_ids"] == ["cmd_prepare"])
           )

    assert %{
             "branch_timeline_integrity_activity_ids" => ["cmd_timeline"],
             "branch_dependency_order_violation_activity_ids" => ["cmd_prepare"]
           } =
             Enum.find(
               artifact["branch_comparison_report"]["rows"],
               &(&1["branch_id"] == "derived_operational_timeline_feedback_cmd_timeline")
             )

    assert %{
             "branch_timeline_integrity_activity_ids" => ["cmd_timeline"],
             "branch_dependency_order_violation_activity_ids" => ["cmd_prepare"]
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "strategy_tradeoff" and
                   &1["branch_id"] == "derived_operational_timeline_feedback_cmd_timeline")
             )

    assert %{
             "branch_timeline_integrity_activity_ids" => ["cmd_timeline"],
             "branch_dependency_order_violation_activity_ids" => ["cmd_prepare"]
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source_review_type"] == "strategy_branch_comparison" and
                   &1["branch_id"] == "derived_operational_timeline_feedback_cmd_timeline")
             )

    contact_branch = branch(artifact, "derived_operational_timeline_feedback_dl_timeline")

    assert Enum.any?(
             contact_branch["events"],
             &(&1["type"] == "contact_success_feedback" and
                 &1["contact_success_factor"] == 0.5 and
                 &1["exclusive_with_activity_ids"] == ["dl_partner"] and
                 &1["exclusivity_violation_activity_ids"] == ["dl_partner"] and
                 &1["feedback_source"] == "prior_plan.operational_timeline_report.rows" and
                 &1["trust_boundary"] == "cadence_timeline_export")
           )

    assert Enum.any?(
             contact_branch["events"],
             &(&1["type"] == "timeline_integrity_feedback" and
                 &1["activity_id"] == "dl_timeline" and
                 &1["exclusivity_violation_group"] == "equator_prime_downlink")
           )

    assert Enum.any?(
             contact_branch["events"],
             &(&1["type"] == "station_throughput_feedback" and
                 &1["station_throughput_factor"] == 0.4 and
                 &1["actual_throughput_mb"] == 40.0 and
                 &1["estimated_throughput_mb"] == 100.0 and
                 &1["feedback_source"] == "prior_plan.operational_timeline_report.rows")
           )

    observation_branch = branch(artifact, "derived_operational_timeline_feedback_obs_timeline")

    assert %{
             "type" => "observation_success_feedback",
             "activity_id" => "obs_timeline",
             "target_id" => "target_a",
             "observation_success_factor" => 0.45,
             "image_quality_score" => 0.45,
             "image_quality_status" => "marginal",
             "image_quality_source" => "cadence.timeline_quality",
             "feedback_source" => "prior_plan.operational_timeline_report.rows",
             "trust_boundary" => "cadence_timeline_export"
           } = List.first(observation_branch["events"])

    assert get_in(artifact, ["operational_feedback", "command_success_rate", "cmd_timeline"]) ==
             0.4

    assert get_in(artifact, ["operational_feedback", "contact_success_rate", "equator_prime"]) ==
             0.5

    assert_in_delta get_in(artifact, [
                      "operational_feedback",
                      "station_throughput_factor",
                      "equator_prime"
                    ]),
                    0.4,
                    1.0e-12

    assert get_in(artifact, ["operational_feedback", "observation_success_rate", "target_a"]) ==
             0.45

    source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] == "prior_plan.operational_timeline_report.rows")
      )

    assert %{
             "source_report_contract" => "operational_timeline_report.v1",
             "source_report_row_count" => 3,
             "weighted_feedback_row_count" => 1,
             "feedback_weight_sources" => ["cadence.timeline_sample_count"],
             "trust_boundaries" => ["cadence_timeline_export"]
           } = source

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch-local refresh from mission-state operational timeline rows" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          command("cmd_live_timeline", "leo_1", 100.0, 130.0),
          downlink("dl_live_timeline", 200.0, 260.0)
        ]
      })

    operational_timeline_report = %{
      "schema_contract" => "operational_timeline_report.v1",
      "source" => "cadence.live_operational_timeline",
      "row_count" => 2,
      "provenance" => %{"trust_boundary" => "cadence_live_timeline_export"},
      "rows" => [
        %{
          "id" => "timeline_row:cmd_live_timeline",
          "activity_id" => "cmd_live_timeline",
          "activity_type" => "command",
          "scenario_id" => "leo_1",
          "starts_at_s" => 100.0,
          "ends_at_s" => 130.0,
          "timeline_id" => "timeline:leo_1:command:cmd_live_timeline",
          "ground_station_id" => "equator_prime",
          "direction" => "uplink",
          "operational_kind" => "command",
          "status" => "planned",
          "approval_status" => "review_required",
          "required_operator_action" => "review_command_feedback",
          "cadence_import_status" => "review",
          "command_success_factor" => 0.3,
          "command_result" => ["accepted", "failed"],
          "feedback_weight" => 3.0,
          "feedback_weight_source" => "cadence.live_sample_count"
        },
        %{
          "id" => "timeline_row:dl_live_timeline",
          "activity_id" => "dl_live_timeline",
          "activity_type" => "downlink",
          "scenario_id" => "leo_1",
          "starts_at_s" => 200.0,
          "ends_at_s" => 260.0,
          "timeline_id" => "timeline:leo_1:downlink:dl_live_timeline",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "operational_kind" => "contact",
          "status" => "partial",
          "approval_status" => "not_evaluated",
          "required_operator_action" => "review_downlink_feedback",
          "cadence_import_status" => "missing",
          "contact_success_factor" => 0.55,
          "actual_throughput_mb" => 25.0,
          "estimated_throughput_mb" => 100.0
        }
      ]
    }

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:operational_timeline_report, operational_timeline_report),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    command_branch = branch(artifact, "derived_operational_timeline_feedback_cmd_live_timeline")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_live_timeline",
             "command_success_factor" => 0.3,
             "command_result" => "accepted,failed",
             "feedback_source" => "mission_state.operational_timeline_report.rows",
             "feedback_scope" => "operational_timeline",
             "feedback_weight" => 3.0,
             "feedback_weight_source" => "cadence.live_sample_count",
             "trust_boundary" => "cadence_live_timeline_export"
           } = Enum.find(command_branch["events"], &(&1["type"] == "command_success_feedback"))

    contact_branch = branch(artifact, "derived_operational_timeline_feedback_dl_live_timeline")

    assert Enum.any?(
             contact_branch["events"],
             &(&1["type"] == "contact_success_feedback" and
                 &1["contact_success_factor"] == 0.55 and
                 &1["feedback_source"] == "mission_state.operational_timeline_report.rows" and
                 &1["trust_boundary"] == "cadence_live_timeline_export")
           )

    assert Enum.any?(
             contact_branch["events"],
             &(&1["type"] == "station_throughput_feedback" and
                 &1["station_throughput_factor"] == 0.25 and
                 &1["feedback_source"] == "mission_state.operational_timeline_report.rows")
           )

    assert get_in(artifact, ["operational_feedback", "command_success_rate", "cmd_live_timeline"]) ==
             0.3

    assert get_in(artifact, ["operational_feedback", "contact_success_rate", "equator_prime"]) ==
             0.55

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor", "equator_prime"]) ==
             0.25

    source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] == "mission_state.operational_timeline_report.rows")
      )

    assert %{
             "source_report_contract" => "operational_timeline_report.v1",
             "source_report_row_count" => 2,
             "weighted_feedback_row_count" => 1,
             "feedback_weight_sources" => ["cadence.live_sample_count"],
             "trust_boundaries" => ["cadence_live_timeline_export"]
           } = source

    assert "mission_state.operational_timeline_report.rows" in artifact[
             "operational_feedback_provenance"
           ]["merge_order"]

    assert get_in(command_branch, [
             "assumptions",
             "candidate_source",
             "source_operational_feedback_provenance",
             "derived_from_source_operational_timeline_report"
           ])

    assert get_in(command_branch, [
             "assumptions",
             "candidate_source",
             "source_operational_feedback_provenance",
             "source_operational_timeline_report_paths"
           ]) == ["operational_timeline_report"]

    assert get_in(command_branch, [
             "assumptions",
             "candidate_source",
             "source_operational_feedback_provenance",
             "source_operational_timeline_report_row_count"
           ]) == 2

    candidate_source = get_in(command_branch, ["assumptions", "candidate_source"])

    operational_timeline_replay_summary =
      CandidateRefresh.operational_timeline_replay_summary(candidate_source)

    assert %{
             "source" =>
               "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.operational_timeline_report",
             "contract" => "operational_timeline_report.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 2,
             "source_report_paths" => ["operational_timeline_report"],
             "contact_feedback_count" => 1,
             "command_feedback_count" => 1,
             "maneuver_feedback_count" => 0,
             "observation_feedback_count" => 0,
             "station_throughput_feedback_count" => 1,
             "operational_kind_counts" => %{"command" => 1, "contact" => 1},
             "activity_status_counts" => %{"partial" => 1, "planned" => 1},
             "approval_status_counts" => %{"not_evaluated" => 1, "review_required" => 1},
             "required_operator_action_counts" => %{
               "review_command_feedback" => 1,
               "review_downlink_feedback" => 1
             },
             "cadence_import_status_counts" => %{"missing" => 1, "review" => 1},
             "timeline_integrity_issue_count" => 0,
             "dependency_integrity_issue_count" => 0,
             "exclusivity_integrity_issue_count" => 0,
             "timeline_integrity_issue_type_counts" => %{},
             "station_reservation_evidence_row_count" => 0,
             "station_reservation_expiration_evidence_row_count" => 0,
             "input_keys" => operational_timeline_input_keys,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["cadence_live_timeline_export"],
             "branch_local_operational_timeline_pressure" => true,
             "branch_local_feedback_pressure" => true,
             "branch_local_integrity_pressure" => false,
             "branch_local_station_reservation_pressure" => false,
             "assumptions" => %{
               "replay_scope" => "operational_timeline_candidate_source_report_summary_only"
             }
           } = operational_timeline_replay_summary

    assert "command_success_rate" in operational_timeline_input_keys
    assert "contact_success_rate" in operational_timeline_input_keys
    assert "station_throughput_factor" in operational_timeline_input_keys

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch-local refresh from standalone planned activity rows" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          command("cmd_planned_row", "leo_1", 100.0, 130.0),
          downlink("dl_planned_row", 200.0, 260.0)
          |> Map.put("estimated_throughput_mb", 100.0)
        ],
        "planned_activity" => %{
          "schema_contract" => "planned_activity.v1",
          "id" => "cmd_planned_row",
          "type" => "command",
          "scenario_id" => "leo_1",
          "starts_at_s" => 100.0,
          "ends_at_s" => 130.0,
          "ground_station_id" => "equator_prime",
          "direction" => "command",
          "command_success_factor" => 0.35,
          "command_result" => ["accepted", "timed_out"],
          "feedback_weight" => 3.0,
          "feedback_weight_source" => "planned_activity_sample_count"
        },
        "planned_activities" => [
          %{
            "schema_contract" => "planned_activity.v1",
            "id" => "dl_planned_row",
            "type" => "downlink",
            "scenario_id" => "leo_1",
            "starts_at_s" => 200.0,
            "ends_at_s" => 260.0,
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "contact_success_factor" => 0.45,
            "contact_result" => ["accepted", "dropped"],
            "actual_throughput_mb" => 30.0,
            "estimated_throughput_mb" => 100.0,
            "required_downlink_mb" => 70.0
          }
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    command_branch = branch(artifact, "derived_operational_timeline_feedback_cmd_planned_row")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_planned_row",
             "command_success_factor" => 0.35,
             "command_result" => "accepted,timed_out",
             "feedback_source" => "prior_plan.planned_activity",
             "feedback_scope" => "operational_timeline",
             "feedback_weight" => 3.0,
             "feedback_weight_source" => "planned_activity_sample_count"
           } = List.first(command_branch["events"])

    contact_branch = branch(artifact, "derived_operational_timeline_feedback_dl_planned_row")

    assert Enum.any?(
             contact_branch["events"],
             &(&1["type"] == "contact_success_feedback" and
                 &1["contact_success_factor"] == 0.45 and
                 &1["feedback_source"] == "prior_plan.planned_activities")
           )

    assert Enum.any?(
             contact_branch["events"],
             &(&1["type"] == "station_throughput_feedback" and
                 &1["station_throughput_factor"] == 0.3 and
                 &1["actual_throughput_mb"] == 30.0 and
                 &1["estimated_throughput_mb"] == 100.0 and
                 &1["feedback_source"] == "prior_plan.planned_activities")
           )

    assert_in_delta get_in(artifact, [
                      "operational_feedback",
                      "command_success_rate",
                      "cmd_planned_row"
                    ]),
                    0.35,
                    1.0e-12

    assert get_in(artifact, ["operational_feedback", "contact_success_rate", "equator_prime"]) ==
             0.45

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor", "equator_prime"]) ==
             0.3

    source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] == "prior_plan.planned_activity")
      )

    assert %{
             "source_report_contract" => "planned_activity.v1",
             "source_report_count" => 2,
             "source_report_row_count" => 2,
             "source_report_paths" => [
               "prior_plan.planned_activity",
               "prior_plan.planned_activities"
             ],
             "weighted_feedback_row_count" => 1,
             "feedback_weight_sources" => ["planned_activity_sample_count"]
           } = source

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch-local refresh from standalone proposed contact rows" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("dl_proposed_row", 200.0, 260.0)
          |> Map.put("estimated_throughput_mb", 100.0),
          downlink("dl_proposed_list_row", 300.0, 360.0)
          |> Map.put("ground_station_id", "polar_prime")
          |> Map.put("estimated_throughput_mb", 120.0)
        ],
        "proposed_contact" => %{
          "schema_contract" => "proposed_contact.v1",
          "id" => "dl_proposed_row",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 200.0,
          "ends_at_s" => 260.0,
          "direction" => "downlink",
          "contact_success_factor" => 0.5,
          "contact_result" => ["accepted", "dropped"],
          "actual_throughput_mb" => 35.0,
          "estimated_throughput_mb" => 100.0,
          "required_downlink_mb" => 75.0,
          "feedback_weight" => 2.0,
          "feedback_weight_source" => "proposed_contact_sample_count",
          "cadence_import" => %{
            "activity_type" => "contact",
            "external_id" => "dl_proposed_row",
            "schema_contract" => "proposed_contact.v1"
          }
        },
        "proposed_contacts" => [
          %{
            "id" => "dl_proposed_list_row",
            "type" => "downlink",
            "scenario_id" => "leo_1",
            "ground_station_id" => "polar_prime",
            "starts_at_s" => 300.0,
            "ends_at_s" => 360.0,
            "direction" => "downlink",
            "contact_success_factor" => 0.4,
            "contact_result" => ["accepted", "partial"],
            "actual_throughput_mb" => 60.0,
            "estimated_throughput_mb" => 120.0,
            "required_downlink_mb" => 90.0,
            "cadence_import" => %{
              "activity_type" => "contact",
              "external_id" => "dl_proposed_list_row",
              "schema_contract" => "proposed_contact.v1"
            }
          }
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    contact_branch = branch(artifact, "derived_operational_timeline_feedback_dl_proposed_row")

    assert Enum.any?(
             contact_branch["events"],
             &(&1["type"] == "contact_success_feedback" and
                 &1["contact_success_factor"] == 0.5 and
                 &1["contact_result"] == "accepted,dropped" and
                 &1["feedback_source"] == "prior_plan.proposed_contact" and
                 &1["feedback_weight"] == 2.0 and
                 &1["feedback_weight_source"] == "proposed_contact_sample_count")
           )

    assert Enum.any?(
             contact_branch["events"],
             &(&1["type"] == "station_throughput_feedback" and
                 &1["station_throughput_factor"] == 0.35 and
                 &1["actual_throughput_mb"] == 35.0 and
                 &1["estimated_throughput_mb"] == 100.0 and
                 &1["feedback_source"] == "prior_plan.proposed_contact")
           )

    list_contact_branch =
      branch(artifact, "derived_operational_timeline_feedback_dl_proposed_list_row")

    assert Enum.any?(
             list_contact_branch["events"],
             &(&1["type"] == "contact_success_feedback" and
                 &1["ground_station_id"] == "polar_prime" and
                 &1["contact_success_factor"] == 0.4 and
                 &1["feedback_source"] == "prior_plan.proposed_contacts")
           )

    assert get_in(artifact, ["operational_feedback", "contact_success_rate", "equator_prime"]) ==
             0.5

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor", "equator_prime"]) ==
             0.35

    assert get_in(artifact, ["operational_feedback", "contact_success_rate", "polar_prime"]) ==
             0.4

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor", "polar_prime"]) ==
             0.5

    source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] == "prior_plan.proposed_contact")
      )

    assert %{
             "source_report_contract" => "proposed_contact.v1",
             "source_report_count" => 2,
             "source_report_row_count" => 2,
             "source_report_paths" => [
               "prior_plan.proposed_contact",
               "prior_plan.proposed_contacts"
             ],
             "weighted_feedback_row_count" => 1,
             "feedback_weight_sources" => ["proposed_contact_sample_count"]
           } = source

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch-local refresh from mission-state planned and proposed source rows" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          command("cmd_mission_planned_row", "leo_1", 100.0, 130.0),
          downlink("dl_mission_proposed_row", 200.0, 260.0)
          |> Map.put("estimated_throughput_mb", 100.0)
        ]
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_planned_activity, %{
        "schema_contract" => "planned_activity.v1",
        "id" => "cmd_mission_planned_row",
        "type" => "command",
        "scenario_id" => "leo_1",
        "starts_at_s" => 100.0,
        "ends_at_s" => 130.0,
        "ground_station_id" => "equator_prime",
        "direction" => "command",
        "command_success_factor" => 0.3,
        "command_result" => ["accepted", "timed_out"],
        "cadence_import_status" => "missing",
        "planned_protection_decision" => "preserve",
        "feedback_weight" => 2.0,
        "feedback_weight_source" => "mission_planned_samples"
      })
      |> Map.put(:source_proposed_contact, %{
        "schema_contract" => "proposed_contact.v1",
        "id" => "dl_mission_proposed_row",
        "type" => "downlink",
        "scenario_id" => "leo_1",
        "ground_station_id" => "equator_prime",
        "starts_at_s" => 200.0,
        "ends_at_s" => 260.0,
        "direction" => "downlink",
        "contact_success_factor" => 0.45,
        "contact_result" => ["accepted", "partial"],
        "actual_throughput_mb" => 40.0,
        "estimated_throughput_mb" => 100.0,
        "required_downlink_mb" => 80.0,
        "cadence_import_status" => "present",
        "planned_protection_decision" => "mutable",
        "feedback_weight" => 3.0,
        "feedback_weight_source" => "mission_proposed_samples"
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    command_branch =
      branch(artifact, "derived_operational_timeline_feedback_cmd_mission_planned_row")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_mission_planned_row",
             "command_success_factor" => 0.3,
             "command_result" => "accepted,timed_out",
             "feedback_source" => "mission_state.source_planned_activity",
             "feedback_scope" => "operational_timeline",
             "feedback_weight" => 2.0,
             "feedback_weight_source" => "mission_planned_samples"
           } = List.first(command_branch["events"])

    contact_branch =
      branch(artifact, "derived_operational_timeline_feedback_dl_mission_proposed_row")

    assert Enum.any?(
             contact_branch["events"],
             &(&1["type"] == "contact_success_feedback" and
                 &1["contact_success_factor"] == 0.45 and
                 &1["contact_result"] == "accepted,partial" and
                 &1["feedback_source"] == "mission_state.source_proposed_contact" and
                 &1["feedback_weight"] == 3.0 and
                 &1["feedback_weight_source"] == "mission_proposed_samples")
           )

    assert Enum.any?(
             contact_branch["events"],
             &(&1["type"] == "station_throughput_feedback" and
                 &1["station_throughput_factor"] == 0.4 and
                 &1["actual_throughput_mb"] == 40.0 and
                 &1["estimated_throughput_mb"] == 100.0 and
                 &1["feedback_source"] == "mission_state.source_proposed_contact")
           )

    assert_in_delta get_in(artifact, [
                      "operational_feedback",
                      "command_success_rate",
                      "cmd_mission_planned_row"
                    ]),
                    0.3,
                    1.0e-12

    assert get_in(artifact, ["operational_feedback", "contact_success_rate", "equator_prime"]) ==
             0.45

    assert_in_delta get_in(artifact, [
                      "operational_feedback",
                      "station_throughput_factor",
                      "equator_prime"
                    ]),
                    0.4,
                    1.0e-12

    planned_source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] == "mission_state.planned_activity")
      )

    assert %{
             "source_report_contract" => "planned_activity.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 1,
             "source_report_paths" => ["mission_state.source_planned_activity"],
             "source_activity_type_counts" => %{"command" => 1},
             "source_direction_counts" => %{"command" => 1},
             "source_cadence_import_status_counts" => %{"missing" => 1},
             "source_planned_protection_decision_counts" => %{"preserve" => 1},
             "weighted_feedback_row_count" => 1,
             "feedback_weight_sources" => ["mission_planned_samples"]
           } = planned_source

    proposed_source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] == "mission_state.proposed_contact")
      )

    assert %{
             "source_report_contract" => "proposed_contact.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 1,
             "source_report_paths" => ["mission_state.source_proposed_contact"],
             "source_activity_type_counts" => %{"downlink" => 1},
             "source_direction_counts" => %{"downlink" => 1},
             "source_cadence_import_status_counts" => %{"present" => 1},
             "source_planned_protection_decision_counts" => %{"mutable" => 1},
             "weighted_feedback_row_count" => 1,
             "feedback_weight_sources" => ["mission_proposed_samples"]
           } = proposed_source

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch-local refresh from standalone realized activity rows" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("dl_realized_row", 200.0, 260.0)
          |> Map.put("estimated_throughput_mb", 100.0),
          observe("obs_realized_row", "leo_1", "target_a", 300.0, 340.0, 8.0)
        ],
        "realized_activity" => %{
          "schema_contract" => "realized_activity.v1",
          "id" => "realized:dl_realized_row",
          "planned_activity_id" => "dl_realized_row",
          "type" => "downlink",
          "status" => "partial",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "actual_starts_at_s" => 205.0,
          "actual_ends_at_s" => 255.0,
          "direction" => "downlink",
          "completed_fraction" => 0.25,
          "actual_throughput_mb" => 25.0,
          "estimated_throughput_mb" => 100.0,
          "required_downlink_mb" => 75.0,
          "feedback_weight" => 3.0,
          "feedback_weight_source" => "provider_sample_count",
          "trust_boundary" => "cadence_execution_feedback"
        },
        "realized_activities" => [
          %{
            "schema_contract" => "realized_activity.v1",
            "id" => "realized:obs_realized_row",
            "planned_activity_id" => "obs_realized_row",
            "type" => "observe",
            "status" => "partial",
            "scenario_id" => "leo_1",
            "target_id" => "target_a",
            "actual_starts_at_s" => 305.0,
            "actual_ends_at_s" => 335.0,
            "completed_fraction" => 0.4,
            "image_quality_score" => 0.4,
            "image_quality_status" => "marginal",
            "image_quality_source" => "provider_imagery_quality",
            "trust_boundary" => "cadence_execution_feedback"
          }
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    contact_branch = branch(artifact, "derived_realized_feedback_dl_realized_row")

    assert Enum.any?(
             contact_branch["events"],
             &(&1["type"] == "contact_success_feedback" and
                 &1["activity_id"] == "dl_realized_row" and
                 &1["contact_success_factor"] == 0.25 and
                 &1["feedback_source"] == "prior_plan.realized_activity" and
                 &1["feedback_weight"] == 3.0 and
                 &1["feedback_weight_source"] == "provider_sample_count" and
                 &1["trust_boundary"] == "cadence_execution_feedback")
           )

    assert Enum.any?(
             contact_branch["events"],
             &(&1["type"] == "station_throughput_feedback" and
                 &1["station_throughput_factor"] == 0.25 and
                 &1["actual_throughput_mb"] == 25.0 and
                 &1["estimated_throughput_mb"] == 100.0 and
                 &1["feedback_source"] == "prior_plan.realized_activity")
           )

    observation_branch = branch(artifact, "derived_realized_feedback_obs_realized_row")

    assert %{
             "type" => "observation_success_feedback",
             "activity_id" => "obs_realized_row",
             "target_id" => "target_a",
             "observation_success_factor" => 0.4,
             "image_quality_score" => 0.4,
             "image_quality_status" => "marginal",
             "image_quality_source" => "provider_imagery_quality",
             "feedback_source" => "prior_plan.realized_activities",
             "trust_boundary" => "cadence_execution_feedback"
           } = List.first(observation_branch["events"])

    assert get_in(artifact, ["operational_feedback", "contact_success_rate", "equator_prime"]) ==
             0.25

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor", "equator_prime"]) ==
             0.25

    assert get_in(artifact, ["operational_feedback", "observation_success_rate", "target_a"]) ==
             0.4

    assert get_in(artifact, ["operational_feedback", "image_quality_score", "target_a"]) ==
             0.4

    source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] == "prior_plan.realized_activity")
      )

    assert %{
             "source_report_contract" => "realized_activity.v1",
             "source_report_count" => 2,
             "source_report_row_count" => 2,
             "source_report_paths" => [
               "prior_plan.realized_activity",
               "prior_plan.realized_activities"
             ],
             "weighted_feedback_row_count" => 1,
             "feedback_weight_sources" => ["provider_sample_count"],
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["cadence_execution_feedback"]
           } = source

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch-local refresh from mission-state realized activity source rows" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("dl_mission_realized_row", 200.0, 260.0)
          |> Map.put("estimated_throughput_mb", 100.0),
          observe("obs_mission_snapshot_row", "leo_1", "target_a", 300.0, 340.0, 8.0)
        ]
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_realized_activity, %{
        "schema_contract" => "realized_activity.v1",
        "id" => "realized:dl_mission_realized_row",
        "planned_activity_id" => "dl_mission_realized_row",
        "type" => "downlink",
        "status" => "partial",
        "scenario_id" => "leo_1",
        "ground_station_id" => "equator_prime",
        "actual_starts_at_s" => 205.0,
        "actual_ends_at_s" => 255.0,
        "direction" => "downlink",
        "completed_fraction" => 0.2,
        "actual_throughput_mb" => 20.0,
        "estimated_throughput_mb" => 100.0,
        "required_downlink_mb" => 80.0,
        "cadence_import_status" => "present",
        "trust_boundary" => "live_execution_feedback"
      })
      |> Map.put(:source_realized_state_snapshot, %{
        "schema_contract" => "realized_state_snapshot.v1",
        "snapshot_id" => "realized_snapshot:mission_source",
        "provenance" => %{"trust_boundary" => "live_execution_snapshot"},
        "activities" => [
          %{
            "schema_contract" => "realized_activity.v1",
            "id" => "realized:obs_mission_snapshot_row",
            "planned_activity_id" => "obs_mission_snapshot_row",
            "type" => "observe",
            "status" => "partial",
            "scenario_id" => "leo_1",
            "target_id" => "target_a",
            "actual_starts_at_s" => 305.0,
            "actual_ends_at_s" => 335.0,
            "completed_fraction" => 0.45,
            "image_quality_score" => 0.45,
            "image_quality_status" => "marginal",
            "image_quality_source" => "provider_imagery_quality",
            "cadence_import_status" => "present"
          }
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    contact_branch = branch(artifact, "derived_realized_feedback_dl_mission_realized_row")

    assert Enum.any?(
             contact_branch["events"],
             &(&1["type"] == "contact_success_feedback" and
                 &1["activity_id"] == "dl_mission_realized_row" and
                 &1["contact_success_factor"] == 0.2 and
                 &1["feedback_source"] == "mission_state.source_realized_activity" and
                 &1["trust_boundary"] == "live_execution_feedback")
           )

    assert Enum.any?(
             contact_branch["events"],
             &(&1["type"] == "station_throughput_feedback" and
                 &1["station_throughput_factor"] == 0.2 and
                 &1["actual_throughput_mb"] == 20.0 and
                 &1["estimated_throughput_mb"] == 100.0 and
                 &1["feedback_source"] == "mission_state.source_realized_activity")
           )

    observation_branch = branch(artifact, "derived_realized_feedback_obs_mission_snapshot_row")

    assert %{
             "type" => "observation_success_feedback",
             "activity_id" => "obs_mission_snapshot_row",
             "target_id" => "target_a",
             "observation_success_factor" => 0.45,
             "image_quality_score" => 0.45,
             "image_quality_status" => "marginal",
             "image_quality_source" => "provider_imagery_quality",
             "feedback_source" => "mission_state.source_realized_state_snapshot.activities",
             "trust_boundary" => "live_execution_snapshot"
           } = List.first(observation_branch["events"])

    assert get_in(artifact, ["operational_feedback", "contact_success_rate", "equator_prime"]) ==
             0.2

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor", "equator_prime"]) ==
             0.2

    assert get_in(artifact, ["operational_feedback", "observation_success_rate", "target_a"]) ==
             0.45

    source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] == "mission_state.realized_activity")
      )

    assert %{
             "source_report_contract" => "realized_activity.v1",
             "source_report_count" => 2,
             "source_report_row_count" => 2,
             "source_report_paths" => [
               "mission_state.source_realized_activity",
               "mission_state.source_realized_state_snapshot.activities"
             ],
             "source_activity_type_counts" => %{"downlink" => 1, "observe" => 1},
             "source_direction_counts" => %{"downlink" => 1},
             "source_cadence_import_status_counts" => %{"present" => 2},
             "source_realized_status_counts" => %{"partial" => 2},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["live_execution_feedback", "live_execution_snapshot"]
           } = source

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch-local refresh from realized state snapshot activities" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("dl_snapshot_row", 200.0, 260.0)
          |> Map.put("estimated_throughput_mb", 100.0),
          observe("obs_snapshot_row", "leo_1", "target_a", 300.0, 340.0, 8.0)
        ],
        "realized_state_snapshot" => %{
          "schema_contract" => "realized_state_snapshot.v1",
          "snapshot_id" => "cadence-snapshot-1",
          "trust_boundary" => "cadence_execution_snapshot",
          "activities" => [
            %{
              "schema_contract" => "realized_activity.v1",
              "id" => "realized:dl_snapshot_row",
              "planned_activity_id" => "dl_snapshot_row",
              "type" => "downlink",
              "status" => "partial",
              "scenario_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "actual_starts_at_s" => 205.0,
              "actual_ends_at_s" => 255.0,
              "direction" => "downlink",
              "completed_fraction" => 0.3,
              "actual_throughput_mb" => 30.0,
              "estimated_throughput_mb" => 100.0,
              "required_downlink_mb" => 80.0
            },
            %{
              "schema_contract" => "realized_activity.v1",
              "id" => "realized:obs_snapshot_row",
              "planned_activity_id" => "obs_snapshot_row",
              "type" => "observe",
              "status" => "partial",
              "scenario_id" => "leo_1",
              "target_id" => "target_a",
              "actual_starts_at_s" => 305.0,
              "actual_ends_at_s" => 335.0,
              "completed_fraction" => 0.6,
              "image_quality_score" => 0.6,
              "image_quality_status" => "usable",
              "image_quality_source" => "snapshot_quality"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    contact_branch = branch(artifact, "derived_realized_feedback_dl_snapshot_row")

    assert Enum.any?(
             contact_branch["events"],
             &(&1["type"] == "contact_success_feedback" and
                 &1["activity_id"] == "dl_snapshot_row" and
                 &1["contact_success_factor"] == 0.3 and
                 &1["feedback_source"] == "prior_plan.realized_state_snapshot.activities" and
                 &1["trust_boundary"] == "cadence_execution_snapshot")
           )

    assert Enum.any?(
             contact_branch["events"],
             &(&1["type"] == "station_throughput_feedback" and
                 &1["station_throughput_factor"] == 0.3 and
                 &1["feedback_source"] == "prior_plan.realized_state_snapshot.activities")
           )

    observation_branch = branch(artifact, "derived_realized_feedback_obs_snapshot_row")

    assert %{
             "type" => "observation_success_feedback",
             "activity_id" => "obs_snapshot_row",
             "target_id" => "target_a",
             "observation_success_factor" => 0.6,
             "image_quality_score" => 0.6,
             "image_quality_status" => "usable",
             "image_quality_source" => "snapshot_quality",
             "feedback_source" => "prior_plan.realized_state_snapshot.activities",
             "trust_boundary" => "cadence_execution_snapshot"
           } = List.first(observation_branch["events"])

    assert get_in(artifact, ["operational_feedback", "contact_success_rate", "equator_prime"]) ==
             0.3

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor", "equator_prime"]) ==
             0.3

    assert get_in(artifact, ["operational_feedback", "observation_success_rate", "target_a"]) ==
             0.6

    source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] == "prior_plan.realized_activity")
      )

    assert %{
             "source_report_contract" => "realized_activity.v1",
             "source_report_count" => 2,
             "source_report_row_count" => 2,
             "source_report_paths" => ["prior_plan.realized_state_snapshot.activities"],
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["cadence_execution_snapshot"]
           } = source

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp command(id, scenario_id, starts_at_s, ends_at_s) do
    %{
      "id" => id,
      "type" => "command",
      "scenario_id" => scenario_id,
      "direction" => "uplink",
      "ground_station_id" => "equator_prime",
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "duration_s" => ends_at_s - starts_at_s,
      "score" => 1.0
    }
  end
end
