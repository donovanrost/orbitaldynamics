Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyResourceMarginFeedbackTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{Schema, TimelineFeedback}

  test "strategy derives resource margin refresh branch from operational feedback" do
    artifact =
      strategy(
        base_plan(%{
          "activities" => [
            observe("obs_storage", "leo_1", "target_a", 100.0, 160.0, 20.0)
            |> Map.put("estimated_storage_mb", 25.0)
          ]
        }),
        mission_state: mission_state_with_refresh_inputs(),
        operational_feedback: %{
          trust_boundary: "cadence_operational_feedback",
          resource_margin_overrides: %{"leo_1" => %{"storage_margin" => 0.05}}
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    resource_branch = branch(artifact, "derived_resource_margin_feedback")

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "storage_margin",
             "storage_margin" => 0.05,
             "storage_margin_threshold" => 0.2,
             "feedback_source" => "operational_feedback.resource_margin_overrides",
             "trust_boundary" => "cadence_operational_feedback"
           } = List.first(resource_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             resource_branch["assumptions"]["candidate_source"]

    assert Enum.any?(
             resource_branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["storage_margin"] == 0.05 and
                 get_in(&1, ["provenance", "trust_boundary"]) ==
                   "cadence_operational_feedback")
           )

    assert %{
             "schema_contract" => "resource_projection_report.v1",
             "projected_resources" => projected_resources
           } = resource_branch["resource_projection_report"]

    assert Enum.any?(
             projected_resources,
             &(&1["spacecraft_id"] == "leo_1" and &1["starting_storage_margin"] == 0.05)
           )

    assert Enum.any?(
             resource_branch["risk_indicators"],
             &(&1["type"] == "storage_margin_low" and &1["value"] == 0.05)
           )

    assert resource_branch["resource_impacts"]["storage_margin"] == 0.05
    assert resource_branch["resource_impacts"]["score_adjustment"] < 0.0

    resource_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_resource_margin_feedback"))

    assert resource_row["storage_margin"] == 0.05
    assert resource_row["resource_score_adjustment"] < 0.0
    assert "storage_margin_low" in resource_row["resource_risk_types"]

    assert get_in(artifact, ["operational_feedback", "resource_margin_overrides"]) == %{
             "leo_1" => %{"storage_margin" => 0.05}
           }

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives thermal margin refresh branch from operational feedback" do
    artifact =
      strategy(
        base_plan(%{
          "activities" => [
            observe("obs_thermal", "leo_1", "target_a", 100.0, 160.0, 20.0)
          ]
        }),
        mission_state: mission_state_with_refresh_inputs(),
        operational_feedback: %{
          trust_boundary: "cadence_thermal_feedback",
          resource_margin_overrides: %{"leo_1" => %{"thermal_margin_c" => "1.5"}}
        },
        branch_generation_policy: %{thermal_margin_c_threshold: "2.0"},
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    resource_branch = branch(artifact, "derived_resource_margin_feedback")

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "thermal_margin_c",
             "thermal_margin_c" => 1.5,
             "thermal_margin_c_threshold" => 2.0,
             "feedback_source" => "operational_feedback.resource_margin_overrides",
             "trust_boundary" => "cadence_thermal_feedback"
           } = List.first(resource_branch["events"])

    assert get_in(artifact, ["operational_feedback", "resource_margin_overrides"]) == %{
             "leo_1" => %{"thermal_margin_c" => 1.5}
           }

    assert Enum.any?(
             resource_branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["thermal_margin_c"] == 1.5 and
                 get_in(&1, ["provenance", "trust_boundary"]) == "cadence_thermal_feedback")
           )

    assert %{"min_activity_thermal_margin_c" => 2.0} =
             resource_branch["repair_result"]["source_resource_filter_report"]["policy"]

    assert Enum.any?(
             resource_branch["repair_result"]["source_resource_filter_report"][
               "suppressed_candidates"
             ],
             &(&1["suppressed_reason"] == "thermal_margin_below_policy" and
                 &1["thermal_margin_c"] == 1.5)
           )

    assert Enum.any?(
             resource_branch["risk_indicators"],
             &(&1["type"] == "thermal_margin_c_low" and &1["value"] == 1.5)
           )

    resource_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_resource_margin_feedback"))

    assert resource_row["thermal_margin_c"] == 1.5
    assert "thermal_margin_low" in resource_row["resource_risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives power margin refresh from battery state feedback" do
    artifact =
      strategy(
        base_plan(%{
          "activities" => [
            observe("obs_power", "leo_1", "target_a", 100.0, 160.0, 20.0)
            |> Map.put("estimated_energy_used_wh", 10.0)
          ]
        }),
        mission_state: mission_state_with_refresh_inputs(),
        operational_feedback: %{
          resource_margin_overrides: %{
            "leo_1" => %{
              "battery_capacity_wh" => 100.0,
              "battery_energy_used_wh" => 95.0,
              "battery_soc" => 0.05
            }
          }
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    resource_branch = branch(artifact, "derived_resource_margin_feedback")

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "power_margin",
             "power_margin" => 0.05,
             "power_margin_threshold" => 0.2,
             "feedback_source" => "operational_feedback.resource_margin_overrides"
           } = Enum.find(resource_branch["events"], &(&1["resource_field"] == "power_margin"))

    assert get_in(artifact, ["operational_feedback", "resource_margin_overrides"]) == %{
             "leo_1" => %{
               "battery_capacity_wh" => 100.0,
               "battery_energy_used_wh" => 95.0,
               "battery_state_of_charge" => 0.05,
               "power_margin" => 0.05
             }
           }

    assert Enum.any?(
             resource_branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["power_margin"] == 0.05)
           )

    assert Enum.any?(
             resource_branch["risk_indicators"],
             &(&1["type"] == "power_margin_low" and &1["value"] == 0.05)
           )

    resource_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_resource_margin_feedback"))

    assert resource_row["power_margin"] == 0.05
    assert "power_margin_low" in resource_row["resource_risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives resource margin refresh branch from realized resource telemetry" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "resource_snapshot_1",
          type: "resource_snapshot",
          status: "completed",
          spacecraft_id: "leo_1",
          storage_capacity_margin: 0.05,
          downlink_capacity_margin: 0.4
        }
      ])

    artifact =
      strategy(
        base_plan(%{
          "activities" => [
            observe("obs_storage", "leo_1", "target_a", 100.0, 160.0, 20.0)
            |> Map.put("estimated_storage_mb", 25.0)
          ]
        }),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    resource_branch = branch(artifact, "derived_resource_margin_feedback")

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "storage_margin",
             "storage_margin" => 0.05,
             "feedback_source" => "operational_feedback.resource_margin_overrides"
           } = Enum.find(resource_branch["events"], &(&1["resource_field"] == "storage_margin"))

    assert get_in(artifact, ["operational_feedback", "resource_margin_overrides"]) == %{
             "leo_1" => %{"downlink_margin" => 0.4, "storage_margin" => 0.05}
           }

    assert %{
             "source" => "mission_state.realized_activities",
             "input_keys" => ["resource_margin_overrides"]
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] == "mission_state.realized_activities")
             )

    assert Enum.any?(
             resource_branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["storage_margin"] == 0.05)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy routes prior timeline resource feedback trust boundaries by resource field" do
    feedback_report =
      TimelineFeedback.reconcile(
        [],
        [
          %{
            id: :resource_snapshot_ops,
            type: :resource_snapshot,
            status: :completed,
            spacecraft_id: :leo_1,
            storage_margin: 0.05,
            payload_available: false,
            antenna_available: false,
            trust_boundary: :ops_resource_feedback
          }
        ]
      )

    prior_plan =
      base_plan(%{
        "activities" => [
          observe("obs_storage", "leo_1", "target_a", 100.0, 160.0, 20.0)
          |> Map.put("estimated_storage_mb", 25.0)
        ],
        "source_timeline_feedback_report" => feedback_report
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] ==
            "prior_plan.source_timeline_feedback_report.operational_feedback")
      )

    assert %{
             "source_operational_feedback_provenance" => %{
               "sources" => [
                 %{
                   "feedback_trust_boundaries" => %{
                     "resource_availability_overrides" => %{
                       "leo_1" => ["ops_resource_feedback"]
                     },
                     "resource_margin_overrides" => %{"leo_1" => ["ops_resource_feedback"]}
                   }
                 }
               ]
             }
           } = source

    resource_branch = branch(artifact, "derived_resource_margin_feedback")
    availability_branch = branch(artifact, "derived_resource_availability_feedback")

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "storage_margin",
             "storage_margin" => 0.05,
             "feedback_source" => "operational_feedback.resource_margin_overrides",
             "trust_boundary" => "ops_resource_feedback"
           } = Enum.find(resource_branch["events"], &(&1["resource_field"] == "storage_margin"))

    assert %{
             "type" => "resource_availability_constraint",
             "spacecraft_id" => "leo_1",
             "resource_field" => "payload_available",
             "available" => false,
             "feedback_source" => "operational_feedback.resource_availability_overrides",
             "trust_boundary" => "ops_resource_feedback"
           } =
             Enum.find(
               availability_branch["events"],
               &(&1["resource_field"] == "payload_available")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives thermal margin refresh branch from realized resource telemetry" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "thermal_snapshot_1",
          type: "resource_snapshot",
          status: "completed",
          spacecraft_id: "leo_1",
          thermal_margin_c: "1.5"
        }
      ])

    artifact =
      strategy(
        base_plan(%{
          "activities" => [
            observe("obs_thermal", "leo_1", "target_a", 100.0, 160.0, 20.0)
          ]
        }),
        mission_state: mission_state,
        branch_generation_policy: %{thermal_margin_c_threshold: "2.0"},
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    resource_branch = branch(artifact, "derived_resource_margin_feedback")

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "thermal_margin_c",
             "thermal_margin_c" => 1.5,
             "thermal_margin_c_threshold" => 2.0,
             "feedback_source" => "operational_feedback.resource_margin_overrides"
           } = List.first(resource_branch["events"])

    assert get_in(artifact, ["operational_feedback", "resource_margin_overrides"]) == %{
             "leo_1" => %{"thermal_margin_c" => 1.5}
           }

    assert %{
             "source" => "mission_state.realized_activities",
             "input_keys" => ["resource_margin_overrides"]
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] == "mission_state.realized_activities")
             )

    assert Enum.any?(
             resource_branch["repair_result"]["source_resource_filter_report"][
               "suppressed_candidates"
             ],
             &(&1["suppressed_reason"] == "thermal_margin_below_policy" and
                 &1["thermal_margin_c"] == 1.5)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
