Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyTargetCoverageRefreshTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives target coverage refresh branches for uncovered target catalog entries" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:objectives, [
        %{
          type: "target_coverage",
          id: "coverage_north",
          target_ids: ["target_a"],
          required_observations: 1
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    coverage = branch(artifact, "derived_target_coverage_target_a")

    assert %{
             "type" => "urgent_target",
             "objective_type" => "target_coverage",
             "target_id" => "target_a",
             "planned_observations" => 0,
             "required_observations" => 1,
             "coverage_objective_id" => "coverage_north"
           } = List.first(coverage["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             coverage["assumptions"]["candidate_source"]

    assert Enum.any?(
             coverage["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "observe" and
                 &1["target_id"] == "target_a" and
                 get_in(&1, ["repair", "reason"]) == "target_coverage_candidate_inserted")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy disambiguates multiple target coverage objectives for the same target" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:objectives, [
        %{
          type: "target_coverage",
          id: "coverage_morning",
          target_ids: ["target_a"],
          starts_at_s: 300.0,
          ends_at_s: 420.0,
          required_observations: 1
        },
        %{
          type: "target_coverage",
          id: "coverage_evening",
          target_ids: ["target_a"],
          starts_at_s: 500.0,
          ends_at_s: 620.0,
          required_observations: 1
        }
      ])

    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_morning", "leo_1", "target_a", 320.0, 380.0, 10.0),
          observe("obs_evening", "leo_1", "target_a", 520.0, 580.0, 10.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_target_coverage_target_a")

    morning = branch(artifact, "derived_target_coverage_target_a_coverage_morning")
    evening = branch(artifact, "derived_target_coverage_target_a_coverage_evening")

    assert %{
             "target_branch_base_id" => "derived_target_coverage_target_a",
             "target_branch_identity" => "coverage_morning"
           } = morning["provenance"]["branch_metadata"]

    assert %{"coverage_objective_id" => "coverage_morning", "starts_at_s" => 300.0} =
             List.first(morning["events"])

    assert [
             %{
               "id" =>
                 "derived_target_coverage_target_a_coverage_morning_urgent_observe_target_a",
               "starts_at_s" => 320.0,
               "repair" => %{"reason" => "target_coverage_candidate_inserted"}
             }
           ] = morning["candidate_plan"]["strategic_additions"]

    assert %{
             "target_branch_base_id" => "derived_target_coverage_target_a",
             "target_branch_identity" => "coverage_evening"
           } = evening["provenance"]["branch_metadata"]

    assert [
             %{
               "id" =>
                 "derived_target_coverage_target_a_coverage_evening_urgent_observe_target_a",
               "starts_at_s" => 520.0,
               "repair" => %{"reason" => "target_coverage_candidate_inserted"}
             }
           ] = evening["candidate_plan"]["strategic_additions"]

    morning_comparison =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_target_coverage_target_a_coverage_morning"))

    assert %{
             "target_branch_base_id" => "derived_target_coverage_target_a",
             "target_branch_identity" => "coverage_morning"
           } = morning_comparison

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    morning_index =
      Enum.find_index(
        artifact["branch_comparison_report"]["rows"],
        &(&1["branch_id"] == "derived_target_coverage_target_a_coverage_morning")
      )

    invalid =
      put_in(
        artifact,
        [
          "branch_comparison_report",
          "rows",
          Access.at(morning_index),
          "target_branch_identity"
        ],
        "coverage_drift"
      )

    assert {:error, validation_report} = Schema.validate_artifact(invalid)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{morning_index}].target_branch_identity")
           )
  end

  test "strategy does not derive target coverage from duplicate target catalog ids" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:targets, [
        %{
          id: "target_a",
          latitude_deg: 0.0,
          longitude_deg: 0.0,
          minimum_elevation_deg: 10.0,
          priority: 2.0
        },
        %{
          id: "target_a",
          latitude_deg: 5.0,
          longitude_deg: 5.0,
          minimum_elevation_deg: 10.0,
          priority: 8.0
        }
      ])
      |> Map.put(:objectives, [
        %{
          type: "target_coverage",
          id: "coverage_duplicate_catalog",
          required_observations: 1
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_target_coverage_target_a")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy target coverage objective preserves candidate time window" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_too_early", "leo_1", "target_a", 100.0, 160.0, 100.0),
          observe("obs_in_window", "leo_1", "target_a", 360.0, 420.0, 10.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              type: "target_coverage",
              target_ids: ["target_a"],
              starts_at_s: 300.0,
              ends_at_s: 500.0,
              required_observations: 1
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    coverage = branch(artifact, "derived_target_coverage_target_a")

    assert %{
             "objective_type" => "target_coverage",
             "starts_at_s" => 300.0,
             "ends_at_s" => 500.0
           } = List.first(coverage["events"])

    assert [
             %{
               "starts_at_s" => 360.0,
               "ends_at_s" => 420.0,
               "repair" => %{"reason" => "target_coverage_candidate_inserted"}
             }
           ] = coverage["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy target coverage objective ignores planned observations outside objective window" do
    prior_plan =
      base_plan(%{
        "activities" => [
          observe("obs_old", "leo_1", "target_a", 100.0, 160.0, 100.0)
        ],
        "candidate_activities" => [
          observe("obs_in_window", "leo_1", "target_a", 360.0, 420.0, 10.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              type: "target_coverage",
              target_ids: ["target_a"],
              starts_at_s: 300.0,
              ends_at_s: 500.0,
              required_observations: 1
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    coverage = branch(artifact, "derived_target_coverage_target_a")

    assert %{
             "objective_type" => "target_coverage",
             "planned_observations" => 0
           } = List.first(coverage["events"])

    assert [
             %{
               "id" => "derived_target_coverage_target_a_urgent_observe_target_a",
               "starts_at_s" => 360.0,
               "repair" => %{"reason" => "target_coverage_candidate_inserted"}
             }
           ] = coverage["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy target coverage objective discounts sparse missed feedback inside objective window" do
    prior_plan =
      base_plan(%{
        "activities" => [
          observe("obs_in_window", "leo_1", "target_a", 360.0, 420.0, 10.0)
        ],
        "candidate_activities" => [
          observe("obs_replacement", "leo_1", "target_a", 430.0, 490.0, 10.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:objectives, [
            %{
              type: "target_coverage",
              target_ids: ["target_a"],
              starts_at_s: 300.0,
              ends_at_s: 500.0,
              required_observations: 1
            }
          ])
          |> Map.put(:realized_activities, [
            %{id: "obs_in_window", status: "missed"}
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    coverage = branch(artifact, "derived_target_coverage_target_a")

    assert %{
             "objective_type" => "target_coverage",
             "planned_observations" => 0
           } = List.first(coverage["events"])

    assert [
             %{
               "id" => "derived_target_coverage_target_a_urgent_observe_target_a",
               "starts_at_s" => 430.0,
               "repair" => %{"reason" => "target_coverage_candidate_inserted"}
             }
           ] = coverage["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy target coverage objective preserves scenario scope when staging candidates" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_wrong_spacecraft", "leo_1", "target_a", 360.0, 420.0, 100.0),
          observe("obs_scoped_spacecraft", "leo_2", "target_a", 360.0, 420.0, 10.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              type: "target_coverage",
              id: "coverage_leo_2",
              target_id: "target_a",
              scenario_id: "leo_2",
              required_observations: 1
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    coverage = branch(artifact, "derived_target_coverage_target_a")

    assert %{
             "coverage_objective_id" => "coverage_leo_2",
             "scenario_id" => "leo_2"
           } = List.first(coverage["events"])

    assert [
             %{
               "scenario_id" => "leo_2",
               "starts_at_s" => 360.0,
               "ends_at_s" => 420.0,
               "repair" => %{"reason" => "target_coverage_candidate_inserted"}
             }
           ] = coverage["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy target coverage objective can carry inline target specs into refresh" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:targets, [])
      |> Map.put(:objectives, [
        %{
          type: "target_coverage",
          targets: [
            %{
              id: "target_inline",
              latitude_deg: 0.0,
              longitude_deg: 0.0,
              minimum_elevation_deg: 10.0,
              priority: 5.0
            }
          ],
          required_observations: 1
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    coverage = branch(artifact, "derived_target_coverage_target_inline")

    assert %{
             "objective_type" => "target_coverage",
             "target_id" => "target_inline"
           } = event = List.first(coverage["events"])

    assert event["latitude_deg"] == 0.0
    assert event["longitude_deg"] == 0.0

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             coverage["assumptions"]["candidate_source"]

    assert Enum.any?(
             coverage["repair_result"]["source_candidate_activities"],
             &(&1["type"] == "observe" and &1["target_id"] == "target_inline")
           )

    assert Enum.any?(
             coverage["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "observe" and
                 &1["target_id"] == "target_inline" and
                 get_in(&1, ["repair", "reason"]) == "target_coverage_candidate_inserted")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy target coverage objective with singular target id does not expand to full catalog" do
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
          type: "target_coverage",
          id: "coverage_target_a_only",
          target_id: "target_a",
          required_observations: 1
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert branch(artifact, "derived_target_coverage_target_a")
    refute branch(artifact, "derived_target_coverage_target_b")

    assert %{
             "coverage_objective_id" => "coverage_target_a_only",
             "target_id" => "target_a"
           } = List.first(branch(artifact, "derived_target_coverage_target_a")["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy target coverage combines explicit list selectors without empty-list masking" do
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
          type: "target_coverage",
          id: "coverage_required_targets",
          target_ids: [],
          required_target_ids: ["target_b"],
          required_observations: 1
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_target_coverage_target_a")
    assert branch(artifact, "derived_target_coverage_target_b")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy skips target coverage branch when requested target is already planned" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:objectives, [
        %{
          type: "target_coverage",
          target_ids: ["target_a"],
          required_observations: 1
        }
      ])

    artifact =
      strategy(
        base_plan(%{
          "activities" => [observe("obs_a", "leo_1", "target_a", 100.0, 160.0, 10.0)]
        }),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_target_coverage_target_a")
  end
end
