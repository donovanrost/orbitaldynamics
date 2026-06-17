Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyObservationDemandFeedbackTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives downlink demand refresh branch from mission-state observation data volume" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "obs_target_a",
          type: "observe",
          target_id: "target_a",
          status: "completed",
          actual_data_volume_mb: 180.0
        },
        %{
          id: "obs_target_a_partial",
          type: "observe",
          target_id: "target_a",
          status: "partial",
          planned_data_volume_mb: 80.0,
          completed_fraction: 0.5
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "default" => 220.0
           }

    demand_branch = branch(artifact, "derived_downlink_demand_feedback")

    assert %{
             "type" => "downlink_demand_feedback",
             "required_downlink_mb" => 220.0,
             "feedback_scope" => "default",
             "feedback_source" => "operational_feedback.downlink_demand_mb"
           } = List.first(demand_branch["events"])

    downlink =
      demand_branch
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert downlink["required_downlink_mb"] == 220.0

    assert downlink["downlink_completion_source"] ==
             "operational_feedback.downlink_demand_mb.default"

    assert "downlink_demand_mb" in artifact["operational_feedback_provenance"][
             "input_keys"
           ]

    assert "downlink_demand_sources" in artifact["operational_feedback_provenance"][
             "input_keys"
           ]

    assert %{
             "source" => "mission_state.realized_activities",
             "input_keys" => [
               "downlink_demand_mb",
               "downlink_demand_sources",
               "observation_success_rate"
             ],
             "realized_activity_count" => 2
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] == "mission_state.realized_activities")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives observation demand and priority from delayed telemetry without observation success" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "obs_delayed",
          type: "observe",
          target_id: "target_a",
          status: "delayed",
          actual_data_volume_mb: 180.0,
          target_priority: 12.0
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "observation_success_rate"]) == %{}

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "default" => 180.0
           }

    assert get_in(artifact, ["operational_feedback", "target_priority_overrides"]) == %{
             "target_a" => 12.0
           }

    assert branch(artifact, "derived_downlink_demand_feedback")
    assert branch(artifact, "derived_target_priority_feedback")
    refute branch(artifact, "derived_observation_success_feedback")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives observation downlink demand from realized data-volume aliases" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "obs_delivered_alias",
          type: "observe",
          target_id: "target_a",
          status: "completed",
          delivered_data_mb: 90.0
        },
        %{
          id: "obs_planned_alias",
          type: "observe",
          target_id: "target_a",
          status: "partial",
          data_volume_mb: 60.0,
          completed_fraction: 0.5
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "default" => 120.0
           }

    assert "mission_state.realized_activities.observation.required_downlink_mb:obs_delivered_alias" in get_in(
             artifact,
             ["operational_feedback", "downlink_demand_sources", "default"]
           )

    demand_branch = branch(artifact, "derived_downlink_demand_feedback")

    assert %{
             "type" => "downlink_demand_feedback",
             "required_downlink_mb" => 120.0,
             "feedback_scope" => "default",
             "downlink_demand_sources" => [
               "mission_state.realized_activities.observation.required_downlink_mb:obs_delivered_alias",
               "mission_state.realized_activities.observation.required_downlink_mb:obs_planned_alias"
             ]
           } = List.first(demand_branch["events"])

    assert %{
             "source" => "mission_state.realized_activities",
             "input_keys" => [
               "downlink_demand_mb",
               "downlink_demand_sources",
               "observation_success_rate"
             ],
             "realized_activity_count" => 2
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] == "mission_state.realized_activities")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy keeps realized telemetry provenance keys separate from embedded mission feedback" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "obs_target_a",
          type: "observe",
          target_id: "target_a",
          status: "completed",
          actual_data_volume_mb: 180.0
        }
      ])
      |> Map.put(:operational_feedback, %{
        station_throughput_factor: %{"equator_prime" => 0.5}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "default" => 180.0
           }

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 0.5
           }

    assert %{
             "source" => "mission_state.realized_activities",
             "input_keys" => [
               "downlink_demand_mb",
               "downlink_demand_sources",
               "observation_success_rate"
             ]
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] == "mission_state.realized_activities")
             )

    assert %{
             "source" => "mission_state.operational_feedback",
             "input_keys" => ["station_throughput_factor"]
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] == "mission_state.operational_feedback")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives refresh branches from mission-state embedded operational feedback" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:operational_feedback, %{
        station_throughput_factor: %{"equator_prime" => 0.5},
        resource_availability_overrides: %{"leo_1" => %{payload_available: " FALSE "}}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    throughput_branch = branch(artifact, "derived_station_throughput_feedback")
    availability_branch = branch(artifact, "derived_resource_availability_feedback")

    assert %{
             "type" => "station_throughput_feedback",
             "ground_station_id" => "equator_prime",
             "station_throughput_factor" => 0.5
           } = List.first(throughput_branch["events"])

    assert %{
             "type" => "resource_availability_constraint",
             "spacecraft_id" => "leo_1",
             "resource_field" => "payload_available",
             "available" => false
           } = List.first(availability_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             throughput_branch["assumptions"]["candidate_source"]

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             availability_branch["assumptions"]["candidate_source"]

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 0.5
           }

    assert get_in(artifact, ["operational_feedback", "resource_availability_overrides"]) == %{
             "leo_1" => %{"payload_available" => false}
           }

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
