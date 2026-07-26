Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairExecutionPolicyTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "repair reassigns a failed observation to a viable spacecraft and charges churn" do
    artifact =
      repair(
        %{
          "activities" => [observe("obs_1", "leo_1", "target_a", 200.0, 260.0, 200.0)],
          "candidate_activities" => [
            observe("obs_1", "leo_1", "target_a", 200.0, 260.0, 200.0),
            observe("obs_2", "leo_2", "target_a", 220.0, 280.0, 150.0),
            observe("obs_3", "leo_1", "target_a", 800.0, 860.0, 180.0)
          ]
        },
        realized_state: %{activities: [%{id: "obs_1", status: "failed"}]},
        current_epoch_s: 180.0,
        scoring_policy: %{"schedule_move_cost_weight" => 1.0}
      )

    assert [%{"id" => "obs_2", "scenario_id" => "leo_2", "repair" => repair}] =
             artifact["activities"]

    assert repair["action"] == "replaced"
    assert artifact["score_terms"]["schedule_churn_penalty"] < 0.0
    assert artifact["score_terms"]["schedule_move_penalty"] < 0.0

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    wrong_target =
      update_in(artifact, ["source_candidate_activities"], fn candidates ->
        Enum.map(candidates, fn
          %{"id" => "obs_3"} = candidate -> Map.put(candidate, "target_id", "target_b")
          candidate -> candidate
        end)
      end)

    assert {:error, report} = Schema.validate_artifact(wrong_target)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] ==
                 "$.activities[0].repair.replacement_ranking.rows[1].candidate_id")
           )

    legacy_wrong_target =
      update_in(
        wrong_target,
        ["activities", Access.at(0), "repair", "replacement_ranking", "rows"],
        fn rows ->
          Enum.map(rows, fn row ->
            Map.drop(row, [
              "contact_intent_pressure_penalty",
              "contact_contention_resolution_pressure_penalty"
            ])
          end)
        end
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(legacy_wrong_target)
  end

  test "repair does not reuse a future selected activity as a replacement candidate" do
    artifact =
      repair(
        %{
          "activities" => [
            downlink("dl_1", 100.0, 160.0),
            downlink("dl_2", 700.0, 760.0)
          ],
          "candidate_activities" => [
            downlink("dl_1", 100.0, 160.0),
            downlink("dl_2", 700.0, 760.0),
            downlink("dl_3", 800.0, 860.0)
          ]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0
      )

    repaired_ids = Enum.map(artifact["activities"], & &1["id"])

    assert Enum.sort(repaired_ids) == ["dl_2", "dl_3"]
    assert Enum.frequencies(repaired_ids) == %{"dl_2" => 1, "dl_3" => 1}

    assert [
             %{
               "activity_id" => "dl_1",
               "repair_action" => "moved",
               "replacement_activity_id" => "dl_3"
             }
           ] = Enum.filter(artifact["deltas"], &(&1["activity_id"] == "dl_1"))
  end

  test "repair move scoring honors schedule_move_cost_weight from repair policy" do
    artifact =
      repair(
        %{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [
            downlink("dl_1", 100.0, 160.0),
            refreshed_downlink("dl_2", 200.0, 260.0)
          ],
          "ranking_explanation" => %{
            "policy" => %{
              "contact_value_weight" => 0.2,
              "schedule_churn_cost_weight" => 100.0
            }
          }
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0,
        repair_policy: %{"schedule_move_cost_weight" => 2.0}
      )

    assert artifact["scoring_policy"]["schedule_move_cost_weight"] == 2.0
    assert artifact["score_terms"]["schedule_move_penalty"] == -200.0

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    invalid_ranking =
      update_in(
        artifact,
        ["activities", Access.at(0), "repair", "replacement_ranking", "rows", Access.at(0)],
        fn row ->
          row
          |> Map.put("schedule_move_penalty", -100.0)
          |> Map.update!("ranking_score", &(&1 + 100.0))
        end
      )

    assert {:error, report} = Schema.validate_artifact(invalid_ranking)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] ==
                 "$.activities[0].repair.replacement_ranking.rows[0].schedule_move_penalty")
           )
  end

  test "repair marks downstream activities affected by a delayed maneuver" do
    artifact =
      repair(
        %{
          "activities" => [
            maneuver("burn_1", 300.0),
            observe("obs_after_burn", "leo_1", "target_b", 350.0, 420.0, 100.0)
          ],
          "candidate_activities" => []
        },
        realized_state: %{
          activities: [
            %{
              id: "burn_1",
              status: "delayed",
              actual_starts_at_s: 360.0,
              actual_ends_at_s: 360.0
            }
          ]
        },
        current_epoch_s: 320.0
      )

    assert [
             %{
               "id" => "burn_1",
               "starts_at_s" => 360.0,
               "ends_at_s" => 390.0,
               "repair" => %{
                 "action" => "moved",
                 "realized_status" => "delayed",
                 "schedule_churn_s" => 60.0,
                 "requires_approval" => true
               }
             },
             %{"id" => "obs_after_burn", "repair" => downstream}
           ] =
             Enum.sort_by(artifact["activities"], & &1["id"])

    assert downstream["affected_by_delayed_maneuver"]

    assert [
             %{
               "activity_id" => "burn_1",
               "status" => "delayed",
               "repair_action" => "moved",
               "replacement_activity_id" => "burn_1",
               "requires_approval" => true
             }
           ] = Enum.filter(artifact["deltas"], &(&1["activity_id"] == "burn_1"))

    assert Enum.any?(
             artifact["approval_requirements"],
             &(&1["activity_id"] == "burn_1" and
                 &1["action"] == "approve_delayed_maneuver")
           )

    assert Enum.any?(
             artifact["approval_requirements"],
             &(&1["action"] == "review_downstream_window")
           )

    assert Enum.any?(artifact["warnings"], &String.contains?(&1, "affected by delayed maneuver"))
  end

  test "repair requires a numeric actual start for a delayed maneuver" do
    assert_raise ArgumentError, "actual_starts_at_s must be numeric", fn ->
      repair(
        %{
          "activities" => [maneuver("burn_1", 300.0)],
          "candidate_activities" => []
        },
        realized_state: %{activities: [%{id: "burn_1", status: "delayed"}]},
        current_epoch_s: 320.0
      )
    end
  end

  test "repair suppresses degraded spacecraft payload activities and preserves health checks" do
    locked_observation =
      "obs_locked_degraded"
      |> observe("leo_1", "target_a", 270.0, 330.0, 100.0)
      |> Map.put("metadata", %{"approval_status" => "approved", "locked" => true})

    artifact =
      repair(
        %{
          "activities" => [
            observe("obs_degraded", "leo_1", "target_a", 200.0, 260.0, 100.0),
            locked_observation,
            health_check("health_1", "leo_1", 210.0, 230.0)
          ],
          "candidate_activities" => []
        },
        realized_state: %{
          spacecraft_states: [
            %{
              scenario_id: "leo_1",
              mode: "degraded",
              incompatible_activity_types: ["observe"]
            }
          ]
        },
        current_epoch_s: 100.0
      )

    assert [%{"id" => "health_1", "repair" => %{"action" => "preserved"}}] =
             Enum.filter(artifact["activities"], &(&1["id"] == "health_1"))

    assert [
             %{
               "id" => "obs_locked_degraded",
               "repair" => %{"action" => "preserved", "reason" => "activity_locked_or_approved"}
             }
           ] = Enum.filter(artifact["activities"], &(&1["id"] == "obs_locked_degraded"))

    assert [%{"activity_id" => "obs_degraded", "repair_action" => "suppressed"}] =
             artifact["deltas"]
             |> Enum.filter(&(&1["activity_id"] == "obs_degraded"))

    refute Enum.any?(
             artifact["deltas"],
             &(&1["activity_id"] == "obs_locked_degraded" and &1["repair_action"] == "suppressed")
           )
  end

  test "repair normalizes string true for degraded spacecraft suppression" do
    artifact =
      repair(
        %{
          "activities" => [observe("obs_degraded", "leo_1", "target_a", 200.0, 260.0, 100.0)],
          "candidate_activities" => []
        },
        realized_state: %{
          spacecraft_states: [
            %{
              scenario_id: "leo_1",
              degraded: "true",
              incompatible_activity_types: ["observe"]
            }
          ]
        },
        current_epoch_s: 100.0
      )

    assert [%{"activity_id" => "obs_degraded", "repair_action" => "suppressed"}] =
             artifact["deltas"]
             |> Enum.filter(&(&1["activity_id"] == "obs_degraded"))

    assert {:ok, %{"schema_contract" => "campaign_repair.v2", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair uses policy command and health exemptions for degraded spacecraft" do
    safe_mode_check = %{
      "id" => "safe_check_1",
      "type" => "safe_mode_check",
      "scenario_id" => "leo_1",
      "starts_at_s" => 210.0,
      "ends_at_s" => 230.0,
      "duration_s" => 20.0,
      "score" => 1.0
    }

    artifact =
      repair(
        %{"activities" => [safe_mode_check], "candidate_activities" => []},
        realized_state: %{
          spacecraft_states: [
            %{
              scenario_id: "leo_1",
              mode: "degraded",
              incompatible_activity_types: ["safe_mode_check"]
            }
          ]
        },
        current_epoch_s: 100.0,
        repair_policy: %{"command_health_activity_types" => ["safe_mode_check"]}
      )

    assert [%{"id" => "safe_check_1", "repair" => %{"action" => "preserved"}}] =
             artifact["activities"]

    refute Enum.any?(artifact["deltas"], &(&1["repair_action"] == "suppressed"))
  end
end
