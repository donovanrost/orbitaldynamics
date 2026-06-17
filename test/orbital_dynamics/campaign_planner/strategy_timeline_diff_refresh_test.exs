Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyTimelineDiffRefreshTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives refresh from prior removed timeline diff rows" do
    prior_plan =
      base_plan(%{
        "activities" => [
          health_check("cmd_removed", "leo_1", 780.0, 840.0),
          maneuver("burn_removed", 900.0)
        ],
        "candidate_activities" => [
          observe("obs_target_a_recovery", "leo_1", "target_a", 360.0, 420.0, 12.0),
          refreshed_downlink("dl_removed_recovery", 360.0, 420.0)
          |> Map.put("estimated_throughput_mb", 40.0)
        ],
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 6,
          "removed_count" => 6,
          "provenance" => %{"trust_boundary" => "ops_timeline_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:obs_removed",
              "rank" => 1,
              "timeline_id" => "timeline:obs_removed",
              "diff_status" => "Removed",
              "source_activity_id" => "obs_removed",
              "source_activity_type" => "Observe",
              "source_target_id" => "target_a",
              "scenario_id" => "leo_1",
              "source_status" => "Planned",
              "required_operator_action" => "review_removed_activity"
            },
            %{
              "id" => "timeline_diff:timeline:dl_removed",
              "rank" => 2,
              "timeline_id" => "timeline:dl_removed",
              "diff_status" => "Removed",
              "source_activity_id" => "dl_removed",
              "source_activity_type" => "Downlink",
              "source_ground_station_id" => "equator_prime",
              "scenario_id" => "leo_1",
              "source_status" => "Planned",
              "source_activity_context" => %{"estimated_throughput_mb" => 40.0},
              "required_operator_action" => "review_removed_activity"
            },
            %{
              "id" => "timeline_diff:timeline:dl_removed_scoped",
              "rank" => 3,
              "timeline_id" => "timeline:dl_removed_scoped",
              "diff_status" => "Removed",
              "source_activity_id" => "dl_removed_scoped",
              "source_activity_type" => "Downlink",
              "source_ground_station_id" => "equator_prime",
              "scenario_id" => "leo_1",
              "source_status" => "Planned",
              "source_activity_context" => %{
                "starts_at_s" => 480.0,
                "ends_at_s" => 540.0,
                "estimated_throughput_mb" => 40.0,
                "required_contacts" => 2,
                "planned_contacts" => 1
              },
              "required_operator_action" => "review_removed_activity"
            },
            %{
              "id" => "timeline_diff:timeline:tracking_removed",
              "rank" => 4,
              "timeline_id" => "timeline:tracking_removed",
              "diff_status" => "Removed",
              "source_activity_id" => "tracking_removed",
              "source_activity_type" => "Planned Contact",
              "source_direction" => "Tracking",
              "source_ground_station_id" => "equator_prime",
              "scenario_id" => "leo_1",
              "source_status" => "Planned",
              "source_activity_context" => %{
                "starts_at_s" => 660.0,
                "ends_at_s" => 720.0,
                "contact_result" => "no-contact"
              },
              "required_operator_action" => "review_removed_activity"
            },
            %{
              "id" => "timeline_diff:timeline:cmd_removed",
              "rank" => 5,
              "timeline_id" => "timeline:cmd_removed",
              "diff_status" => "Removed",
              "source_activity_id" => "cmd_removed",
              "source_activity_type" => "Planned Contact",
              "source_direction" => "Health-Check",
              "scenario_id" => "leo_1",
              "source_status" => "Planned",
              "source_activity_context" => %{
                "starts_at_s" => 780.0,
                "ends_at_s" => 840.0,
                "command_result" => "failed"
              },
              "required_operator_action" => "review_removed_activity"
            },
            %{
              "id" => "timeline_diff:timeline:burn_removed",
              "rank" => 6,
              "timeline_id" => "timeline:burn_removed",
              "diff_status" => "Removed",
              "source_activity_id" => "burn_removed",
              "source_activity_type" => "Impulsive Burn",
              "source_operational_kind" => "Maneuver",
              "scenario_id" => "leo_1",
              "source_status" => "Planned",
              "source_activity_context" => %{
                "starts_at_s" => 900.0,
                "ends_at_s" => 900.0,
                "maneuver_result" => "not-executed"
              },
              "required_operator_action" => "review_removed_activity"
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

    observation_branch = branch(artifact, "derived_timeline_diff_removed_obs_removed")

    assert %{
             "type" => "urgent_target",
             "objective_type" => "target_revisit",
             "target_id" => "target_a",
             "source_activity_id" => "obs_removed",
             "source_activity_ids" => ["obs_removed"],
             "timeline_id" => "timeline:obs_removed",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_timeline_review"
           } = List.first(observation_branch["events"])

    assert observation_addition =
             Enum.find(
               observation_branch["candidate_plan"]["strategic_additions"],
               &(&1["target_id"] == "target_a" and
                   get_in(&1, ["repair", "reason"]) == "target_revisit_candidate_inserted")
             )

    assert %{
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_timeline_review",
             "source_event_type" => "urgent_target",
             "source_activity_id" => "obs_removed",
             "source_activity_ids" => ["obs_removed"],
             "source_timeline_id" => "timeline:obs_removed",
             "derivation_reasons" => [
               "timeline_diff_removed_activity",
               "timeline_diff_removed_observation"
             ]
           } = observation_addition["feasibility"]

    assert Enum.any?(
             observation_branch["approval_requirements"],
             &(get_in(&1, ["activity_context", "feedback_source"]) ==
                 "prior_plan.source_timeline_diff_report" and
                 get_in(&1, ["activity_context", "trust_boundary"]) == "ops_timeline_review" and
                 get_in(&1, ["activity_context", "source_activity_id"]) == "obs_removed")
           )

    downlink_branch = branch(artifact, "derived_timeline_diff_removed_dl_removed")

    assert %{
             "type" => "downlink_completion_gap",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 40.0,
             "source_activity_id" => "dl_removed",
             "source_activity_ids" => ["dl_removed"],
             "timeline_id" => "timeline:dl_removed",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_timeline_review"
           } = List.first(downlink_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             downlink_branch["assumptions"]["candidate_source"]

    assert [
             %{
               "type" => "downlink",
               "feasibility" => %{
                 "feedback_source" => "prior_plan.source_timeline_diff_report",
                 "feedback_scope" => "timeline_diff",
                 "trust_boundary" => "ops_timeline_review",
                 "source_event_type" => "downlink_completion_gap",
                 "source_activity_id" => "dl_removed",
                 "source_activity_ids" => ["dl_removed"],
                 "source_timeline_id" => "timeline:dl_removed",
                 "derivation_reasons" => [
                   "timeline_diff_removed_activity",
                   "timeline_diff_removed_downlink"
                 ]
               }
             }
           ] = downlink_branch["candidate_plan"]["strategic_additions"]

    scoped_downlink_branch = branch(artifact, "derived_timeline_diff_removed_dl_removed_scoped")

    assert %{
             "type" => "downlink_completion_gap",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 480.0,
             "ends_at_s" => 540.0,
             "required_contacts" => 2,
             "planned_contacts" => 1,
             "required_downlink_mb" => 40.0,
             "source_activity_id" => "dl_removed_scoped",
             "source_activity_ids" => ["dl_removed_scoped"],
             "timeline_id" => "timeline:dl_removed_scoped",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_timeline_review"
           } = List.first(scoped_downlink_branch["events"])

    tracking_branch = branch(artifact, "derived_timeline_diff_removed_tracking_removed")

    assert %{
             "type" => "contact_success_feedback",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 660.0,
             "ends_at_s" => 720.0,
             "contact_result" => "no-contact",
             "realized_status" => "missed",
             "source_activity_id" => "tracking_removed",
             "source_activity_ids" => ["tracking_removed"],
             "timeline_id" => "timeline:tracking_removed",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "equator_prime",
             "trust_boundary" => "ops_timeline_review",
             "derivation_reasons" => [
               "timeline_diff_removed_activity",
               "timeline_diff_removed_contact"
             ]
           } = List.first(tracking_branch["events"])

    assert List.first(tracking_branch["events"])["contact_success_factor"] == 0.0
    assert tracking_branch["feedback_adjustments"]["contact_success_factor"] == 0.0

    command_branch = branch(artifact, "derived_timeline_diff_removed_cmd_removed")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_removed",
             "scenario_id" => "leo_1",
             "starts_at_s" => 780.0,
             "ends_at_s" => 840.0,
             "command_result" => "failed",
             "realized_status" => "missed",
             "source_activity_id" => "cmd_removed",
             "source_activity_ids" => ["cmd_removed"],
             "timeline_id" => "timeline:cmd_removed",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "cmd_removed",
             "trust_boundary" => "ops_timeline_review",
             "derivation_reasons" => [
               "timeline_diff_removed_activity",
               "timeline_diff_removed_command"
             ]
           } = List.first(command_branch["events"])

    assert List.first(command_branch["events"])["command_success_factor"] == 0.0
    assert command_branch["feedback_adjustments"]["command_success_factor"] == 0.0

    maneuver_branch = branch(artifact, "derived_timeline_diff_removed_burn_removed")

    assert %{
             "type" => "maneuver_success_feedback",
             "activity_id" => "burn_removed",
             "scenario_id" => "leo_1",
             "starts_at_s" => 900.0,
             "ends_at_s" => 900.0,
             "maneuver_result" => "not-executed",
             "realized_status" => "missed",
             "source_activity_id" => "burn_removed",
             "source_activity_ids" => ["burn_removed"],
             "timeline_id" => "timeline:burn_removed",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "burn_removed",
             "trust_boundary" => "ops_timeline_review",
             "derivation_reasons" => [
               "timeline_diff_removed_activity",
               "timeline_diff_removed_maneuver"
             ]
           } = List.first(maneuver_branch["events"])

    assert List.first(maneuver_branch["events"])["maneuver_success_factor"] == 0.0
    assert maneuver_branch["feedback_adjustments"]["maneuver_success_factor"] == 0.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives refresh from mission-state removed timeline diff rows" do
    timeline_diff_report = %{
      "schema_contract" => "timeline_diff_report.v1",
      "model" => "timeline_identity_activity_diff",
      "source" => "cadence.live_timeline_diff",
      "row_count" => 2,
      "removed_count" => 2,
      "provenance" => %{"trust_boundary" => "live_timeline_diff_review"},
      "rows" => [
        %{
          "id" => "timeline_diff:timeline:obs_live_removed",
          "rank" => 1,
          "timeline_id" => "timeline:obs_live_removed",
          "diff_status" => "removed",
          "source_activity_id" => "obs_live_removed",
          "source_activity_type" => "observe",
          "source_target_id" => "target_a",
          "scenario_id" => "leo_1",
          "source_status" => "planned",
          "required_operator_action" => "review_removed_activity"
        },
        %{
          "id" => "timeline_diff:timeline:dl_live_removed",
          "rank" => 2,
          "timeline_id" => "timeline:dl_live_removed",
          "diff_status" => "removed",
          "source_activity_id" => "dl_live_removed",
          "source_activity_type" => "downlink",
          "source_ground_station_id" => "equator_prime",
          "scenario_id" => "leo_1",
          "source_status" => "planned",
          "source_activity_context" => %{"estimated_throughput_mb" => 44.0},
          "required_operator_action" => "review_removed_activity"
        }
      ]
    }

    artifact =
      strategy(
        base_plan(%{
          "candidate_activities" => [
            observe("obs_live_removed_recovery", "leo_1", "target_a", 360.0, 420.0, 12.0),
            refreshed_downlink("dl_live_removed_recovery", 360.0, 420.0)
            |> Map.put("estimated_throughput_mb", 44.0)
          ]
        }),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_timeline_diff_report, timeline_diff_report),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    observation_branch = branch(artifact, "derived_timeline_diff_removed_obs_live_removed")

    assert %{
             "type" => "urgent_target",
             "objective_type" => "target_revisit",
             "target_id" => "target_a",
             "source_activity_id" => "obs_live_removed",
             "source_activity_ids" => ["obs_live_removed"],
             "timeline_id" => "timeline:obs_live_removed",
             "feedback_source" => "mission_state.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "live_timeline_diff_review"
           } = List.first(observation_branch["events"])

    downlink_branch = branch(artifact, "derived_timeline_diff_removed_dl_live_removed")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 44.0,
             "source_activity_id" => "dl_live_removed",
             "source_activity_ids" => ["dl_live_removed"],
             "timeline_id" => "timeline:dl_live_removed",
             "feedback_source" => "mission_state.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "live_timeline_diff_review"
           } = List.first(downlink_branch["events"])

    assert get_in(downlink_branch, [
             "assumptions",
             "candidate_source",
             "source_report_input_paths"
           ]) == ["mission_state.source_timeline_diff_report"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives mission-state timeline refresh from result artifact wrappers" do
    source_result_artifact = %{
      "schema_contract" => "result_artifact.v1",
      "study_id" => "live_timeline_result_artifact",
      "metadata" => %{"trust_boundary" => "live_result_artifact_review"},
      "timeline_diff_report" => %{
        "schema_contract" => "timeline_diff_report.v1",
        "model" => "timeline_identity_activity_diff",
        "source" => "cadence.live_timeline_diff",
        "row_count" => 1,
        "removed_count" => 1,
        "rows" => [
          %{
            "id" => "timeline_diff:timeline:obs_live_result_removed",
            "rank" => 1,
            "timeline_id" => "timeline:obs_live_result_removed",
            "diff_status" => "removed",
            "source_activity_id" => "obs_live_result_removed",
            "source_activity_type" => "observe",
            "source_target_id" => "target_a",
            "scenario_id" => "leo_1",
            "source_status" => "planned",
            "required_operator_action" => "review_removed_activity"
          }
        ]
      },
      "timeline_transition_application_report" => %{
        "schema_contract" => "timeline_transition_application_report.v1",
        "model" => "timeline_transition_application_fixture",
        "applications" => [
          %{
            "id" => "timeline_application:timeline:obs_live_application_result",
            "rank" => 1,
            "timeline_id" => "timeline:obs_live_application_result",
            "diff_status" => "removed",
            "source_activity_id" => "obs_live_application_result",
            "source_activity_type" => "observe",
            "source_target_id" => "target_b",
            "scenario_id" => "leo_1",
            "source_status" => "planned",
            "application_status" => "source_preserved_pending_review",
            "selected_activity_source" => "source",
            "source_timeline_diff" => %{
              "id" => "timeline_diff:timeline:obs_live_application_result",
              "rank" => 1,
              "timeline_id" => "timeline:obs_live_application_result",
              "diff_status" => "removed",
              "source_activity_id" => "obs_live_application_result",
              "source_activity_type" => "observe",
              "source_target_id" => "target_b",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "required_operator_action" => "review_removed_activity"
            },
            "required_operator_action" => "review_removed_activity"
          }
        ]
      }
    }

    artifact =
      strategy(
        base_plan(%{
          "candidate_activities" => [
            observe("obs_live_result_recovery", "leo_1", "target_a", 360.0, 420.0, 12.0),
            observe("obs_live_application_recovery", "leo_1", "target_b", 480.0, 540.0, 10.0)
          ]
        }),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_result_artifact, source_result_artifact),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    diff_branch = branch(artifact, "derived_timeline_diff_removed_obs_live_result_removed")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_a",
             "source_activity_id" => "obs_live_result_removed",
             "timeline_id" => "timeline:obs_live_result_removed",
             "feedback_source" => "mission_state.source_result_artifact.timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "live_result_artifact_review"
           } = List.first(diff_branch["events"])

    application_branch =
      branch(artifact, "derived_timeline_diff_removed_obs_live_application_result")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_b",
             "source_activity_id" => "obs_live_application_result",
             "timeline_id" => "timeline:obs_live_application_result",
             "feedback_source" =>
               "mission_state.source_result_artifact.timeline_transition_application_report.applications",
             "feedback_scope" => "timeline_diff",
             "application_status" => "source_preserved_pending_review",
             "selected_activity_source" => "source",
             "trust_boundary" => "live_result_artifact_review"
           } = List.first(application_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives refresh from timeline transition application reports" do
    transition_application = %{
      "id" => "timeline_application:timeline:obs_application",
      "rank" => 1,
      "timeline_id" => "timeline:obs_application",
      "diff_status" => "removed",
      "source_activity_id" => "obs_application",
      "source_activity_type" => "observe",
      "source_target_id" => "target_a",
      "scenario_id" => "leo_1",
      "source_status" => "planned",
      "changed_fields" => ["status"],
      "transition_decision" => "review",
      "requires_operator_review" => true,
      "required_operator_action" => "review_removed_activity",
      "reason" => "removed observation requires review",
      "application_status" => "source_preserved_pending_review",
      "selected_activity_source" => "source",
      "selected_activity" => %{"activity_id" => "obs_application"},
      "timeline_identity_collision" => true,
      "duplicate_timeline_identity_scope" => "source",
      "source_duplicate_activity_count" => 2,
      "replacement_duplicate_activity_count" => 1,
      "source_duplicate_activity_ids" => ["obs_application", "obs_application_shadow"],
      "replacement_duplicate_activity_ids" => ["obs_application_replacement"],
      "source_duplicate_activities" => [
        %{"activity_id" => "obs_application"},
        %{"activity_id" => "obs_application_shadow"}
      ],
      "replacement_duplicate_activities" => [
        %{"activity_id" => "obs_application_replacement"}
      ],
      "source_timeline_diff" => %{
        "id" => "timeline_diff:timeline:obs_application",
        "rank" => 1,
        "timeline_id" => "timeline:obs_application",
        "diff_status" => "removed",
        "source_activity_id" => "obs_application",
        "source_activity_type" => "observe",
        "source_target_id" => "target_a",
        "scenario_id" => "leo_1",
        "source_status" => "planned",
        "changed_fields" => ["status"],
        "requires_operator_review" => true,
        "required_operator_action" => "review_removed_activity",
        "reason" => "removed observation requires review"
      }
    }

    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_application_recovery", "leo_1", "target_a", 360.0, 420.0, 12.0),
          observe("obs_review_application_recovery", "leo_1", "target_b", 420.0, 480.0, 10.0),
          observe(
            "obs_flat_review_application_recovery",
            "leo_1",
            "target_b",
            450.0,
            510.0,
            10.0
          ),
          observe("obs_import_application_recovery", "leo_1", "target_a", 480.0, 540.0, 10.0),
          observe("obs_flat_import_application_recovery", "leo_1", "target_a", 540.0, 600.0, 10.0)
        ],
        "source_timeline_transition_application_report" => %{
          "schema_contract" => "timeline_transition_application_report.v1",
          "model" => "artifact_only_timeline_transition_application",
          "source" => "repair.activities",
          "source_activity_count" => 1,
          "replacement_activity_count" => 0,
          "application_count" => 1,
          "selected_activity_count" => 1,
          "review_required_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_transition_application_review"},
          "applications" => [transition_application],
          "assumptions" => %{"execution_boundary" => "artifact_only_no_schedule_mutation"}
        },
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "timeline_transition_application_report.v1",
          "review_count" => 2,
          "provenance" => %{"trust_boundary" => "ops_transition_review_queue"},
          "rows" => [
            %{
              "id" => "operator_review:timeline_application:obs_review_application",
              "review_type" => "timeline_diff_review",
              "source" => "timeline_transition_application_report.applications",
              "subject_id" => "timeline:obs_review_application",
              "timeline_id" => "timeline:obs_review_application",
              "approval_status" => "operator_review_required",
              "policy_classification" => "operator_review_required",
              "approval_rule_matches" => [
                %{
                  "rule_id" => "transition_preserve_review",
                  "classification" => "operator_review_required",
                  "application_status" => "source_preserved_pending_review"
                }
              ],
              "source_policy_decision" => %{
                "schema_contract" => "policy_decision.v1",
                "classification" => "operator_review_required",
                "policy_bundle_id" => "timeline_transition_policy"
              },
              "source_timeline_application" =>
                transition_application
                |> put_in(["timeline_id"], "timeline:obs_review_application")
                |> put_in(["source_activity_id"], "obs_review_application")
                |> put_in(["source_target_id"], "target_b")
                |> put_in(["selected_activity", "activity_id"], "obs_review_application")
                |> put_in(
                  ["source_timeline_diff", "timeline_id"],
                  "timeline:obs_review_application"
                )
                |> put_in(
                  ["source_timeline_diff", "source_activity_id"],
                  "obs_review_application"
                )
                |> put_in(["source_timeline_diff", "source_target_id"], "target_b")
            },
            %{
              "id" => "operator_review:timeline_diff:obs_flat_review_application",
              "review_type" => "timeline_diff_review",
              "source" => "timeline_diff_report.rows",
              "subject_id" => "timeline:obs_flat_review_application",
              "timeline_id" => "timeline:obs_flat_review_application",
              "diff_status" => "removed",
              "source_activity_id" => "obs_flat_review_application",
              "source_activity_type" => "observe",
              "source_target_id" => "target_b",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "changed_fields" => ["status"],
              "required_operator_action" => "review_removed_activity",
              "approval_status" => "operator_review_required"
            }
          ]
        },
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "timeline_transition_application_report.v1",
          "manifest_id" => "cadence_import_manifest:timeline_transition_application_report",
          "row_count" => 2,
          "ready_count" => 0,
          "review_required_count" => 2,
          "blocked_count" => 0,
          "missing_import_count" => 0,
          "provenance" => %{"trust_boundary" => "cadence_transition_import_queue"},
          "rows" => [
            %{
              "id" => "cadence_import:timeline_application:obs_import_application",
              "rank" => 1,
              "import_action" => "review_timeline_diff",
              "import_status" => "review_required_before_import",
              "cadence_import_status" => "present",
              "source_review_type" => "timeline_diff_review",
              "source_review_row" => %{
                "id" => "operator_review:timeline_application:obs_import_application",
                "review_type" => "timeline_diff_review",
                "source" => "timeline_transition_application_report.applications",
                "subject_id" => "timeline:obs_import_application",
                "approval_status" => "operator_review_required",
                "policy_classification" => "operator_review_required",
                "approval_rule_matches" => [
                  %{
                    "rule_id" => "transition_import_review",
                    "classification" => "operator_review_required",
                    "application_status" => "source_preserved_pending_review"
                  }
                ],
                "source_policy_decision" => %{
                  "schema_contract" => "policy_decision.v1",
                  "classification" => "operator_review_required",
                  "policy_bundle_id" => "timeline_transition_import_policy"
                },
                "source_timeline_application" =>
                  transition_application
                  |> put_in(["timeline_id"], "timeline:obs_import_application")
                  |> put_in(["source_activity_id"], "obs_import_application")
                  |> put_in(["selected_activity", "activity_id"], "obs_import_application")
                  |> put_in(
                    ["source_timeline_diff", "timeline_id"],
                    "timeline:obs_import_application"
                  )
                  |> put_in(
                    ["source_timeline_diff", "source_activity_id"],
                    "obs_import_application"
                  )
              }
            },
            %{
              "id" => "cadence_import:timeline_diff:obs_flat_import_application",
              "rank" => 2,
              "import_action" => "review_timeline_diff",
              "import_status" => "review_required_before_import",
              "cadence_import_status" => "present",
              "source_review_type" => "timeline_diff_review",
              "source_review_row_id" =>
                "operator_review:timeline_diff:obs_flat_import_application",
              "source_review_action" => "review_removed_activity",
              "timeline_id" => "timeline:obs_flat_import_application",
              "diff_status" => "removed",
              "source_activity_id" => "obs_flat_import_application",
              "source_activity_type" => "observe",
              "source_target_id" => "target_a",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "changed_fields" => ["status"],
              "required_operator_action" => "review_removed_activity",
              "approval_status" => "operator_review_required"
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

    application_branch = branch(artifact, "derived_timeline_diff_removed_obs_application")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_a",
             "source_activity_id" => "obs_application",
             "application_status" => "source_preserved_pending_review",
             "selected_activity_source" => "source",
             "selected_activity" => %{"activity_id" => "obs_application"},
             "feedback_source" =>
               "prior_plan.source_timeline_transition_application_report.applications",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_transition_application_review",
             "timeline_identity_collision" => true,
             "duplicate_timeline_identity_scope" => "source",
             "source_duplicate_activity_count" => 2,
             "replacement_duplicate_activity_count" => 1,
             "source_duplicate_activity_ids" => ["obs_application", "obs_application_shadow"],
             "replacement_duplicate_activity_ids" => ["obs_application_replacement"],
             "source_timeline_application" => %{
               "application_status" => "source_preserved_pending_review",
               "timeline_identity_collision" => true,
               "source_duplicate_activity_ids" => ["obs_application", "obs_application_shadow"]
             }
           } = List.first(application_branch["events"])

    review_branch = branch(artifact, "derived_timeline_diff_removed_obs_review_application")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_b",
             "source_activity_id" => "obs_review_application",
             "application_status" => "source_preserved_pending_review",
             "policy_classification" => "operator_review_required",
             "approval_rule_matches" => [
               %{
                 "rule_id" => "transition_preserve_review",
                 "classification" => "operator_review_required",
                 "application_status" => "source_preserved_pending_review"
               }
             ],
             "source_policy_decision" => %{
               "schema_contract" => "policy_decision.v1",
               "classification" => "operator_review_required",
               "policy_bundle_id" => "timeline_transition_policy"
             },
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.source_timeline_application",
             "trust_boundary" => "ops_transition_review_queue"
           } = List.first(review_branch["events"])

    flat_review_branch =
      branch(artifact, "derived_timeline_diff_removed_obs_flat_review_application")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_b",
             "source_activity_id" => "obs_flat_review_application",
             "feedback_source" => "prior_plan.operator_review_package.rows.timeline_diff_review",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_transition_review_queue"
           } = List.first(flat_review_branch["events"])

    assert Enum.any?(
             review_branch["candidate_plan"]["strategic_additions"],
             &(get_in(&1, ["feasibility", "feedback_source"]) ==
                 "prior_plan.operator_review_package.rows.source_timeline_application" and
                 get_in(&1, ["feasibility", "source_activity_id"]) == "obs_review_application")
           )

    import_branch = branch(artifact, "derived_timeline_diff_removed_obs_import_application")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_a",
             "source_activity_id" => "obs_import_application",
             "application_status" => "source_preserved_pending_review",
             "policy_classification" => "operator_review_required",
             "approval_rule_matches" => [
               %{
                 "rule_id" => "transition_import_review",
                 "classification" => "operator_review_required",
                 "application_status" => "source_preserved_pending_review"
               }
             ],
             "source_policy_decision" => %{
               "schema_contract" => "policy_decision.v1",
               "classification" => "operator_review_required",
               "policy_bundle_id" => "timeline_transition_import_policy"
             },
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.source_review_row.source_timeline_application",
             "trust_boundary" => "cadence_transition_import_queue"
           } = List.first(import_branch["events"])

    flat_import_branch =
      branch(artifact, "derived_timeline_diff_removed_obs_flat_import_application")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_a",
             "source_activity_id" => "obs_flat_import_application",
             "feedback_source" => "prior_plan.cadence_import_manifest.rows.timeline_diff_review",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "cadence_transition_import_queue"
           } = List.first(flat_import_branch["events"])

    assert Enum.any?(
             import_branch["candidate_plan"]["strategic_additions"],
             &(get_in(&1, ["feasibility", "feedback_source"]) ==
                 "prior_plan.cadence_import_manifest.rows.source_review_row.source_timeline_application" and
                 get_in(&1, ["feasibility", "source_activity_id"]) == "obs_import_application")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy accepts source timeline transition application aliases in review and import rows" do
    transition_application = %{
      "id" => "timeline_application:timeline:obs_alias_review",
      "rank" => 1,
      "timeline_id" => "timeline:obs_alias_review",
      "diff_status" => "removed",
      "source_activity_id" => "obs_alias_review",
      "source_activity_type" => "observe",
      "source_target_id" => "target_a",
      "scenario_id" => "leo_1",
      "source_status" => "planned",
      "changed_fields" => ["status"],
      "transition_decision" => "review",
      "requires_operator_review" => true,
      "required_operator_action" => "review_removed_activity",
      "application_status" => "source_preserved_pending_review",
      "selected_activity_source" => "source",
      "selected_activity" => %{"activity_id" => "obs_alias_review"},
      "source_timeline_diff" => %{
        "id" => "timeline_diff:timeline:obs_alias_review",
        "rank" => 1,
        "timeline_id" => "timeline:obs_alias_review",
        "diff_status" => "removed",
        "source_activity_id" => "obs_alias_review",
        "source_activity_type" => "observe",
        "source_target_id" => "target_a",
        "scenario_id" => "leo_1",
        "source_status" => "planned",
        "changed_fields" => ["status"],
        "requires_operator_review" => true,
        "required_operator_action" => "review_removed_activity"
      }
    }

    import_application =
      transition_application
      |> put_in(["id"], "timeline_application:timeline:obs_alias_import")
      |> put_in(["timeline_id"], "timeline:obs_alias_import")
      |> put_in(["source_activity_id"], "obs_alias_import")
      |> put_in(["selected_activity", "activity_id"], "obs_alias_import")
      |> put_in(["source_timeline_diff", "id"], "timeline_diff:timeline:obs_alias_import")
      |> put_in(["source_timeline_diff", "timeline_id"], "timeline:obs_alias_import")
      |> put_in(["source_timeline_diff", "source_activity_id"], "obs_alias_import")

    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_alias_review_recovery", "leo_1", "target_a", 360.0, 420.0, 12.0),
          observe("obs_alias_import_recovery", "leo_1", "target_a", 420.0, 480.0, 12.0)
        ],
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "timeline_transition_application_report.v1",
          "review_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_transition_alias_review_queue"},
          "rows" => [
            %{
              "id" => "operator_review:timeline_application:obs_alias_review",
              "review_type" => "timeline_diff_review",
              "source" => "timeline_transition_application_report.applications",
              "subject_id" => "timeline:obs_alias_review",
              "approval_status" => "operator_review_required",
              "source_timeline_transition_application" => transition_application
            }
          ]
        },
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "timeline_transition_application_report.v1",
          "manifest_id" => "cadence_import_manifest:timeline_transition_application_aliases",
          "row_count" => 1,
          "ready_count" => 0,
          "review_required_count" => 1,
          "blocked_count" => 0,
          "missing_import_count" => 0,
          "provenance" => %{"trust_boundary" => "cadence_transition_alias_import_queue"},
          "rows" => [
            %{
              "id" => "cadence_import:timeline_application:obs_alias_import",
              "rank" => 1,
              "import_action" => "review_timeline_diff",
              "import_status" => "review_required_before_import",
              "cadence_import_status" => "present",
              "source_review_type" => "timeline_diff_review",
              "source_review_row" => %{
                "id" => "operator_review:timeline_application:obs_alias_import",
                "review_type" => "timeline_diff_review",
                "source" => "timeline_transition_application_report.applications",
                "subject_id" => "timeline:obs_alias_import",
                "approval_status" => "operator_review_required",
                "source_timeline_transition_application" => import_application
              }
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

    review_branch = branch(artifact, "derived_timeline_diff_removed_obs_alias_review")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_a",
             "source_activity_id" => "obs_alias_review",
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.source_timeline_transition_application",
             "trust_boundary" => "ops_transition_alias_review_queue"
           } = List.first(review_branch["events"])

    import_branch = branch(artifact, "derived_timeline_diff_removed_obs_alias_import")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_a",
             "source_activity_id" => "obs_alias_import",
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.source_review_row.source_timeline_transition_application",
             "trust_boundary" => "cadence_transition_alias_import_queue"
           } = List.first(import_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives timeline transition application refresh from mission-state reports" do
    transition_application = %{
      "id" => "timeline_application:timeline:obs_mission_application",
      "rank" => 1,
      "timeline_id" => "timeline:obs_mission_application",
      "diff_status" => "removed",
      "source_activity_id" => "obs_mission_application",
      "source_activity_type" => "observe",
      "source_target_id" => "target_a",
      "scenario_id" => "leo_1",
      "source_status" => "planned",
      "changed_fields" => ["status"],
      "transition_decision" => "review",
      "requires_operator_review" => true,
      "required_operator_action" => "review_removed_activity",
      "application_status" => "source_preserved_pending_review",
      "selected_activity_source" => "source",
      "selected_activity" => %{"activity_id" => "obs_mission_application"},
      "source_timeline_diff" => %{
        "id" => "timeline_diff:timeline:obs_mission_application",
        "rank" => 1,
        "timeline_id" => "timeline:obs_mission_application",
        "diff_status" => "removed",
        "source_activity_id" => "obs_mission_application",
        "source_activity_type" => "observe",
        "source_target_id" => "target_a",
        "scenario_id" => "leo_1",
        "source_status" => "planned",
        "changed_fields" => ["status"],
        "requires_operator_review" => true,
        "required_operator_action" => "review_removed_activity"
      }
    }

    timeline_transition_application_report = %{
      "schema_contract" => "timeline_transition_application_report.v1",
      "model" => "artifact_only_timeline_transition_application",
      "source" => "mission_state.timeline_transition_application",
      "source_activity_count" => 1,
      "replacement_activity_count" => 0,
      "application_count" => 1,
      "selected_activity_count" => 1,
      "review_required_count" => 1,
      "provenance" => %{"trust_boundary" => "mission_transition_application_review"},
      "applications" => [transition_application],
      "assumptions" => %{"execution_boundary" => "artifact_only_no_schedule_mutation"}
    }

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(
            :source_timeline_transition_application_report,
            timeline_transition_application_report
          ),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    application_branch = branch(artifact, "derived_timeline_diff_removed_obs_mission_application")

    assert_candidate_source_report_path(
      application_branch,
      "mission_state.source_timeline_transition_application_report"
    )

    assert_candidate_refresh_request_report_path(
      application_branch,
      "mission_state.source_timeline_transition_application_report"
    )

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_a",
             "source_activity_id" => "obs_mission_application",
             "application_status" => "source_preserved_pending_review",
             "selected_activity_source" => "source",
             "selected_activity" => %{"activity_id" => "obs_mission_application"},
             "feedback_source" =>
               "mission_state.source_timeline_transition_application_report.applications",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "mission_transition_application_review",
             "source_timeline_application" => %{
               "application_status" => "source_preserved_pending_review"
             }
           } = List.first(application_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives timeline transition application refresh from result artifact reports" do
    transition_application = %{
      "id" => "timeline_application:timeline:obs_result_application",
      "rank" => 1,
      "timeline_id" => "timeline:obs_result_application",
      "diff_status" => "removed",
      "source_activity_id" => "obs_result_application",
      "source_activity_type" => "observe",
      "source_target_id" => "target_a",
      "scenario_id" => "leo_1",
      "source_status" => "planned",
      "changed_fields" => ["status"],
      "transition_decision" => "review",
      "requires_operator_review" => true,
      "required_operator_action" => "review_removed_activity",
      "application_status" => "source_preserved_pending_review",
      "selected_activity_source" => "source",
      "selected_activity" => %{"activity_id" => "obs_result_application"},
      "source_timeline_diff" => %{
        "id" => "timeline_diff:timeline:obs_result_application",
        "rank" => 1,
        "timeline_id" => "timeline:obs_result_application",
        "diff_status" => "removed",
        "source_activity_id" => "obs_result_application",
        "source_activity_type" => "observe",
        "source_target_id" => "target_a",
        "scenario_id" => "leo_1",
        "source_status" => "planned",
        "changed_fields" => ["status"],
        "requires_operator_review" => true,
        "required_operator_action" => "review_removed_activity"
      }
    }

    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_result_application_recovery", "leo_1", "target_a", 360.0, 420.0, 12.0)
        ],
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "study_id" => "timeline_transition_application_result_artifact",
          "provenance" => %{"trust_boundary" => "ops_result_artifact"},
          "timeline_transition_application_report" => %{
            "schema_contract" => "timeline_transition_application_report.v1",
            "model" => "artifact_only_timeline_transition_application",
            "source" => "repair.activities",
            "source_activity_count" => 1,
            "replacement_activity_count" => 0,
            "application_count" => 1,
            "selected_activity_count" => 1,
            "review_required_count" => 1,
            "applications" => [transition_application],
            "assumptions" => %{"execution_boundary" => "artifact_only_no_schedule_mutation"}
          }
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch = branch(artifact, "derived_timeline_diff_removed_obs_result_application")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_a",
             "source_activity_id" => "obs_result_application",
             "application_status" => "source_preserved_pending_review",
             "selected_activity_source" => "source",
             "selected_activity" => %{"activity_id" => "obs_result_application"},
             "feedback_source" =>
               "prior_plan.source_result_artifact.timeline_transition_application_report.applications",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_result_artifact",
             "source_timeline_application" => %{
               "application_status" => "source_preserved_pending_review"
             }
           } = List.first(branch["events"])

    assert Enum.any?(
             branch["candidate_plan"]["strategic_additions"],
             &(get_in(&1, ["feasibility", "feedback_source"]) ==
                 "prior_plan.source_result_artifact.timeline_transition_application_report.applications" and
                 get_in(&1, ["feasibility", "source_activity_id"]) == "obs_result_application")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives prior result-artifact timeline refresh from source report keys" do
    transition_application = %{
      "id" => "timeline_application:timeline:obs_source_result_application",
      "rank" => 1,
      "timeline_id" => "timeline:obs_source_result_application",
      "diff_status" => "removed",
      "source_activity_id" => "obs_source_result_application",
      "source_activity_type" => "observe",
      "source_target_id" => "target_b",
      "scenario_id" => "leo_1",
      "source_status" => "planned",
      "changed_fields" => ["status"],
      "transition_decision" => "review",
      "requires_operator_review" => true,
      "required_operator_action" => "review_removed_activity",
      "application_status" => "source_preserved_pending_review",
      "selected_activity_source" => "source",
      "selected_activity" => %{"activity_id" => "obs_source_result_application"},
      "source_timeline_diff" => %{
        "id" => "timeline_diff:timeline:obs_source_result_application",
        "rank" => 1,
        "timeline_id" => "timeline:obs_source_result_application",
        "diff_status" => "removed",
        "source_activity_id" => "obs_source_result_application",
        "source_activity_type" => "observe",
        "source_target_id" => "target_b",
        "scenario_id" => "leo_1",
        "source_status" => "planned",
        "changed_fields" => ["status"],
        "requires_operator_review" => true,
        "required_operator_action" => "review_removed_activity"
      }
    }

    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_source_result_diff_recovery", "leo_1", "target_a", 360.0, 420.0, 12.0),
          observe(
            "obs_source_result_application_recovery",
            "leo_1",
            "target_b",
            480.0,
            540.0,
            10.0
          )
        ],
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "study_id" => "source_timeline_result_artifact",
          "provenance" => %{"trust_boundary" => "ops_source_result_artifact"},
          "source_timeline_diff_report" => %{
            "schema_contract" => "timeline_diff_report.v1",
            "model" => "timeline_identity_activity_diff",
            "source" => "adapter.source_timeline_diff",
            "row_count" => 1,
            "removed_count" => 1,
            "rows" => [
              %{
                "id" => "timeline_diff:timeline:obs_source_result_diff",
                "rank" => 1,
                "timeline_id" => "timeline:obs_source_result_diff",
                "diff_status" => "removed",
                "source_activity_id" => "obs_source_result_diff",
                "source_activity_type" => "observe",
                "source_target_id" => "target_a",
                "scenario_id" => "leo_1",
                "source_status" => "planned",
                "required_operator_action" => "review_removed_activity"
              }
            ]
          },
          "source_timeline_transition_application_report" => %{
            "schema_contract" => "timeline_transition_application_report.v1",
            "model" => "artifact_only_timeline_transition_application",
            "source" => "adapter.source_timeline_transition_application",
            "source_activity_count" => 1,
            "replacement_activity_count" => 0,
            "application_count" => 1,
            "selected_activity_count" => 1,
            "review_required_count" => 1,
            "applications" => [transition_application],
            "assumptions" => %{"execution_boundary" => "artifact_only_no_schedule_mutation"}
          }
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    diff_branch = branch(artifact, "derived_timeline_diff_removed_obs_source_result_diff")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_a",
             "source_activity_id" => "obs_source_result_diff",
             "timeline_id" => "timeline:obs_source_result_diff",
             "feedback_source" => "prior_plan.source_result_artifact.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_source_result_artifact"
           } = List.first(diff_branch["events"])

    application_branch =
      branch(artifact, "derived_timeline_diff_removed_obs_source_result_application")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_b",
             "source_activity_id" => "obs_source_result_application",
             "timeline_id" => "timeline:obs_source_result_application",
             "application_status" => "source_preserved_pending_review",
             "selected_activity_source" => "source",
             "feedback_source" =>
               "prior_plan.source_result_artifact.source_timeline_transition_application_report.applications",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_source_result_artifact"
           } = List.first(application_branch["events"])

    assert Enum.any?(
             application_branch["candidate_plan"]["strategic_additions"],
             &(get_in(&1, ["feasibility", "feedback_source"]) ==
                 "prior_plan.source_result_artifact.source_timeline_transition_application_report.applications" and
                 get_in(&1, ["feasibility", "source_activity_id"]) ==
                   "obs_source_result_application")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_candidate_source_report_path(branch, expected_path) do
    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = branch["assumptions"]["candidate_source"]

    assert expected_path in candidate_source["source_report_input_paths"]
    candidate_source
  end

  defp assert_candidate_refresh_request_report_path(branch, expected_path) do
    assert expected_path in get_in(branch, [
             "assumptions",
             "candidate_source",
             "candidate_refresh_request_source_report_input_paths"
           ])
  end
end
