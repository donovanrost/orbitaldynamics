Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairContactContentionResolutionPressureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CampaignPlanner.RepairContactContentionResolutionPressure
  alias OrbitalDynamics.Schema

  test "maps deferred candidates to sorted unique resolution group IDs" do
    report = %{
      "recommendations" => [
        %{"group_id" => "contention:z", "deferred_contact_ids" => ["dl_2", "dl_2"]},
        %{"group_id" => "contention:a", "deferred_contact_ids" => ["dl_2", "dl_3"]},
        %{"group_id" => nil, "deferred_contact_ids" => ["dl_ignored"]},
        "invalid"
      ]
    }

    assert RepairContactContentionResolutionPressure.group_ids_by_candidate_id(report) == %{
             "dl_2" => ["contention:a", "contention:z"],
             "dl_3" => ["contention:a"]
           }

    assert RepairContactContentionResolutionPressure.selected_count(report, [
             %{"id" => "dl_2"},
             %{"id" => "dl_2"},
             %{"id" => "unrelated"}
           ]) == 1
  end

  test "exact deferred contention evidence applies one advisory ranking unit" do
    deferred_candidate =
      "dl_deferred"
      |> refreshed_downlink(500.0, 560.0)
      |> Map.put("score", 10.0)

    recommended_candidate =
      "dl_recommended"
      |> refreshed_downlink(500.0, 560.0)
      |> Map.put("score", 9.8)
      |> put_in(["score_terms", "contact_value"], 9.8)

    candidate_refresh =
      [deferred_candidate, recommended_candidate]
      |> candidate_refresh_artifact(contention_resolution_report())

    plan = %{
      "activities" => [downlink("dl_1", 100.0, 160.0)],
      "candidate_activities" => []
    }

    common_opts = [
      realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
      current_epoch_s: 165.0,
      candidate_refresh: candidate_refresh
    ]

    recommended_artifact =
      repair(plan, Keyword.put(common_opts, :scoring_policy, %{"risk_weight" => "1.0"}))

    deferred_artifact =
      repair(plan, Keyword.put(common_opts, :scoring_policy, %{"risk_weight" => "0.1"}))

    assert [%{"id" => "dl_recommended"}] = recommended_artifact["activities"]

    assert %{
             "selected_candidate_id" => "dl_recommended",
             "rows" => [
               %{
                 "candidate_id" => "dl_recommended",
                 "contact_contention_resolution_pressure_penalty" => recommended_pressure,
                 "selected" => true
               } = recommended_row,
               %{
                 "candidate_id" => "dl_deferred",
                 "contact_contention_resolution_pressure_penalty" => -1.0,
                 "contact_contention_resolution_group_ids" => [
                   "station:equator_prime:contention:1"
                 ],
                 "selected" => false
               }
             ]
           } = replacement_ranking(recommended_artifact)

    assert recommended_pressure == 0.0

    refute Map.has_key?(recommended_row, "contact_contention_resolution_group_ids")

    refute Map.has_key?(
             recommended_artifact["score_terms"],
             "contact_contention_resolution_pressure_penalty"
           )

    assert [%{"id" => "dl_deferred"}] = deferred_artifact["activities"]

    assert %{
             "selected_candidate_id" => "dl_deferred",
             "rows" => [
               %{
                 "candidate_id" => "dl_deferred",
                 "contact_contention_resolution_pressure_penalty" => -0.1,
                 "contact_contention_resolution_group_ids" => [
                   "station:equator_prime:contention:1"
                 ],
                 "selected" => true
               },
               %{
                 "candidate_id" => "dl_recommended",
                 "contact_contention_resolution_pressure_penalty" => neutral_pressure,
                 "selected" => false
               }
             ]
           } = replacement_ranking(deferred_artifact)

    assert neutral_pressure == 0.0

    assert deferred_artifact["score_terms"][
             "contact_contention_resolution_pressure_penalty"
           ] == -0.1

    assert [
             %{
               "term_key" => "contact_contention_resolution_pressure_penalty",
               "value" => -0.1,
               "selected" => true
             }
           ] =
             Enum.filter(
               deferred_artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "contact_contention_resolution_pressure_penalty")
             )

    assert Enum.any?(
             deferred_artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "contact_contention_recommendation" and
                 &1["selected_contact_id"] == "dl_recommended" and
                 &1["deferred_contact_ids"] == ["dl_deferred"])
           )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(recommended_artifact)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(deferred_artifact)

    assert_pressure_drift_rejected(deferred_artifact)
  end

  test "exports optional deferred contention ranking evidence" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    row_schema =
      get_in(schema, [
        "properties",
        "activities",
        "items",
        "properties",
        "repair",
        "properties",
        "replacement_ranking",
        "properties",
        "rows",
        "items"
      ])

    assert get_in(row_schema, [
             "properties",
             "contact_contention_resolution_pressure_penalty",
             "type"
           ]) == "number"

    assert get_in(row_schema, [
             "properties",
             "contact_contention_resolution_group_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    refute "contact_contention_resolution_pressure_penalty" in row_schema["required"]
  end

  defp assert_pressure_drift_rejected(artifact) do
    ranking_row_path =
      "$.activities[0].repair.replacement_ranking.rows[0]"

    invalid_penalty =
      update_in(
        artifact,
        ["activities", Access.at(0), "repair", "replacement_ranking", "rows", Access.at(0)],
        fn row ->
          row
          |> Map.put("contact_contention_resolution_pressure_penalty", -0.2)
          |> Map.update!("ranking_score", &(&1 - 0.1))
        end
      )

    assert {:error, penalty_report} = Schema.validate_artifact(invalid_penalty)

    assert Enum.any?(
             penalty_report["errors"],
             &(&1["path"] ==
                 ranking_row_path <> ".contact_contention_resolution_pressure_penalty")
           )

    invalid_groups =
      put_in(
        artifact,
        [
          "activities",
          Access.at(0),
          "repair",
          "replacement_ranking",
          "rows",
          Access.at(0),
          "contact_contention_resolution_group_ids"
        ],
        ["station:equator_prime:contention:drift"]
      )

    assert {:error, group_report} = Schema.validate_artifact(invalid_groups)

    assert Enum.any?(
             group_report["errors"],
             &(&1["path"] ==
                 ranking_row_path <> ".contact_contention_resolution_group_ids")
           )

    partial_current =
      update_in(
        artifact,
        ["activities", Access.at(0), "repair", "replacement_ranking", "rows", Access.at(1)],
        &Map.delete(&1, "contact_contention_resolution_pressure_penalty")
      )

    assert {:error, partial_report} = Schema.validate_artifact(partial_current)

    assert Enum.any?(
             partial_report["errors"],
             &(&1["path"] ==
                 "$.activities[0].repair.replacement_ranking.rows[1].contact_contention_resolution_pressure_penalty")
           )

    invalid_score_term =
      artifact
      |> put_in(
        ["score_terms", "contact_contention_resolution_pressure_penalty"],
        -0.2
      )
      |> Map.update!("score", &(&1 - 0.1))

    assert {:error, score_report} = Schema.validate_artifact(invalid_score_term)

    assert Enum.any?(
             score_report["errors"],
             &(&1["path"] ==
                 "$.score_terms.contact_contention_resolution_pressure_penalty")
           )
  end

  defp replacement_ranking(artifact) do
    get_in(artifact, ["activities", Access.at(0), "repair", "replacement_ranking"])
  end

  defp candidate_refresh_artifact(candidates, report) do
    %{
      "schema_version" => 1,
      "schema_contract" => "candidate_refresh.v1",
      "artifact_type" => "candidate_refresh",
      "generated_at" => "2026-05-14T00:00:00Z",
      "planner" => "OrbitalDynamics.CandidateRefresh.V1",
      "refresh_id" => "candidate_refresh:contention_resolution_pressure:001",
      "study_id" => "contention_resolution_pressure",
      "snapshot_id" => "ops-state-1",
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 1_000.0,
        "output_step_s" => 60.0
      },
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-1",
        "spacecraft_state_count" => 1
      },
      "refreshed_windows" => %{
        "access_windows" => [],
        "target_visibility_windows" => [],
        "eclipse_intervals" => []
      },
      "candidate_activities" => candidates,
      "contact_contention_resolution_report" => report,
      "contact_intents" => [],
      "resource_summaries" => [],
      "invalidated_candidates" => [],
      "validation_records" => [],
      "warnings" => [],
      "assumptions" => %{},
      "provenance" => %{},
      "source_window_lineage" =>
        Enum.map(candidates, fn candidate ->
          %{
            "candidate_activity_id" => candidate["id"],
            "source_window_id" => candidate["source_window_id"],
            "source_window_type" => get_in(candidate, ["source_window", "type"]),
            "scenario_id" => candidate["scenario_id"]
          }
        end)
    }
  end

  defp contention_resolution_report do
    %{
      "schema_contract" => "contact_contention_resolution_report.v1",
      "model" => "deterministic_contact_contention_recommendation",
      "policy" => %{
        "selection_rule" => "highest_score_earliest_start",
        "tie_breakers" => ["starts_at_s", "id"],
        "action" => "recommend_preferred_contact_for_operator_review"
      },
      "conflict_group_count" => 1,
      "recommendation_count" => 1,
      "recommendations" => [
        %{
          "group_id" => "station:equator_prime:contention:1",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 500.0,
          "ends_at_s" => 560.0,
          "selected_contact_id" => "dl_recommended",
          "selected_scenario_id" => "leo_1",
          "deferred_contact_ids" => ["dl_deferred"],
          "candidate_count" => 2,
          "selection_reason" => "highest_score_earliest_start",
          "action" => "recommend_preferred_contact_for_operator_review",
          "review_status" => "operator_review_required"
        }
      ],
      "assumptions" => %{
        "boundary" => "recommendation_only_no_station_reservation",
        "candidate_mutation" => "none",
        "operator_review" => "required_for_conflicting_contacts"
      }
    }
  end
end
