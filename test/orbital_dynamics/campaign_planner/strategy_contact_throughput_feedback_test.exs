Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyContactThroughputFeedbackTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy-derived refresh applies station throughput feedback to generated contacts" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        operational_feedback: %{
          station_throughput_factor: %{"equator_prime" => 0.5}
        },
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    downlink =
      artifact
      |> branch("urgent")
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert get_in(downlink, ["throughput_model", "station_capacity_fraction"]) == 0.5
    assert downlink["station_availability"] == "reduced_capacity"

    assert %{
             "schema_contract" => "contact_allocation_report.v1",
             "input_contact_count" => allocation_input_count,
             "allocated_contact_count" => allocated_count,
             "rows" => allocation_rows
           } =
             artifact
             |> branch("urgent")
             |> get_in(["repair_result", "source_contact_allocation_report"])

    assert allocation_input_count > 0
    assert allocated_count > 0

    assert %{
             "contact_id" => contact_id,
             "allocation_status" => "allocated",
             "station_availability" => "reduced_capacity"
           } = Enum.find(allocation_rows, &(&1["contact_id"] == downlink["id"]))

    assert contact_id == downlink["id"]

    assert %{
             "review_type" => "contact_allocation_review",
             "branch_id" => "urgent",
             "contact_id" => ^contact_id,
             "allocation_status" => "allocated",
             "source" =>
               "campaign_strategy.branches.repair_result.source_contact_allocation_report.rows"
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["contact_id"] == contact_id)
             )
  end

  test "strategy review includes repaired-activity same-spacecraft allocation with branch identity" do
    primary_contact = refreshed_downlink("dl_equator", 100.0, 220.0)

    overlapping_contact =
      "dl_dsn"
      |> refreshed_downlink(120.0, 240.0)
      |> Map.put("ground_station_id", "deep_space_net")
      |> Map.put("source_window_id", "window:leo_1:ground_station_access:deep_space_net:1")
      |> Map.put("source_window", %{
        "id" => "window:leo_1:ground_station_access:deep_space_net:1",
        "type" => "ground_station_access"
      })

    artifact =
      strategy(
        base_plan(%{
          "activities" => [primary_contact, overlapping_contact],
          "candidate_activities" => []
        }),
        mission_state: mission_state_with_refresh_inputs(),
        branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
        current_epoch_s: 0.0
      )

    baseline = branch(artifact, "baseline")

    assert %{
             "schema_contract" => "contact_allocation_report.v1",
             "source" => "campaign_repair.activities",
             "deferred_contact_count" => 1,
             "rows" => allocation_rows
           } = baseline["repair_result"]["contact_allocation_report"]

    assert %{
             "contact_id" => "dl_dsn",
             "spacecraft_id" => "leo_1",
             "allocation_status" => "deferred",
             "allocation_reason" => "same_spacecraft_contention",
             "selected_contact_id" => "dl_equator",
             "contention_group_id" => "spacecraft:leo_1:contention:1"
           } = Enum.find(allocation_rows, &(&1["contact_id"] == "dl_dsn"))

    assert %{
             "review_type" => "contact_allocation_review",
             "branch_id" => "baseline",
             "source" =>
               "campaign_strategy.branches.repair_result.contact_allocation_report.rows",
             "contact_id" => "dl_dsn",
             "allocation_reason" => "same_spacecraft_contention"
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "contact_allocation_review" and
                   &1["contact_id"] == "dl_dsn" and
                   &1["source"] ==
                     "campaign_strategy.branches.repair_result.contact_allocation_report.rows")
             )

    assert %{
             "import_action" => "review_contact_allocation",
             "source_review_type" => "contact_allocation_review",
             "branch_id" => "baseline",
             "contact_id" => "dl_dsn",
             "allocation_reason" => "same_spacecraft_contention"
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source_review_type"] == "contact_allocation_review" and
                   &1["contact_id"] == "dl_dsn" and &1["branch_id"] == "baseline")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives station throughput refresh branch from operational feedback" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        operational_feedback: %{
          station_throughput_factor: %{"equator_prime" => 0.5}
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    throughput_branch = branch(artifact, "derived_station_throughput_feedback")

    assert %{
             "type" => "station_throughput_feedback",
             "ground_station_id" => "equator_prime",
             "station_throughput_factor" => 0.5,
             "feedback_source" => "operational_feedback.station_throughput_factor"
           } = List.first(throughput_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             throughput_branch["assumptions"]["candidate_source"]

    downlink =
      throughput_branch
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert get_in(downlink, ["throughput_model", "station_capacity_fraction"]) == 0.5
    assert downlink["station_availability"] == "reduced_capacity"

    assert Enum.any?(
             throughput_branch["risk_indicators"],
             &(&1["type"] == "station_throughput_factor_low" and &1["value"] == 0.5)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy normalizes numeric-string feedback branch thresholds" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        operational_feedback: %{
          station_throughput_factor: %{"equator_prime" => "0.5"},
          downlink_demand_mb: %{"equator_prime" => "15.0"}
        },
        branch_generation_policy: %{
          station_throughput_feedback_threshold: "0.8",
          downlink_demand_feedback_threshold_mb: "20.0"
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    throughput_branch = branch(artifact, "derived_station_throughput_feedback")

    assert %{
             "type" => "station_throughput_feedback",
             "ground_station_id" => "equator_prime",
             "station_throughput_factor" => 0.5
           } = List.first(throughput_branch["events"])

    refute branch(artifact, "derived_downlink_demand_feedback")

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "equator_prime" => 15.0
           }

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
