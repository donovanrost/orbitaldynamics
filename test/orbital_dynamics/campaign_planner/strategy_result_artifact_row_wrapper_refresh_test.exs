Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyResultArtifactRowWrapperRefreshTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives branch-local refresh from mission-state result artifact row wrappers" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          command("cmd_result_planned", "leo_1", 100.0, 130.0),
          command("cmd_result_review_package", "leo_1", 140.0, 170.0),
          command("cmd_result_import_manifest", "leo_1", 180.0, 210.0),
          downlink("dl_result_proposed", 200.0, 260.0)
          |> Map.put("estimated_throughput_mb", 100.0),
          downlink("dl_result_realized", 300.0, 360.0)
          |> Map.put("estimated_throughput_mb", 100.0),
          observe("obs_result_snapshot", "leo_1", "target_a", 400.0, 440.0, 8.0)
        ]
      })

    source_result_artifact = %{
      "schema_contract" => "result_artifact.v1",
      "study_id" => "live_row_result_artifact",
      "metadata" => %{"trust_boundary" => "live_row_result_review"},
      "source_planned_activity" => %{
        "schema_contract" => "planned_activity.v1",
        "id" => "cmd_result_planned",
        "type" => "command",
        "scenario_id" => "leo_1",
        "starts_at_s" => 100.0,
        "ends_at_s" => 130.0,
        "ground_station_id" => "equator_prime",
        "direction" => "command",
        "command_success_factor" => 0.31,
        "command_result" => ["accepted", "timed_out"]
      },
      "source_operator_review_package" => %{
        "schema_contract" => "operator_review_package.v1",
        "source_artifact_type" => "campaign_strategy.v3",
        "rows" => [
          %{
            "id" => "operator_review:command_window:cmd_result_review_package",
            "review_type" => "command_window_review",
            "activity_id" => "cmd_result_review_package",
            "activity_type" => "command",
            "scenario_id" => "leo_1",
            "source_command_window" => %{
              "activity_id" => "cmd_result_review_package",
              "type" => "command",
              "scenario_id" => "leo_1",
              "starts_at_s" => 140.0,
              "ends_at_s" => 170.0,
              "command_success_factor" => 0.36,
              "command_result" => "accepted"
            }
          }
        ]
      },
      "source_cadence_import_manifest" => %{
        "schema_contract" => "cadence_import_manifest.v1",
        "source_artifact_type" => "operator_review_package.v1",
        "rows" => [
          %{
            "id" => "cadence_import:command_window:cmd_result_import_manifest",
            "import_action" => "review_command_window",
            "source_review_type" => "command_window_review",
            "source_review_row" => %{
              "review_type" => "command_window_review",
              "activity_id" => "cmd_result_import_manifest",
              "activity_type" => "command",
              "scenario_id" => "leo_1",
              "source_command_window" => %{
                "activity_id" => "cmd_result_import_manifest",
                "type" => "command",
                "scenario_id" => "leo_1",
                "starts_at_s" => 180.0,
                "ends_at_s" => 210.0,
                "command_success_factor" => 0.66,
                "command_result" => "accepted"
              }
            }
          }
        ]
      },
      "source_proposed_contact" => %{
        "schema_contract" => "proposed_contact.v1",
        "id" => "dl_result_proposed",
        "type" => "downlink",
        "scenario_id" => "leo_1",
        "ground_station_id" => "equator_prime",
        "starts_at_s" => 200.0,
        "ends_at_s" => 260.0,
        "direction" => "downlink",
        "contact_success_factor" => 0.42,
        "actual_throughput_mb" => 42.0,
        "estimated_throughput_mb" => 100.0,
        "required_downlink_mb" => 80.0
      },
      "source_contact_intent" => %{
        "schema_contract" => "contact_intent.v1",
        "id" => "contact_intent:result_blocked",
        "activity_id" => "dl_result_intent",
        "activity_type" => "downlink",
        "scenario_id" => "leo_1",
        "spacecraft_id" => "leo_1",
        "ground_station_id" => "equator_prime",
        "direction" => "downlink",
        "starts_at_s" => 700.0,
        "ends_at_s" => 760.0,
        "estimated_throughput_mb" => 37.0,
        "approval_status" => "blocked_by_policy",
        "policy_decision" => %{
          "classification" => "blocked_by_policy",
          "policy_bundle_id" => "contact_command_review_v1"
        },
        "source_window_id" =>
          "window:leo_1:ground_station_access:equator_prime:result_intent_blocked"
      },
      "source_realized_activity" => %{
        "schema_contract" => "realized_activity.v1",
        "id" => "realized:dl_result_realized",
        "planned_activity_id" => "dl_result_realized",
        "type" => "downlink",
        "status" => "partial",
        "scenario_id" => "leo_1",
        "ground_station_id" => "equator_prime",
        "actual_starts_at_s" => 305.0,
        "actual_ends_at_s" => 355.0,
        "direction" => "downlink",
        "completed_fraction" => 0.2,
        "actual_throughput_mb" => 20.0,
        "estimated_throughput_mb" => 100.0,
        "required_downlink_mb" => 80.0
      },
      "source_realized_state_snapshot" => %{
        "schema_contract" => "realized_state_snapshot.v1",
        "snapshot_id" => "realized_snapshot:result_wrapper",
        "activities" => [
          %{
            "schema_contract" => "realized_activity.v1",
            "id" => "realized:obs_result_snapshot",
            "planned_activity_id" => "obs_result_snapshot",
            "type" => "observe",
            "status" => "partial",
            "scenario_id" => "leo_1",
            "target_id" => "target_a",
            "actual_starts_at_s" => 405.0,
            "actual_ends_at_s" => 435.0,
            "completed_fraction" => 0.45,
            "image_quality_score" => 0.45,
            "image_quality_status" => "marginal",
            "image_quality_source" => "provider_imagery_quality"
          }
        ]
      }
    }

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_result_artifact, source_result_artifact),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    command_branch = branch(artifact, "derived_operational_timeline_feedback_cmd_result_planned")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_result_planned",
             "command_success_factor" => 0.31,
             "command_result" => "accepted,timed_out",
             "feedback_source" => "mission_state.source_result_artifact.source_planned_activity",
             "feedback_scope" => "operational_timeline",
             "trust_boundary" => "live_row_result_review"
           } = List.first(command_branch["events"])

    review_branch =
      branch(artifact, "derived_command_window_feedback_cmd_result_review_package")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_result_review_package",
             "command_success_factor" => 0.36,
             "feedback_source" =>
               "mission_state.source_result_artifact.source_operator_review_package.rows.source_command_window",
             "feedback_scope" => "command_window",
             "trust_boundary" => "live_row_result_review"
           } = List.first(review_branch["events"])

    assert_candidate_source_report_path(
      review_branch,
      "mission_state.source_result_artifact.source_operator_review_package"
    )

    assert_candidate_refresh_request_report_path(
      review_branch,
      "mission_state.source_result_artifact.source_operator_review_package"
    )

    import_branch =
      branch(artifact, "derived_command_window_feedback_cmd_result_import_manifest")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_result_import_manifest",
             "command_success_factor" => 0.66,
             "feedback_source" =>
               "mission_state.source_result_artifact.source_cadence_import_manifest.rows.source_review_row.source_command_window",
             "feedback_scope" => "command_window",
             "trust_boundary" => "live_row_result_review"
           } = List.first(import_branch["events"])

    assert_candidate_source_report_path(
      import_branch,
      "mission_state.source_result_artifact.source_cadence_import_manifest"
    )

    assert_candidate_refresh_request_report_path(
      import_branch,
      "mission_state.source_result_artifact.source_cadence_import_manifest"
    )

    contact_branch = branch(artifact, "derived_operational_timeline_feedback_dl_result_proposed")

    assert Enum.any?(
             contact_branch["events"],
             &(&1["type"] == "contact_success_feedback" and
                 &1["contact_success_factor"] == 0.42 and
                 &1["feedback_source"] ==
                   "mission_state.source_result_artifact.source_proposed_contact" and
                 &1["trust_boundary"] == "live_row_result_review")
           )

    intent_branch =
      branch(
        artifact,
        "derived_contact_intent_pressure_blocked_by_policy_dl_result_intent"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "source_activity_id" => "dl_result_intent",
             "required_downlink_mb" => 37.0,
             "approval_status" => "blocked_by_policy",
             "contact_intent_gate_status" => "blocked_by_policy",
             "policy_classification" => "blocked_by_policy",
             "feedback_source" => "mission_state.source_result_artifact.source_contact_intent",
             "feedback_scope" => "contact_intent",
             "trust_boundary" => "live_row_result_review"
           } = List.first(intent_branch["events"])

    assert_candidate_source_report_path(
      intent_branch,
      "mission_state.source_result_artifact.source_contact_intent"
    )

    assert_candidate_refresh_request_report_path(
      intent_branch,
      "mission_state.source_result_artifact.source_contact_intent"
    )

    realized_branch = branch(artifact, "derived_realized_feedback_dl_result_realized")

    assert Enum.any?(
             realized_branch["events"],
             &(&1["type"] == "contact_success_feedback" and
                 &1["activity_id"] == "dl_result_realized" and
                 &1["contact_success_factor"] == 0.2 and
                 &1["feedback_source"] ==
                   "mission_state.source_result_artifact.source_realized_activity" and
                 &1["trust_boundary"] == "live_row_result_review")
           )

    observation_branch = branch(artifact, "derived_realized_feedback_obs_result_snapshot")

    assert %{
             "type" => "observation_success_feedback",
             "activity_id" => "obs_result_snapshot",
             "target_id" => "target_a",
             "observation_success_factor" => 0.45,
             "image_quality_score" => 0.45,
             "image_quality_status" => "marginal",
             "image_quality_source" => "provider_imagery_quality",
             "feedback_source" =>
               "mission_state.source_result_artifact.source_realized_state_snapshot.activities",
             "trust_boundary" => "live_row_result_review"
           } = List.first(observation_branch["events"])

    planned_source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] == "mission_state.planned_activity")
      )

    assert "mission_state.source_result_artifact.source_planned_activity" in planned_source[
             "source_report_paths"
           ]

    proposed_source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] == "mission_state.proposed_contact")
      )

    assert "mission_state.source_result_artifact.source_proposed_contact" in proposed_source[
             "source_report_paths"
           ]

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
