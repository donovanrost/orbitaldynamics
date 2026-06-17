Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyOperationalFeedbackTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy operational feedback and resources create deterministic score terms and risks" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          observe("obs_1", "leo_1", "target_a", 100.0, 160.0, 100.0),
          downlink("dl_1", 200.0, 260.0)
        ],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([%{"type" => "downlink_completion", "required_contacts" => 2}],
            resources: %{"fuel_margin" => 0.1, "storage_margin" => 0.1, "downlink_margin" => 0.4}
          ),
        operational_feedback: %{
          contact_success_rate: %{default: 0.7},
          observation_success_rate: %{"target_a" => 0.6},
          station_throughput_factor: %{"equator_prime" => 0.5}
        },
        branches: [
          %{id: "baseline"},
          %{id: "fuel", events: [%{type: "fuel_preservation_mode"}]}
        ],
        current_epoch_s: 0.0
      )

    fuel = branch(artifact, "fuel")

    assert fuel["score_terms"]["resource_score"] < 0.0
    assert fuel["score_terms"]["feedback_adjustment_score"] < 0.0
    assert Enum.any?(fuel["risk_indicators"], &(&1["type"] == "fuel_margin_low"))
    assert Enum.any?(fuel["risk_indicators"], &(&1["type"] == "contact_success_rate_low"))
    assert fuel["resource_impacts"]["downlink_capacity_margin"] == 0.4
    assert fuel["feedback_adjustments"]["station_throughput_factor"] == 0.5

    fuel_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "fuel"))

    assert fuel_row["fuel_margin"] == 0.1
    assert fuel_row["storage_margin"] == 0.1
    assert fuel_row["downlink_capacity_margin"] == 0.4
    assert fuel_row["resource_score_adjustment"] < 0.0
    assert fuel_row["fuel_preservation_mode"] == true

    assert fuel_row["resource_risk_types"] == [
             "downlink_capacity_low",
             "fuel_margin_low",
             "storage_margin_low"
           ]
  end

  test "strategy feedback adjustments include planned-contact downlinks" do
    planned_contact =
      "planned_dl_1"
      |> downlink(200.0, 260.0)
      |> Map.put("type", "planned_contact")
      |> Map.put("direction", "downlink")

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [planned_contact],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        operational_feedback: %{
          contact_success_rate: %{"equator_prime" => 0.4},
          station_throughput_factor: %{"equator_prime" => 0.5}
        },
        branches: [%{id: "baseline"}, %{id: "review"}],
        current_epoch_s: 0.0
      )

    review = branch(artifact, "review")

    assert review["feedback_adjustments"]["contact_success_factor"] == 0.4

    assert review["feedback_adjustments"]["contact_success_factor_source"] ==
             "operational_feedback.contact_success_rate"

    assert review["feedback_adjustments"]["station_throughput_factor"] == 0.5

    assert review["feedback_adjustments"]["station_throughput_factor_source"] ==
             "operational_feedback.station_throughput_factor"

    assert review["score_terms"]["feedback_adjustment_score"] < 0.0

    assert Enum.any?(
             review["risk_indicators"],
             &(&1["type"] == "contact_success_rate_low" and &1["value"] == 0.4)
           )

    assert Enum.any?(
             review["risk_indicators"],
             &(&1["type"] == "station_throughput_factor_low" and &1["value"] == 0.5)
           )

    review_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "review"))

    assert review_row["contact_success_factor_source"] ==
             "operational_feedback.contact_success_rate"

    assert review_row["station_throughput_factor_source"] ==
             "operational_feedback.station_throughput_factor"

    assert_execution_feedback_pressure_score_terms(review, artifact, [
      "contact_success_rate_low",
      "station_throughput_factor_low"
    ])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy applies maneuver success feedback to maneuver activities and events" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          %{
            "id" => "burn_impulsive",
            "type" => "impulsive_burn",
            "scenario_id" => "leo_1",
            "starts_at_s" => 100.0,
            "ends_at_s" => 100.0,
            "duration_s" => 0.0,
            "score" => 0.0
          },
          downlink("dl_1", 300.0, 360.0)
        ],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        operational_feedback: %{
          maneuver_success_rate: %{"burn_impulsive" => 0.5}
        },
        branches: [
          %{id: "baseline"},
          %{
            id: "maneuver_confidence",
            events: [
              %{
                type: "delayed_maneuver",
                activity_id: "burn_impulsive",
                actual_starts_at_s: 140.0
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    maneuver_branch = branch(artifact, "maneuver_confidence")

    assert maneuver_branch["feedback_adjustments"]["maneuver_success_factor"] == 0.5
    assert maneuver_branch["score_terms"]["feedback_adjustment_score"] < 0.0

    assert Enum.any?(
             maneuver_branch["risk_indicators"],
             &(&1["type"] == "maneuver_success_rate_low" and &1["value"] == 0.5)
           )
  end

  test "strategy applies branch-authored maneuver feedback with provider feedback key to activity scoring" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          %{
            "id" => "burn_impulsive",
            "type" => "impulsive_burn",
            "scenario_id" => "leo_1",
            "starts_at_s" => 100.0,
            "ends_at_s" => 100.0,
            "duration_s" => 0.0,
            "score" => 0.0
          }
        ],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        branches: [
          %{id: "baseline"},
          %{
            id: "maneuver_provider_confidence",
            events: [
              %{
                type: "maneuver_success_feedback",
                activity_id: "burn_impulsive",
                feedback_key: "provider-feedback-burn-42",
                maneuver_success_factor: 0.4
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    maneuver_branch = branch(artifact, "maneuver_provider_confidence")

    assert maneuver_branch["feedback_adjustments"]["maneuver_success_factor"] == 0.4

    assert Enum.any?(
             maneuver_branch["risk_indicators"],
             &(&1["type"] == "maneuver_success_rate_low" and &1["value"] == 0.4)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy applies command success feedback to command and health-check activities" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          health_check("cmd_health_1", "leo_1", 100.0, 130.0),
          downlink("dl_1", 300.0, 360.0)
        ],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        operational_feedback: %{
          command_success_rate: %{"cmd_health_1" => 0.25}
        },
        branches: [%{id: "baseline"}, %{id: "command_confidence"}],
        current_epoch_s: 0.0
      )

    command_branch = branch(artifact, "command_confidence")

    assert command_branch["feedback_adjustments"]["command_success_factor"] == 0.25
    assert command_branch["score_terms"]["feedback_adjustment_score"] < 0.0

    command_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "command_confidence"))

    assert command_row["command_success_factor"] == 0.25
    assert command_row["feedback_score_adjustment"] < 0.0
    assert "command_success_rate_low" in command_row["feedback_risk_types"]

    assert Enum.any?(
             command_branch["risk_indicators"],
             &(&1["type"] == "command_success_rate_low" and &1["value"] == 0.25)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy applies branch-authored command feedback with provider feedback key to activity scoring" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          health_check("cmd_health_1", "leo_1", 100.0, 130.0),
          downlink("dl_1", 300.0, 360.0)
        ],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        branches: [
          %{id: "baseline"},
          %{
            id: "command_provider_confidence",
            events: [
              %{
                type: "command_success_feedback",
                activity_id: "cmd_health_1",
                feedback_key: "provider-feedback-command-42",
                command_success_factor: 0.25
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    command_branch = branch(artifact, "command_provider_confidence")

    assert command_branch["feedback_adjustments"]["command_success_factor"] == 0.25

    assert Enum.any?(
             command_branch["risk_indicators"],
             &(&1["type"] == "command_success_rate_low" and &1["value"] == 0.25)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_execution_feedback_pressure_score_terms(branch, artifact, risk_types) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])
    expected_risk_types = List.wrap(risk_types)

    execution_feedback_risk_types =
      ~w(contact_success_rate_low observation_success_rate_low station_throughput_factor_low command_success_rate_low maneuver_success_rate_low maneuver_execution_uncertainty_high maneuver_execution_uncertainty_missing)

    Enum.each(expected_risk_types, fn risk_type ->
      assert Enum.any?(branch["risk_indicators"], &(&1["type"] == risk_type))
    end)

    execution_feedback_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] in execution_feedback_risk_types)
      )

    assert execution_feedback_pressure_count > 0

    assert branch["score_terms"]["execution_feedback_pressure_penalty"] ==
             -execution_feedback_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - execution_feedback_pressure_count) *
               risk_weight

    assert "execution_feedback_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "execution_feedback_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end

  test "strategy does not create downlink resource risk from capacity without downlink objective" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [observe("obs_1", "leo_1", "target_a", 100.0, 160.0, 100.0)],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state([], resources: %{downlink_capacity_mb: 0.1}),
        branches: [
          %{id: "baseline"},
          %{id: "observe_only", events: [%{type: "fuel_preservation_mode"}]}
        ],
        current_epoch_s: 0.0
      )

    observe_only = branch(artifact, "observe_only")

    assert observe_only["resource_impacts"]["downlink_capacity_margin"] == nil
    assert observe_only["score_terms"]["resource_score"] == 0.0
    refute Enum.any?(observe_only["risk_indicators"], &(&1["type"] == "downlink_capacity_low"))
    refute Enum.any?(observe_only["risk_indicators"], &(&1["type"] == "no_viable_downlink"))
  end
end
