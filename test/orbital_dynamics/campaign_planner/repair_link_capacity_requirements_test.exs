Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairLinkCapacityRequirementsTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "repair replacement ranking internalizes calibrated projected link shortfall" do
    missed_downlink = downlink("dl_1", 100.0, 160.0)

    future_downlink =
      "dl_future"
      |> refreshed_downlink(700.0, 750.0)
      |> Map.put("estimated_throughput_mb", 50.0)

    shortfall_candidate =
      "dl_shortfall"
      |> refreshed_downlink(500.0, 560.0)
      |> Map.merge(%{"score" => 10.0, "estimated_throughput_mb" => 49.0})

    satisfying_candidate =
      "dl_satisfies"
      |> refreshed_downlink(500.0, 560.0)
      |> Map.merge(%{
        "score" => 9.5,
        "score_terms" => %{"contact_value" => 9.5},
        "estimated_throughput_mb" => 50.0
      })

    deeper_shortfall_candidate =
      "dl_deeper_shortfall"
      |> refreshed_downlink(500.0, 560.0)
      |> Map.merge(%{
        "score" => 9.0,
        "score_terms" => %{"contact_value" => 9.0},
        "estimated_throughput_mb" => 48.0
      })

    plan = %{
      "activities" => [missed_downlink, future_downlink],
      "candidate_activities" => [
        shortfall_candidate,
        satisfying_candidate,
        deeper_shortfall_candidate
      ]
    }

    common_opts = [
      realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
      current_epoch_s: 165.0,
      mission_state:
        mission_state([
          %{
            "type" => "downlink_completion",
            "required_downlink_mb" => 100.0
          }
        ])
    ]

    satisfying_artifact =
      repair(plan, Keyword.put(common_opts, :scoring_policy, %{"risk_weight" => "1.0"}))

    shortfall_artifact =
      repair(plan, Keyword.put(common_opts, :scoring_policy, %{"risk_weight" => "0.25"}))

    assert [
             %{"id" => "dl_satisfies", "repair" => %{"action" => "moved"}},
             %{
               "id" => "dl_future"
             }
           ] =
             satisfying_artifact["activities"]

    assert %{
             "selected_candidate_id" => "dl_satisfies",
             "evaluated_candidate_count" => 3,
             "rows" => [
               %{
                 "rank" => 1,
                 "candidate_id" => "dl_satisfies",
                 "link_capacity_pressure_penalty" => satisfying_link_penalty,
                 "selected" => true,
                 "ranking_score" => satisfying_ranking_score
               },
               %{
                 "rank" => 2,
                 "candidate_id" => "dl_shortfall",
                 "link_capacity_pressure_penalty" => -1.0,
                 "link_capacity_pressure_required_downlink_mb" => 100.0,
                 "link_capacity_pressure_selected_capacity_adjusted_throughput_mb" => 99.0,
                 "link_capacity_pressure_shortfall_mb" => 1.0,
                 "selected" => false,
                 "ranking_score" => shortfall_ranking_score
               },
               %{
                 "rank" => 3,
                 "candidate_id" => "dl_deeper_shortfall",
                 "link_capacity_pressure_penalty" => -1.0,
                 "link_capacity_pressure_required_downlink_mb" => 100.0,
                 "link_capacity_pressure_selected_capacity_adjusted_throughput_mb" => 98.0,
                 "link_capacity_pressure_shortfall_mb" => 2.0,
                 "selected" => false,
                 "ranking_score" => deeper_shortfall_ranking_score
               }
             ]
           } =
             get_in(satisfying_artifact, [
               "activities",
               Access.at(0),
               "repair",
               "replacement_ranking"
             ])

    assert_in_delta satisfying_ranking_score, -94.5, 1.0e-9
    assert_in_delta shortfall_ranking_score, -95.0, 1.0e-9
    assert_in_delta deeper_shortfall_ranking_score, -96.0, 1.0e-9
    assert satisfying_link_penalty == 0.0

    [satisfying_ranking_row, _shortfall_ranking_row, _deeper_shortfall_ranking_row] =
      get_in(satisfying_artifact, [
        "activities",
        Access.at(0),
        "repair",
        "replacement_ranking",
        "rows"
      ])

    refute Map.has_key?(
             satisfying_ranking_row,
             "link_capacity_pressure_shortfall_mb"
           )

    refute Map.has_key?(
             satisfying_ranking_row,
             "link_capacity_pressure_required_downlink_mb"
           )

    refute Map.has_key?(
             satisfying_ranking_row,
             "link_capacity_pressure_selected_capacity_adjusted_throughput_mb"
           )

    assert %{
             "selected_capacity_adjusted_throughput_mb" => 100.0,
             "downlink_requirement_status" => "satisfied"
           } = satisfying_artifact["link_capacity_report"]

    assert satisfying_artifact["link_capacity_report"]["selected_downlink_shortfall_mb"] == 0.0

    refute Map.has_key?(satisfying_artifact["score_terms"], "link_capacity_pressure_penalty")

    refute "link_capacity_pressure_penalty" in satisfying_artifact["score_term_report"][
             "score_term_keys"
           ]

    assert_in_delta satisfying_artifact["score"], -84.5, 1.0e-9

    assert [
             %{"id" => "dl_shortfall", "repair" => %{"action" => "moved"}},
             %{
               "id" => "dl_future"
             }
           ] =
             shortfall_artifact["activities"]

    assert %{
             "selected_candidate_id" => "dl_shortfall",
             "rows" => [
               %{
                 "candidate_id" => "dl_shortfall",
                 "link_capacity_pressure_penalty" => -0.25,
                 "link_capacity_pressure_required_downlink_mb" => 100.0,
                 "link_capacity_pressure_selected_capacity_adjusted_throughput_mb" => 99.0,
                 "link_capacity_pressure_shortfall_mb" => 1.0,
                 "selected" => true
               },
               %{"candidate_id" => "dl_satisfies", "selected" => false},
               %{
                 "candidate_id" => "dl_deeper_shortfall",
                 "link_capacity_pressure_required_downlink_mb" => 100.0,
                 "link_capacity_pressure_selected_capacity_adjusted_throughput_mb" => 98.0,
                 "link_capacity_pressure_shortfall_mb" => 2.0,
                 "selected" => false
               }
             ]
           } =
             get_in(shortfall_artifact, [
               "activities",
               Access.at(0),
               "repair",
               "replacement_ranking"
             ])

    [_shortfall_ranking_row, satisfying_ranking_row, _deeper_shortfall_ranking_row] =
      get_in(shortfall_artifact, [
        "activities",
        Access.at(0),
        "repair",
        "replacement_ranking",
        "rows"
      ])

    refute Map.has_key?(
             satisfying_ranking_row,
             "link_capacity_pressure_shortfall_mb"
           )

    refute Map.has_key?(
             satisfying_ranking_row,
             "link_capacity_pressure_required_downlink_mb"
           )

    refute Map.has_key?(
             satisfying_ranking_row,
             "link_capacity_pressure_selected_capacity_adjusted_throughput_mb"
           )

    assert %{
             "selected_capacity_adjusted_throughput_mb" => 99.0,
             "selected_downlink_shortfall_mb" => 1.0,
             "downlink_requirement_status" => "shortfall"
           } = shortfall_artifact["link_capacity_report"]

    assert shortfall_artifact["score_terms"]["link_capacity_pressure_penalty"] == -0.25
    assert_in_delta shortfall_artifact["score"], -84.25, 1.0e-9

    assert [
             %{
               "term_key" => "link_capacity_pressure_penalty",
               "value" => -0.25,
               "selected" => true
             }
           ] =
             Enum.filter(
               shortfall_artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "link_capacity_pressure_penalty")
             )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2", "status" => "pass"}} =
             Schema.validate_artifact(satisfying_artifact)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2", "status" => "pass"}} =
             Schema.validate_artifact(shortfall_artifact)

    legacy_artifact =
      update_in(
        shortfall_artifact,
        ["activities", Access.at(0), "repair", "replacement_ranking", "rows"],
        fn rows ->
          Enum.map(rows, fn row ->
            row
            |> Map.delete("link_capacity_pressure_required_downlink_mb")
            |> Map.delete("link_capacity_pressure_selected_capacity_adjusted_throughput_mb")
          end)
        end
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2", "status" => "pass"}} =
             Schema.validate_artifact(legacy_artifact)

    invalid_mixed_generation =
      update_in(
        shortfall_artifact,
        ["activities", Access.at(0), "repair", "replacement_ranking", "rows", Access.at(2)],
        fn row ->
          row
          |> Map.delete("link_capacity_pressure_required_downlink_mb")
          |> Map.delete("link_capacity_pressure_selected_capacity_adjusted_throughput_mb")
        end
      )

    assert {:error, mixed_report} = Schema.validate_artifact(invalid_mixed_generation)

    assert Enum.any?(
             mixed_report["errors"],
             &(&1["path"] ==
                 "$.activities[0].repair.replacement_ranking.rows[2].link_capacity_pressure_required_downlink_mb")
           )

    invalid_partial_evidence =
      update_in(
        shortfall_artifact,
        ["activities", Access.at(0), "repair", "replacement_ranking", "rows", Access.at(0)],
        &Map.delete(&1, "link_capacity_pressure_required_downlink_mb")
      )

    assert {:error, partial_report} = Schema.validate_artifact(invalid_partial_evidence)

    assert Enum.any?(
             partial_report["errors"],
             &(&1["path"] ==
                 "$.activities[0].repair.replacement_ranking.rows[0].link_capacity_pressure_required_downlink_mb")
           )

    invalid_missing_throughput =
      update_in(
        shortfall_artifact,
        ["activities", Access.at(0), "repair", "replacement_ranking", "rows", Access.at(0)],
        &Map.delete(
          &1,
          "link_capacity_pressure_selected_capacity_adjusted_throughput_mb"
        )
      )

    assert {:error, throughput_report} = Schema.validate_artifact(invalid_missing_throughput)

    assert Enum.any?(
             throughput_report["errors"],
             &(&1["path"] ==
                 "$.activities[0].repair.replacement_ranking.rows[0].link_capacity_pressure_selected_capacity_adjusted_throughput_mb")
           )

    invalid_missing_shortfall =
      update_in(
        shortfall_artifact,
        ["activities", Access.at(0), "repair", "replacement_ranking", "rows", Access.at(0)],
        &Map.delete(&1, "link_capacity_pressure_shortfall_mb")
      )

    assert {:error, shortfall_report} = Schema.validate_artifact(invalid_missing_shortfall)

    assert Enum.any?(
             shortfall_report["errors"],
             &(&1["path"] ==
                 "$.activities[0].repair.replacement_ranking.rows[0].link_capacity_pressure_shortfall_mb")
           )

    invalid_projection_equation =
      put_in(
        shortfall_artifact,
        [
          "activities",
          Access.at(0),
          "repair",
          "replacement_ranking",
          "rows",
          Access.at(0),
          "link_capacity_pressure_selected_capacity_adjusted_throughput_mb"
        ],
        98.0
      )

    assert {:error, equation_report} = Schema.validate_artifact(invalid_projection_equation)

    assert Enum.any?(
             equation_report["errors"],
             &(&1["path"] ==
                 "$.activities[0].repair.replacement_ranking.rows[0].link_capacity_pressure_shortfall_mb")
           )

    invalid_ranking =
      update_in(
        shortfall_artifact,
        ["activities", Access.at(0), "repair", "replacement_ranking", "rows", Access.at(0)],
        fn row ->
          row
          |> Map.put("link_capacity_pressure_penalty", -0.5)
          |> Map.update!("ranking_score", &(&1 - 0.25))
        end
      )

    assert {:error, report} = Schema.validate_artifact(invalid_ranking)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] ==
                 "$.activities[0].repair.replacement_ranking.rows[0].link_capacity_pressure_penalty")
           )
  end

  test "repair link capacity uses mission-state downlink data volume requirement" do
    missed_downlink = downlink("dl_1", 100.0, 160.0)

    artifact =
      repair(
        %{
          "activities" => [missed_downlink],
          "candidate_activities" => [
            missed_downlink,
            refreshed_downlink("dl_2", 700.0, 760.0)
          ]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_downlink_mb" => 100.0
            }
          ]),
        scoring_policy: %{"risk_weight" => "2.5"}
      )

    assert [%{"id" => "dl_2"}] = artifact["activities"]

    assert %{
             "required_downlink_mb" => 100.0,
             "selected_capacity_adjusted_throughput_mb" => 60.0,
             "selected_downlink_shortfall_mb" => 40.0,
             "downlink_requirement_status" => "shortfall"
           } = artifact["link_capacity_report"]

    assert artifact["score_terms"]["link_capacity_pressure_penalty"] == -2.5
    assert artifact["score"] == artifact["score_terms"] |> Map.values() |> Enum.sum()

    assert "link_capacity_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert [
             %{
               "term_key" => "link_capacity_pressure_penalty",
               "value" => -2.5,
               "selected" => true
             }
           ] =
             Enum.filter(
               artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "link_capacity_pressure_penalty")
             )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair scoring omits link-capacity pressure when selected capacity satisfies demand" do
    missed_downlink = downlink("dl_1", 100.0, 160.0)

    artifact =
      repair(
        %{
          "activities" => [missed_downlink],
          "candidate_activities" => [
            missed_downlink,
            refreshed_downlink("dl_2", 700.0, 760.0)
          ]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_downlink_mb" => 60.0
            }
          ]),
        scoring_policy: %{"risk_weight" => "2.5"}
      )

    assert %{
             "selected_downlink_shortfall_mb" => shortfall,
             "downlink_requirement_status" => "satisfied"
           } = artifact["link_capacity_report"]

    assert shortfall == 0.0

    refute Map.has_key?(artifact["score_terms"], "link_capacity_pressure_penalty")

    refute "link_capacity_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert {:ok, %{"schema_contract" => "campaign_repair.v2", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair link capacity aggregates multiple mission-state downlink data volume requirements" do
    missed_downlink = downlink("dl_1", 100.0, 160.0)

    artifact =
      repair(
        %{
          "activities" => [missed_downlink],
          "candidate_activities" => [
            missed_downlink,
            refreshed_downlink("dl_2", 700.0, 760.0)
          ]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_downlink_mb" => 100.0
            },
            %{
              "type" => "downlink_completion",
              "required_downlink_mb" => 50.0
            }
          ])
      )

    assert %{
             "required_downlink_mb" => 150.0,
             "selected_capacity_adjusted_throughput_mb" => 60.0,
             "selected_downlink_shortfall_mb" => 90.0,
             "downlink_requirement_status" => "shortfall"
           } = artifact["link_capacity_report"]

    assert {:ok, %{"schema_contract" => "campaign_repair.v2", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair link capacity policy overrides mission-state downlink requirement" do
    missed_downlink = downlink("dl_1", 100.0, 160.0)

    artifact =
      repair(
        %{
          "activities" => [missed_downlink],
          "candidate_activities" => [
            missed_downlink,
            refreshed_downlink("dl_2", 700.0, 760.0)
          ]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_downlink_mb" => 100.0
            }
          ]),
        scoring_policy: %{"required_downlink_mb" => 120.0}
      )

    assert %{
             "required_downlink_mb" => 120.0,
             "selected_capacity_adjusted_throughput_mb" => 60.0,
             "selected_downlink_shortfall_mb" => 60.0,
             "downlink_requirement_status" => "shortfall"
           } = artifact["link_capacity_report"]

    assert {:ok, %{"schema_contract" => "campaign_repair.v2", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
