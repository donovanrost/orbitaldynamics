Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyDownlinkRefreshTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy stages downlink completion from branch-generated refresh candidates" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:objectives, [
        %{type: "downlink_completion", required_contacts: 1}
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert [
             %{
               "type" => "downlink",
               "ground_station_id" => "equator_prime",
               "repair" => %{
                 "action" => "strategic_addition",
                 "reason" => "downlink_completion_candidate_inserted",
                 "requires_approval" => true
               },
               "feasibility" => %{
                 "status" => "validated_candidate_window",
                 "ground_station_id" => "equator_prime",
                 "source_window" => %{"type" => "ground_station_access"}
               }
             }
           ] = downlink_branch["candidate_plan"]["strategic_additions"]

    assert get_in(downlink_branch, [
             "objective_satisfaction",
             "downlink_completion",
             "ratio"
           ]) == 1.0

    assert Enum.any?(
             downlink_branch["approval_requirements"],
             &(&1["activity_type"] == "downlink" and
                 &1["action"] == "approve_strategic_addition")
           )
  end

  test "strategy derives downlink refresh when realized feedback misses a planned contact" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{id: "dl_late", status: "missed"}
      ])

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
        "activities" => [downlink("dl_late", 500.0, 560.0)]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert %{
             "type" => "downlink_completion_gap",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "source_activity_id" => "dl_late",
             "realized_status" => "missed",
             "derivation_reasons" => [
               "downlink_completion_gap",
               "realized_downlink_missed"
             ]
           } = List.first(downlink_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             downlink_branch["assumptions"]["candidate_source"]

    assert Enum.any?(
             downlink_branch["repair_result"]["deltas"],
             &(&1["activity_id"] == "dl_late" and &1["repair_action"] == "moved")
           )

    assert Enum.any?(
             downlink_branch["repair_result"]["source_candidate_activities"],
             &(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives downlink refresh when direct realized status records provider failure" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{id: "dl_late", status: "matched", realized_status: "failed"}
      ])

    artifact =
      strategy(
        base_plan(%{
          "activities" => [downlink("dl_late", 500.0, 560.0)]
        }),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [
          %{id: "baseline"},
          %{id: "manual", events: [%{type: "fuel_preservation_mode"}]}
        ],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert [
             %{
               "id" => "dl_late",
               "status" => "failed",
               "feedback_status" => "matched",
               "realized_status" => "failed"
             }
           ] = get_in(artifact, ["mission_state_snapshot", "realized_activities"])

    assert %{
             "type" => "downlink_completion_gap",
             "source_activity_id" => "dl_late",
             "realized_status" => "failed",
             "derivation_reasons" => [
               "downlink_completion_gap",
               "realized_downlink_failed"
             ]
           } = List.first(downlink_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy does not derive downlink refresh for completed contact feedback" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{id: "dl_late", status: "completed"}
      ])

    artifact =
      strategy(
        base_plan(%{
          "activities" => [downlink("dl_late", 500.0, 560.0)]
        }),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [
          %{id: "baseline"},
          %{id: "manual", events: [%{type: "fuel_preservation_mode"}]}
        ],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_downlink_constrained")
  end

  test "strategy derives downlink refresh from provider contact result failure aliases" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{id: "dl_late", status: "completed", contact_result: ["accepted", "dropped"]}
      ])

    artifact =
      strategy(
        base_plan(%{
          "activities" => [downlink("dl_late", 500.0, 560.0)]
        }),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [
          %{id: "baseline"},
          %{id: "manual", events: [%{type: "fuel_preservation_mode"}]}
        ],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert %{
             "type" => "downlink_completion_gap",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "source_activity_id" => "dl_late",
             "realized_status" => "completed",
             "contact_result" => "accepted,dropped",
             "derivation_reasons" => [
               "downlink_completion_gap",
               "realized_downlink_completed",
               "realized_downlink_contact_result_accepted",
               "realized_downlink_contact_result_dropped"
             ]
           } = List.first(downlink_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             downlink_branch["assumptions"]["candidate_source"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy branch-generated refresh compares result-artifact prior candidates" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{id: "dl_late", status: "completed", contact_result: ["accepted", "dropped"]}
      ])

    prior_plan =
      base_plan(%{
        "activities" => [downlink("dl_late", 500.0, 560.0)],
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "metadata" => %{"trust_boundary" => "ops_candidate_result_artifact"},
          "candidate_activities" => [refreshed_downlink("dl_prior_from_result", 700.0, 760.0)]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [
          %{id: "baseline"},
          %{id: "manual", events: [%{type: "fuel_preservation_mode"}]}
        ],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert %{
             "prior_candidate_count" => 1,
             "invalidated_candidate_count" => invalidated_count
           } = downlink_branch["repair_result"]["source_candidate_diff_report"]

    assert invalidated_count >= 1

    refute "no prior candidates compared" in downlink_branch["repair_result"]["warnings"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy does not derive downlink refresh when provider contact result is successful" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{id: "dl_late", status: "failed", contact_result: "delivered"}
      ])

    artifact =
      strategy(
        base_plan(%{
          "activities" => [
            downlink("dl_late", 500.0, 560.0)
            |> Map.put("required_downlink_mb", 360.0)
          ]
        }),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [
          %{id: "baseline"},
          %{id: "manual", events: [%{type: "fuel_preservation_mode"}]}
        ],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 1.0
           }

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{}
    refute branch(artifact, "derived_downlink_constrained")
    refute branch(artifact, "derived_downlink_demand_feedback")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy downlink refresh normalizes provider contact result aliases" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{id: "dl_late", status: "failed", contact_result: "accepted, DELIVERED"}
      ])

    artifact =
      strategy(
        base_plan(%{
          "activities" => [
            downlink("dl_late", 500.0, 560.0)
            |> Map.put("required_downlink_mb", 360.0)
          ]
        }),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [
          %{id: "baseline"},
          %{id: "manual", events: [%{type: "fuel_preservation_mode"}]}
        ],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 1.0
           }

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{}
    refute branch(artifact, "derived_downlink_constrained")
    refute branch(artifact, "derived_downlink_demand_feedback")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
