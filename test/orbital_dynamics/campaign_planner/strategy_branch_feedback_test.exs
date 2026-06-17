Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyBranchFeedbackTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy preserves branch-event conflicts with realized feedback for review" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_500.0},
        "activities" => [refreshed_downlink("dl_1", 100.0, 160.0)],
        "candidate_activities" => [refreshed_downlink("dl_2", 700.0, 760.0)]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:realized_activities, [
            %{id: "dl_1", status: "completed", completed_fraction: 1.0}
          ]),
        branches: [
          %{id: "baseline"},
          %{
            id: "outage",
            events: [
              %{
                type: "ground_station_outage",
                ground_station_id: "equator_prime",
                starts_at_s: 90.0,
                ends_at_s: 200.0
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    assert [
             %{
               "activity_id" => "dl_1",
               "repair_action" => "review_realized_feedback",
               "status" => "ambiguous_realized_feedback",
               "realized_feedback_count" => 2,
               "realized_feedback_rows" => [
                 %{"id" => "dl_1", "status" => "completed"},
                 %{
                   "id" => "dl_1",
                   "status" => "missed",
                   "reason" => "branch_ground_station_outage"
                 }
               ]
             }
           ] =
             branch(artifact, "outage")["repair_result"]["deltas"]
             |> Enum.filter(&(&1["activity_id"] == "dl_1"))

    refute Enum.any?(
             branch(artifact, "outage")["repair_result"]["activities"],
             &(&1["id"] == "dl_2")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy branch station outages affect tracking and health-check station activities" do
    tracking_activity = %{
      "id" => "tracking_1",
      "type" => "tracking",
      "scenario_id" => "leo_1",
      "ground_station_id" => "equator_prime",
      "starts_at_s" => 100.0,
      "ends_at_s" => 140.0,
      "duration_s" => 40.0,
      "score" => 2.0
    }

    health_activity =
      "health_1"
      |> health_check("leo_1", 150.0, 180.0)
      |> Map.put("ground_station_id", "equator_prime")

    command_activity = %{
      "id" => "command_1",
      "type" => "command",
      "scenario_id" => "leo_1",
      "ground_station_id" => "equator_prime",
      "starts_at_s" => 110.0,
      "ends_at_s" => 130.0,
      "duration_s" => 20.0,
      "score" => 1.0
    }

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_500.0},
        "activities" => [tracking_activity, health_activity, command_activity],
        "candidate_activities" => [
          Map.put(tracking_activity, "id", "tracking_candidate"),
          Map.put(health_activity, "id", "health_candidate"),
          Map.put(command_activity, "id", "command_candidate")
        ]
      })

    artifact =
      strategy(prior_plan,
        branches: [
          %{id: "baseline"},
          %{
            id: "outage",
            events: [
              %{
                type: "ground_station_outage",
                ground_station_id: "equator_prime",
                starts_at_s: 90.0,
                ends_at_s: 200.0
              }
            ]
          },
          %{
            id: "reserved",
            events: [
              %{
                type: "ground_station_reserved",
                ground_station_id: "equator_prime",
                starts_at_s: 90.0,
                ends_at_s: 200.0,
                reservation_id: "reservation_tracking_health",
                reserved_by: "ops_team_b",
                reservation_status: "confirmed"
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    outage = branch(artifact, "outage")
    reserved = branch(artifact, "reserved")

    assert outage["repair_result"]["source_timeline_feedback_report"]["rows"]
           |> Enum.filter(&(&1["realized_status"] == "missed"))
           |> Enum.map(
             &{&1["activity_id"], &1["realized_status"], &1["feedback_kind"],
              &1["ground_station_id"], &1["station_availability"]}
           )
           |> Enum.sort() == [
             {"health_1", "missed", "health_check", "equator_prime", "unavailable"},
             {"tracking_1", "missed", "contact", "equator_prime", "unavailable"}
           ]

    source_candidate_ids =
      outage["repair_result"]["source_candidate_activities"]
      |> Enum.map(& &1["id"])

    refute "tracking_candidate" in source_candidate_ids
    refute "health_candidate" in source_candidate_ids
    assert "command_candidate" in source_candidate_ids

    reserved_feedback_row =
      reserved["repair_result"]["source_timeline_feedback_report"]["rows"]
      |> Enum.find(&(&1["activity_id"] == "tracking_1"))

    assert %{
             "activity_id" => "tracking_1",
             "realized_status" => "missed",
             "station_availability" => "reserved",
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "reservation_tracking_health",
             "station_reserved_by" => "ops_team_b",
             "station_reservation_status" => "confirmed"
           } = reserved_feedback_row

    assert %{
             "branch_id" => "reserved",
             "review_type" => "realized_feedback",
             "activity_id" => "tracking_1",
             "station_availability" => "reserved",
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "reservation_tracking_health",
             "station_reserved_by" => "ops_team_b",
             "station_reservation_status" => "confirmed",
             "source_feedback" => %{
               "station_reservation_id" => "reservation_tracking_health"
             }
           } =
             artifact["operator_review_package"]["rows"]
             |> Enum.find(
               &(&1["branch_id"] == "reserved" and
                   &1["review_type"] == "realized_feedback" and
                   &1["activity_id"] == "tracking_1")
             )

    assert %{
             "branch_id" => "reserved",
             "source_review_type" => "realized_feedback",
             "import_action" => "review_realized_feedback",
             "activity_id" => "tracking_1",
             "station_availability" => "reserved",
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "reservation_tracking_health",
             "station_reserved_by" => "ops_team_b",
             "station_reservation_status" => "confirmed",
             "source_feedback" => %{
               "station_reservation_id" => "reservation_tracking_health"
             }
           } =
             artifact["cadence_import_manifest"]["rows"]
             |> Enum.find(
               &(&1["branch_id"] == "reserved" and
                   &1["source_review_type"] == "realized_feedback" and
                   &1["activity_id"] == "tracking_1")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
