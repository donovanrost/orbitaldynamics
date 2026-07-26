Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairCandidateRejectionFilterTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{Schema, Timeline}

  test "repair excludes mission-state rejected replacement candidates" do
    available_candidate =
      "dl_available"
      |> refreshed_downlink(520.0, 580.0)
      |> Map.put("score", 10.0)

    rejected_high_score_candidate =
      "dl_rejected"
      |> refreshed_downlink(500.0, 560.0)
      |> Map.put("score", 500.0)
      |> put_in(["score_terms", "repair_priority"], 490.0)

    rejection_report =
      Timeline.candidate_rejection_report(
        [
          %{
            id: :dl_rejected,
            type: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            source_window_id: :equator_prime_rejected_window,
            starts_at_s: 500.0,
            ends_at_s: 560.0,
            min_duration_s: 120.0
          }
        ],
        source: :mission_state_candidate_rejections
      )
      |> Map.put("provenance", %{"trust_boundary" => "mission_state_candidate_rejection_report"})

    artifact =
      repair(
        %{
          "activities" => [downlink("dl_old", 100.0, 160.0)],
          "candidate_activities" => [downlink("dl_old", 100.0, 160.0)]
        },
        mission_state: %{source_candidate_rejection_report: rejection_report},
        realized_state: %{activities: [%{id: "dl_old", status: "missed"}]},
        current_epoch_s: 165.0,
        candidate_refresh:
          candidate_refresh_artifact([available_candidate, rejected_high_score_candidate],
            freshness_report: freshness_report("current")
          )
      )

    assert [%{"id" => "dl_available", "repair" => repair}] = artifact["activities"]
    refute Enum.any?(artifact["activities"], &(&1["id"] == "dl_rejected"))

    assert %{
             "action" => "moved",
             "timeline_link" => %{"replacement_activity_id" => "dl_available"},
             "replacement_ranking" => %{
               "evaluated_candidate_count" => 1,
               "rows" => [
                 %{"candidate_id" => "dl_available", "rank" => 1, "selected" => true}
               ]
             }
           } = repair

    assert %{
             "schema_contract" => "candidate_rejection_report.v1",
             "rows" => [
               %{
                 "candidate_id" => "dl_rejected",
                 "rejection_status" => "rejected",
                 "required_operator_action" => "review_candidate_rejection"
               }
             ]
           } = artifact["source_candidate_rejection_report"]

    assert artifact["score_terms"]["candidate_rejection_pressure_penalty"] == -1.0

    assert "candidate_rejection_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert [
             %{
               "term_key" => "candidate_rejection_pressure_penalty",
               "value" => -1.0,
               "selected" => true
             }
           ] =
             Enum.filter(
               artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "candidate_rejection_pressure_penalty")
             )

    assert %{
             "candidate_rejection_review_count" => 1
           } = artifact["operator_review_package"]

    assert %{
             "review_type" => "candidate_rejection_review",
             "candidate_id" => "dl_rejected",
             "source" => "campaign_repair.source_candidate_rejection_report.rows"
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "candidate_rejection_review")
             )

    assert %{
             "import_action" => "review_candidate_rejection",
             "source_review_type" => "candidate_rejection_review",
             "activity_id" => "dl_rejected",
             "source_review_row" => %{"candidate_id" => "dl_rejected"}
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source_review_type"] == "candidate_rejection_review")
             )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    rejected_candidate_artifact =
      artifact
      |> update_in(["source_candidate_activities"], fn candidates ->
        Enum.map(candidates, fn
          %{"id" => "dl_rejected"} = candidate ->
            candidate
            |> Map.put("score", -100.0)
            |> Map.put("score_terms", %{"contact_value" => -100.0})

          candidate ->
            candidate
        end)
      end)
      |> append_rejected_candidate_ranking_row()

    assert {:error, report} = Schema.validate_artifact(rejected_candidate_artifact)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] ==
                 "$.activities[0].repair.replacement_ranking.rows[1].candidate_id")
           )

    fully_legacy_artifact =
      update_in(
        rejected_candidate_artifact,
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
             Schema.validate_artifact(fully_legacy_artifact)
  end

  defp append_rejected_candidate_ranking_row(artifact) do
    [selected_row] =
      get_in(artifact, ["activities", Access.at(0), "repair", "replacement_ranking", "rows"])

    churn_s = 400.0
    move_penalty = -4.0

    rejected_row =
      selected_row
      |> Map.put("candidate_id", "dl_rejected")
      |> Map.put("candidate_score", -100.0)
      |> Map.put("schedule_churn_s", churn_s)
      |> Map.put("schedule_move_penalty", move_penalty)
      |> Map.put("ranking_score", ranking_score(selected_row, -100.0, move_penalty))
      |> Map.put("rank", 2)
      |> Map.put("selected", false)

    artifact
    |> put_in(
      ["activities", Access.at(0), "repair", "replacement_ranking", "rows"],
      [selected_row, rejected_row]
    )
    |> put_in(
      [
        "activities",
        Access.at(0),
        "repair",
        "replacement_ranking",
        "evaluated_candidate_count"
      ],
      2
    )
  end

  defp ranking_score(selected_row, candidate_score, move_penalty) do
    candidate_score +
      move_penalty +
      Enum.sum([
        selected_row["schedule_churn_penalty"],
        selected_row["station_calendar_pressure_penalty"],
        selected_row["contact_intent_pressure_penalty"],
        selected_row["contact_contention_resolution_pressure_penalty"],
        selected_row["link_capacity_pressure_penalty"],
        selected_row["resource_projection_pressure_penalty"]
      ])
  end

  defp candidate_refresh_artifact(candidates, opts) do
    %{
      "schema_version" => 1,
      "schema_contract" => "candidate_refresh.v1",
      "artifact_type" => "candidate_refresh",
      "generated_at" => "2026-05-14T00:00:00Z",
      "planner" => "OrbitalDynamics.CandidateRefresh.V1",
      "refresh_id" => Keyword.get(opts, :refresh_id, "candidate_refresh:test:abc"),
      "study_id" => "candidate_refresh_test",
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
      "contact_intents" => Keyword.get(opts, :contact_intents, []),
      "resource_summaries" => Keyword.get(opts, :resource_summaries, []),
      "contact_filter_report" => Keyword.get(opts, :contact_filter_report),
      "contact_allocation_report" => Keyword.get(opts, :contact_allocation_report),
      "resource_filter_report" => Keyword.get(opts, :resource_filter_report),
      "refresh_budget_report" => Keyword.get(opts, :refresh_budget_report),
      "candidate_diff_report" => Keyword.get(opts, :candidate_diff_report),
      "freshness_report" => Keyword.get(opts, :freshness_report),
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

  defp freshness_report(status) do
    stale_reasons =
      if status == "stale",
        do: ["accepted_snapshot_older_than_policy"],
        else: []

    %{
      "schema_contract" => "freshness_report.v1",
      "model" => "accepted_snapshot_horizon_and_quality_freshness",
      "generated_at" => "2026-05-14T00:00:00Z",
      "accepted_at" => "2026-05-13T23:00:00Z",
      "current_epoch_s" => 165.0,
      "horizon_starts_at_s" => 165.0,
      "accepted_snapshot_age_s" => 3600.0,
      "horizon_start_offset_s" => 0.0,
      "max_snapshot_age_s" => 60.0,
      "max_horizon_start_offset_s" => 1.0,
      "status" => status,
      "stale_reasons" => stale_reasons,
      "unknown_reasons" => []
    }
  end
end
