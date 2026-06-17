Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyBranchResourceFeedbackTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.CampaignPlanner.OperationalFeedback

  test "strategy generated refresh carries explicit branch resource events as operational feedback" do
    artifact =
      strategy(
        base_plan(%{
          "activities" => [
            observe("manual_payload_obs", "leo_1", "target_a", 100.0, 160.0, 20.0),
            downlink("manual_antenna_dl", 220.0, 280.0)
          ]
        }),
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: false,
        branches: [
          %{id: "baseline"},
          %{
            id: "manual_resource",
            events: [
              %{
                type: "resource_margin_pressure",
                spacecraft_id: "leo_1",
                resource_field: "power_margin",
                power_margin: 0.05,
                starts_at_s: 0.0,
                ends_at_s: 1_000.0,
                trust_boundary: "ops_review"
              },
              %{
                type: "resource_availability_constraint",
                spacecraft_id: "leo_1",
                resource_field: "payload_available",
                available: false,
                starts_at_s: 0.0,
                ends_at_s: 1_000.0,
                trust_boundary: "ops_review"
              },
              %{
                type: "resource_availability_constraint",
                spacecraft_id: "leo_1",
                antenna_status: "Outage",
                starts_at_s: 0.0,
                ends_at_s: 1_000.0,
                trust_boundary: "ops_review"
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    resource_branch = branch(artifact, "manual_resource")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             resource_branch["assumptions"]["candidate_source"]

    assert %{
             "type" => "candidate_refresh.v1",
             "operational_feedback_input_keys" => [
               "resource_availability_overrides",
               "resource_margin_overrides"
             ],
             "operational_feedback_trust_boundary_status" => "declared",
             "operational_feedback_trust_boundary" => "ops_review"
           } = resource_branch["repair_result"]["assumptions"]["candidate_source"]

    assert Enum.any?(
             resource_branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["power_margin"] == 0.05 and
                 &1["payload_available"] == false and
                 &1["antenna_available"] == false and
                 &1["source_quality"] == "operational_feedback" and
                 get_in(&1, ["provenance", "resource_feedback_source"]) ==
                   "operational_feedback" and
                 get_in(&1, ["provenance", "trust_boundary"]) == "ops_review")
           )

    assert %{
             "schema_contract" => "resource_projection_report.v1",
             "projected_resources" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "resource_pressure_status" => "resource_availability_pressure",
                 "resource_pressure_types" => pressure_types
               }
             ]
           } = resource_branch["resource_projection_report"]

    assert "payload_unavailable" in pressure_types
    assert "antenna_unavailable" in pressure_types

    resource_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "manual_resource"))

    assert resource_row["resource_projection_payload_unavailable_count"] == 1
    assert resource_row["resource_projection_payload_unavailable_spacecraft_ids"] == ["leo_1"]
    assert resource_row["resource_projection_antenna_unavailable_count"] == 1
    assert resource_row["resource_projection_antenna_unavailable_spacecraft_ids"] == ["leo_1"]

    assert resource_row["resource_projection_availability_pressure_types"] == [
             "antenna_unavailable",
             "payload_unavailable"
           ]

    assert %{"suppressed_candidate_count" => suppressed_count} =
             resource_branch["repair_result"]["source_resource_filter_report"]

    assert suppressed_count > 0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy generated refresh carries explicit degraded spacecraft events as availability feedback" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: false,
        branches: [
          %{id: "baseline"},
          %{
            id: "manual_degraded",
            events: [
              %{
                type: "degraded_spacecraft",
                scenario_id: :leo_1,
                mode: :safe,
                suppressed_activity_types: [:observe, :downlink],
                starts_at_s: 0.0,
                ends_at_s: 1_000.0,
                trust_boundary: "ops_review"
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    degraded_branch = branch(artifact, "manual_degraded")

    assert [
             %{
               "scenario_id" => "leo_1",
               "mode" => "safe",
               "incompatible_activity_types" => ["downlink", "observe"]
             }
           ] = degraded_branch["events"]

    refute Map.has_key?(List.first(degraded_branch["events"]), "suppressed_activity_types")

    assert %{
             "operational_feedback_input_keys" => ["resource_availability_overrides"],
             "operational_feedback_trust_boundary" => "ops_review"
           } = degraded_branch["repair_result"]["assumptions"]["candidate_source"]

    assert [
             %{
               "scenario_id" => "leo_1",
               "mode" => "safe",
               "incompatible_activity_types" => ["downlink", "observe"]
             }
           ] = degraded_branch["repair_result"]["realized_state_snapshot"]["spacecraft_states"]

    assert Enum.any?(
             degraded_branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["mode"] == "safe" and
                 &1["degraded"] == true and &1["payload_available"] == false and
                 &1["antenna_available"] == false and
                 get_in(&1, ["assumptions", "incompatible_activity_types"]) == [
                   "downlink",
                   "observe"
                 ] and
                 &1["source_quality"] == "operational_feedback")
           )

    assert %{"suppressed_candidate_count" => suppressed_count} =
             degraded_branch["repair_result"]["source_resource_filter_report"]

    assert suppressed_count > 0

    degraded_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "manual_degraded"))

    assert degraded_row["payload_availability"] == 0.0
    assert degraded_row["antenna_availability"] == 0.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives availability branch from operational feedback alias" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        operational_feedback: %OperationalFeedback{
          resource_availability_overrides: %{},
          availability_overrides: %{"leo_1" => %{payload_available: false}}
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    availability_branch = branch(artifact, "derived_resource_availability_feedback")

    assert %{
             "type" => "resource_availability_constraint",
             "spacecraft_id" => "leo_1",
             "resource_field" => "payload_available",
             "available" => false,
             "feedback_source" => "operational_feedback.resource_availability_overrides"
           } = List.first(availability_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             availability_branch["assumptions"]["candidate_source"]

    assert get_in(artifact, ["operational_feedback", "resource_availability_overrides"]) == %{
             "leo_1" => %{"payload_available" => false}
           }

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives availability branches from struct-style availability flags" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resources, %{payload_available?: false})

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        operational_feedback: %OperationalFeedback{
          resource_availability_overrides: %{"leo_1" => %{antenna_available?: false}}
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    payload_branch = branch(artifact, "derived_payload_constrained_leo_1")
    availability_branch = branch(artifact, "derived_resource_availability_feedback")

    assert %{
             "type" => "resource_availability_constraint",
             "spacecraft_id" => "leo_1",
             "resource_field" => "payload_available",
             "available" => false
           } = List.first(payload_branch["events"])

    assert %{
             "type" => "resource_availability_constraint",
             "spacecraft_id" => "leo_1",
             "resource_field" => "antenna_available",
             "available" => false,
             "feedback_source" => "operational_feedback.resource_availability_overrides"
           } = List.first(availability_branch["events"])

    assert Enum.any?(
             payload_branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["payload_available"] == false)
           )

    assert get_in(artifact, ["operational_feedback", "resource_availability_overrides"]) == %{
             "leo_1" => %{"antenna_available" => false}
           }

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "top-level operational feedback overrides mission-state embedded feedback" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:operational_feedback, %{
        station_throughput_factor: %{"equator_prime" => 0.4}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        operational_feedback: %{
          station_throughput_factor: %{"equator_prime" => 0.9}
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_station_throughput_feedback")

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 0.9
           }

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
