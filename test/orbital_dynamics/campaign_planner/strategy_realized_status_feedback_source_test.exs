Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRealizedStatusFeedbackSourceTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives downlink demand from reviewed realized-status failures" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("dl_failed_review", 100.0, 160.0)
          |> Map.put("required_downlink_mb", 120.0)
        ],
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "timeline_feedback_report.v1",
          "review_count" => 1,
          "rows" => [
            %{
              "id" => "operator_review:realized_feedback:dl_failed_review",
              "review_type" => "realized_feedback",
              "activity_id" => "dl_failed_review",
              "activity_type" => "downlink",
              "feedback_status" => "matched",
              "realized_status" => "failed",
              "ground_station_id" => "equator_prime",
              "source_feedback" => %{
                "activity_id" => "dl_failed_review",
                "status" => "matched",
                "realized_status" => "failed",
                "planned_type" => "downlink",
                "ground_station_id" => "equator_prime",
                "required_downlink_mb" => 120.0
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

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.0
           }

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "equator_prime" => 120.0
           }

    assert %{
             "type" => "downlink_demand_feedback",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 120.0
           } = List.first(branch(artifact, "derived_downlink_demand_feedback")["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives non-contact confidence from reviewed realized status" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          observe("obs_failed_review", "leo_1", "target_a", 100.0, 160.0, 10.0),
          health_check("cmd_partial_review", "leo_1", 200.0, 230.0),
          %{
            "id" => "burn_delayed_review",
            "type" => "impulsive_burn",
            "scenario_id" => "leo_1",
            "starts_at_s" => 300.0,
            "ends_at_s" => 300.0,
            "duration_s" => 0.0,
            "score" => 0.0
          }
        ],
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "timeline_feedback_report.v1",
          "review_count" => 3,
          "rows" => [
            %{
              "id" => "operator_review:realized_feedback:obs_failed_review",
              "review_type" => "realized_feedback",
              "activity_id" => "obs_failed_review",
              "activity_type" => "observe",
              "feedback_status" => "matched",
              "realized_status" => "failed",
              "target_id" => "target_a",
              "source_feedback" => %{
                "activity_id" => "obs_failed_review",
                "status" => "matched",
                "realized_status" => "failed",
                "planned_type" => "observe",
                "target_id" => "target_a"
              }
            },
            %{
              "id" => "operator_review:realized_feedback:cmd_partial_review",
              "review_type" => "realized_feedback",
              "activity_id" => "cmd_partial_review",
              "activity_type" => "health_check",
              "feedback_status" => "matched",
              "realized_status" => "partial",
              "source_feedback" => %{
                "activity_id" => "cmd_partial_review",
                "status" => "matched",
                "realized_status" => "partial",
                "planned_type" => "health_check"
              }
            },
            %{
              "id" => "operator_review:realized_feedback:burn_delayed_review",
              "review_type" => "realized_feedback",
              "activity_id" => "burn_delayed_review",
              "activity_type" => "impulsive_burn",
              "feedback_status" => "matched",
              "realized_status" => "delayed",
              "source_feedback" => %{
                "activity_id" => "burn_delayed_review",
                "status" => "matched",
                "realized_status" => "delayed",
                "planned_type" => "impulsive_burn"
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

    assert get_in(artifact, ["operational_feedback", "observation_success_rate"]) == %{
             "target_a" => 0.0
           }

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_partial_review" => 0.5
           }

    assert get_in(artifact, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_delayed_review" => 0.5
           }

    assert %{"observation_success_factor" => observation_success_factor} =
             List.first(branch(artifact, "derived_observation_success_feedback")["events"])

    assert observation_success_factor == 0.0

    assert %{"command_success_factor" => 0.5} =
             List.first(branch(artifact, "derived_command_success_feedback")["events"])

    assert %{"maneuver_success_factor" => 0.5} =
             List.first(branch(artifact, "derived_maneuver_success_feedback")["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
