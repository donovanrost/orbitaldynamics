Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairDeterminismTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CampaignPlanner
  alias OrbitalDynamics.CampaignPlanner.ReplanRequest
  alias OrbitalDynamics.Schema

  test "repair artifacts are reproducible with fixed inputs and generated_at" do
    request = %ReplanRequest{
      prior_plan:
        base_plan(%{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [downlink("dl_2", 700.0, 760.0)]
        }),
      realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
      current_epoch_s: 165.0,
      generated_at: ~U[2026-05-13 12:00:00Z]
    }

    left = CampaignPlanner.repair(request)
    right = CampaignPlanner.repair(request)

    annotated =
      CampaignPlanner.repair(%{
        request
        | realized_state: %{
            activities: [%{id: "dl_1", status: "missed"}],
            model_limits: ["operator_declared_feedback_snapshot_boundary"]
          }
      })

    assert left == right
    assert left["schema_version"] == 2
    assert left["source_plan_id"] == "campaign_plan:test:2026-05-13T00:00:00Z"
    assert annotated["repair_metadata"]["repair_id"] == left["repair_metadata"]["repair_id"]

    assert annotated["realized_state_snapshot"]["model_limits"] == [
             "operator_declared_feedback_snapshot_boundary"
           ]

    assert left["realized_state_snapshot"]["activities"] == [
             %{
               "schema_contract" => "realized_activity.v1",
               "id" => "dl_1",
               "metadata" => %{},
               "status" => "missed"
             }
           ]

    assert left["realized_state_snapshot"]["schema_contract"] == "realized_state_snapshot.v1"

    assert left["realized_state_snapshot"]["model_limits"] == [
             "provider_feedback_snapshot_only",
             "no_ground_truth_reconstruction",
             "no_schedule_mutation",
             "no_subsystem_state_estimation"
           ]

    assert is_binary(left["repair_metadata"]["repair_id"])
    assert left["assumptions"]["repair_model"] == "prior_candidate_windows_greedy_repair"
    assert left["scoring_policy"]["schedule_churn_cost_weight"] == 100.0
  end

  test "repair normalizes realized spacecraft states to schema-valid scenario identities" do
    artifact =
      repair(
        %{
          "activities" => [
            observe("obs_degraded", "leo_1", "target_a", 200.0, 260.0, 100.0)
          ],
          "candidate_activities" => []
        },
        realized_state: %{
          spacecraft_states: [
            %{mode: "degraded", incompatible_activity_types: ["observe"]},
            %{id: "leo 2", mode: "degraded", incompatible_activity_types: ["observe"]},
            %{
              id: "leo_1",
              mode: "degraded",
              degraded: true,
              payload_available: false,
              antenna_available: true,
              incompatible_activity_types: ["observe"],
              source: "operator_realized_state"
            }
          ]
        },
        current_epoch_s: 100.0
      )

    assert [
             %{
               "scenario_id" => "leo_1",
               "mode" => "degraded",
               "degraded" => true,
               "payload_available" => false,
               "antenna_available" => true,
               "incompatible_activity_types" => ["observe"],
               "source" => "operator_realized_state"
             }
           ] = artifact["realized_state_snapshot"]["spacecraft_states"]

    assert artifact["realized_state_snapshot"]["metadata"][
             "dropped_identityless_spacecraft_state_count"
           ] == 1

    assert artifact["realized_state_snapshot"]["metadata"][
             "dropped_invalid_spacecraft_state_count"
           ] == 1

    assert [%{"activity_id" => "obs_degraded", "repair_action" => "suppressed"}] =
             Enum.filter(artifact["deltas"], &(&1["activity_id"] == "obs_degraded"))

    assert {:ok, %{"schema_contract" => "campaign_repair.v2", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair generated IDs and ordering are stable across input row permutations" do
    activities = [
      downlink("dl_1", 100.0, 160.0),
      observe("obs_1", "leo_1", "target_a", 250.0, 310.0, 10.0)
    ]

    candidates = [
      downlink("dl_2", 700.0, 760.0),
      observe("obs_2", "leo_1", "target_a", 800.0, 860.0, 12.0)
    ]

    realized_activities = [
      %{id: "obs_1", status: "failed"},
      %{id: "dl_1", status: "missed"}
    ]

    request_for = fn activities, candidates, realized_activities ->
      %ReplanRequest{
        prior_plan:
          base_plan(%{
            "activities" => activities,
            "candidate_activities" => candidates
          }),
        realized_state: %{activities: realized_activities},
        current_epoch_s: 165.0,
        generated_at: ~U[2026-05-13 12:00:00Z]
      }
    end

    left = CampaignPlanner.repair(request_for.(activities, candidates, realized_activities))

    right =
      CampaignPlanner.repair(
        request_for.(
          Enum.reverse(activities),
          Enum.reverse(candidates),
          Enum.reverse(realized_activities)
        )
      )

    assert right == left

    assert Enum.map(left["source_candidate_activities"], & &1["id"]) == [
             "dl_2",
             "obs_2"
           ]

    assert Enum.map(left["deltas"], & &1["activity_id"]) == ["dl_1", "obs_1"]
  end
end
