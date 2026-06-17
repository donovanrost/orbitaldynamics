Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyPriorityCommitmentRefreshTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives refresh branches for normal priority commitments" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:objectives, [
        %{
          type: "priority_commitment",
          target_id: "target_a",
          priority: 1.0,
          candidate_windows: [
            %{
              id: "priority_window_a",
              scenario_id: "leo_1",
              starts_at_s: 300.0,
              ends_at_s: 360.0
            }
          ]
        }
      ])

    artifact =
      strategy(base_plan(%{"activities" => [downlink("dl_1", 100.0, 160.0)]}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    commitment = branch(artifact, "derived_urgent_target_target_a")

    assert %{
             "type" => "candidate_refresh.v1",
             "scope" => "branch_generated"
           } = commitment["assumptions"]["candidate_source"]

    assert Enum.any?(
             commitment["repair_result"]["source_candidate_activities"],
             &(&1["type"] == "observe" and &1["target_id"] == "target_a")
           )

    assert Enum.any?(
             commitment["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "observe" and
                 &1["target_id"] == "target_a" and
                 get_in(&1, ["repair", "reason"]) == "priority_commitment_candidate_inserted")
           )
  end

  test "strategy priority commitments count required observations in comparison and review rows" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:objectives, [
        %{
          type: "priority_commitment",
          id: "commitment_target_a_twice",
          target_id: "target_a",
          required_count: 2,
          priority: 1.0,
          candidate_windows: [
            %{
              id: "priority_window_a_second",
              scenario_id: "leo_1",
              starts_at_s: 300.0,
              ends_at_s: 360.0
            }
          ]
        }
      ])

    artifact =
      strategy(
        base_plan(%{
          "activities" => [observe("obs_existing", "leo_1", "target_a", 100.0, 160.0, 10.0)]
        }),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    commitment = branch(artifact, "derived_urgent_target_target_a")

    assert %{
             "required_observations" => 2,
             "planned_observations" => 1,
             "objective_type" => "priority_commitment"
           } = List.first(commitment["events"])

    assert [
             %{
               "type" => "observe",
               "target_id" => "target_a",
               "repair" => %{"reason" => "priority_commitment_candidate_inserted"}
             }
           ] = commitment["candidate_plan"]["strategic_additions"]

    baseline_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "baseline"))

    assert %{
             "priority_commitment_required_target_count" => 1,
             "priority_commitment_satisfied_target_count" => 0,
             "priority_commitment_missed_target_count" => 1,
             "priority_commitment_required_target_ids" => ["target_a"],
             "priority_commitment_missed_target_ids" => ["target_a"],
             "priority_commitment_required_observation_count" => 2,
             "priority_commitment_planned_observation_count" => 1,
             "priority_commitment_missing_observation_count" => 1,
             "priority_commitment_ratio" => 0.5
           } = baseline_row

    derived_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_urgent_target_target_a"))

    assert %{
             "priority_commitment_satisfied_target_ids" => ["target_a"],
             "priority_commitment_required_observation_count" => 2,
             "priority_commitment_planned_observation_count" => 2,
             "priority_commitment_missing_observation_count" => 0,
             "priority_commitment_ratio" => 1.0
           } = derived_row

    assert get_in(baseline_row, ["score_terms", "priority_commitment_score"]) == 25.0
    assert get_in(derived_row, ["score_terms", "priority_commitment_score"]) == 50.0

    assert %{
             "priority_commitment_required_observation_count" => 2,
             "priority_commitment_missing_observation_count" => 1,
             "priority_commitment_ratio" => 0.5
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "strategy_tradeoff" and &1["branch_id"] == "baseline" and
                   &1["source"] == "campaign_strategy.branch_comparison_report.rows")
             )

    assert %{
             "priority_commitment_required_observation_count" => 2,
             "priority_commitment_missing_observation_count" => 1,
             "priority_commitment_ratio" => 0.5
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source_review_type"] == "strategy_branch_comparison" and
                   &1["branch_id"] == "baseline")
             )

    assert Enum.any?(
             artifact["recommendation"]["risks_remaining"],
             &(&1["type"] == "priority_commitment_unmet" and
                 &1["target_id"] == "target_a" and
                 &1["required_observations"] == 2 and
                 &1["planned_observations"] == 1 and
                 &1["missing_observations"] == 1)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy priority commitments honor explicit target selector lists" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.update!(:targets, fn targets ->
        targets ++
          [
            %{
              id: "target_b",
              latitude_deg: 5.0,
              longitude_deg: 5.0,
              minimum_elevation_deg: 10.0,
              priority: 2.0
            }
          ]
      end)
      |> Map.put(:objectives, [
        %{
          type: "priority_commitment",
          id: "commitment_required_targets",
          target_ids: [],
          required_target_ids: ["target_b"],
          priority: 1.0
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_urgent_target_commitment_required_targets")
    refute branch(artifact, "derived_urgent_target_target_a")

    commitment = branch(artifact, "derived_urgent_target_target_b")

    assert %{
             "type" => "urgent_target",
             "objective_type" => "priority_commitment",
             "target_id" => "target_b",
             "commitment_id" => "commitment_required_targets"
           } = List.first(commitment["events"])

    assert Enum.any?(
             commitment["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "observe" and
                 &1["target_id"] == "target_b" and
                 get_in(&1, ["repair", "reason"]) == "priority_commitment_candidate_inserted")
           )

    baseline_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "baseline"))

    assert baseline_row["priority_commitment_required_target_ids"] == ["target_b"]
    assert baseline_row["priority_commitment_missed_target_ids"] == ["target_b"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy priority commitments carry inline target specs into refresh" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:targets, [])
      |> Map.put(:objectives, [
        %{
          type: "priority_commitment",
          id: "commitment_inline",
          targets: [
            %{
              id: "target_inline",
              latitude_deg: "12.0",
              longitude_deg: "34.0",
              minimum_elevation_deg: "15.0",
              priority: "6.0"
            }
          ]
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    commitment = branch(artifact, "derived_urgent_target_target_inline")

    assert %{
             "objective_type" => "priority_commitment",
             "target_id" => "target_inline",
             "latitude_deg" => 12.0,
             "longitude_deg" => 34.0,
             "minimum_elevation_deg" => 15.0,
             "priority" => 6.0
           } = List.first(commitment["events"])

    assert Enum.any?(
             commitment["repair_result"]["source_candidate_activities"],
             &(&1["type"] == "observe" and &1["target_id"] == "target_inline")
           )

    assert Enum.any?(
             commitment["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "observe" and
                 &1["target_id"] == "target_inline" and
                 get_in(&1, ["repair", "reason"]) == "priority_commitment_candidate_inserted")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy priority commitments carry provider target-spec aliases into refresh" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:targets, [])
      |> Map.put(:objectives, [
        %{
          type: "priority_commitment",
          id: "commitment_required_target_specs",
          required_targets: [
            %{
              id: "target_required_spec",
              latitude_deg: -3.0,
              longitude_deg: 44.0,
              minimum_elevation_deg: 18.0,
              priority: 7.0
            }
          ]
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    commitment = branch(artifact, "derived_urgent_target_target_required_spec")

    assert %{
             "objective_type" => "priority_commitment",
             "target_id" => "target_required_spec",
             "latitude_deg" => -3.0,
             "longitude_deg" => 44.0,
             "minimum_elevation_deg" => 18.0,
             "priority" => 7.0,
             "commitment_id" => "commitment_required_target_specs"
           } = List.first(commitment["events"])

    assert Enum.any?(
             commitment["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "observe" and
                 &1["target_id"] == "target_required_spec" and
                 get_in(&1, ["repair", "reason"]) == "priority_commitment_candidate_inserted")
           )

    baseline_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "baseline"))

    assert baseline_row["priority_commitment_required_target_ids"] == ["target_required_spec"]
    assert baseline_row["priority_commitment_missed_target_ids"] == ["target_required_spec"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
