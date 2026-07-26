Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairCandidateDiffSemanticMatchTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "repair prefers semantic candidate-diff replacement links" do
    semantic_replacement =
      "dl_semantic"
      |> refreshed_downlink(520.0, 580.0)
      |> Map.put("score", 10.0)

    high_score_candidate =
      "dl_high_score"
      |> refreshed_downlink(500.0, 560.0)
      |> Map.put("score", 500.0)
      |> put_in(["score_terms", "repair_priority"], 490.0)

    candidate_diff_report = %{
      "schema_contract" => "candidate_diff_report.v1",
      "model" => "candidate_id_set_diff_with_semantic_change_reasons",
      "prior_candidate_count" => 1,
      "refreshed_candidate_count" => 2,
      "retained_candidate_count" => 0,
      "new_candidate_count" => 2,
      "invalidated_candidate_count" => 1,
      "retained_candidates" => [],
      "new_candidates" => [
        %{
          "id" => "dl_semantic",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "starts_at_s" => 520.0,
          "ends_at_s" => 580.0,
          "diff_reason" => "semantically_similar_prior_candidate_changed",
          "matched_prior_candidate_id" => "dl_old",
          "semantic_change_reasons" => ["starts_at_s_changed", "ends_at_s_changed"]
        },
        %{
          "id" => "dl_high_score",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "starts_at_s" => 500.0,
          "ends_at_s" => 560.0,
          "diff_reason" => "not_present_in_prior_candidate_set"
        }
      ],
      "invalidated_candidates" => [
        %{
          "id" => "dl_old",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "collection_id" => "collection_alpha",
          "product_ids" => ["image_l0", "image_l1"],
          "payload_id" => "camera_a",
          "instrument_id" => "imager",
          "target_id" => "target_a",
          "source_activity_ids" => ["obs_semantic"],
          "objective_id" => "latency:collection_alpha",
          "objective_type" => "collection_latency",
          "latency_objective" => true,
          "max_latency_s" => 900.0,
          "planned_latency_s" => 540.0,
          "required_downlink_mb" => 300.0,
          "candidate_downlink_mb" => 360.0,
          "downlink_completion_ratio" => 1.0,
          "downlink_requirement_status" => "satisfied",
          "downlink_completion_source" =>
            "candidate_refresh.downlink_demand.objectives_and_operational_feedback",
          "downlink_completion_sources" => [
            "candidate_refresh.objectives.collection_latency",
            "operational_feedback.downlink_demand_mb.station"
          ],
          "starts_at_s" => 100.0,
          "ends_at_s" => 160.0,
          "invalidated_reason" => "replaced_by_semantically_similar_candidate",
          "replacement_candidate_id" => "dl_semantic",
          "candidate_budget_match_status" => "budget_dropped_replacement_candidate",
          "candidate_budget_match_count" => 1,
          "budget_dropped_candidate_ids" => ["dl_semantic"],
          "semantic_change_reasons" => ["starts_at_s_changed", "ends_at_s_changed"]
        }
      ]
    }

    artifact =
      repair(
        %{
          "activities" => [downlink("dl_old", 100.0, 160.0)],
          "candidate_activities" => [downlink("dl_old", 100.0, 160.0)]
        },
        realized_state: %{activities: [%{id: "dl_old", status: "missed"}]},
        current_epoch_s: 165.0,
        candidate_refresh:
          candidate_refresh_artifact([semantic_replacement, high_score_candidate],
            candidate_diff_report: candidate_diff_report,
            freshness_report: freshness_report("current")
          )
      )

    assert [%{"id" => "dl_semantic", "repair" => repair}] = artifact["activities"]

    assert %{
             "invalidated_candidate_id" => "dl_old",
             "replacement_candidate_id" => "dl_semantic",
             "invalidated_reason" => "replaced_by_semantically_similar_candidate",
             "candidate_budget_match_status" => "budget_dropped_replacement_candidate",
             "candidate_budget_match_count" => 1,
             "budget_dropped_candidate_ids" => ["dl_semantic"],
             "semantic_change_reasons" => ["starts_at_s_changed", "ends_at_s_changed"]
           } = repair["candidate_diff"]

    assert %{
             "selected_candidate_id" => "dl_semantic",
             "rows" => [
               %{
                 "rank" => 1,
                 "candidate_id" => "dl_semantic",
                 "semantic_candidate_diff_match" => true,
                 "candidate_diff_priority" => 0,
                 "candidate_score" => 10.0,
                 "selected" => true
               },
               %{
                 "rank" => 2,
                 "candidate_id" => "dl_high_score",
                 "semantic_candidate_diff_match" => false,
                 "candidate_diff_priority" => 1,
                 "candidate_score" => 500.0,
                 "selected" => false
               }
             ]
           } = repair["replacement_ranking"]

    assert [
             %{
               "activity_id" => "dl_old",
               "repair_action" => "moved",
               "replacement_activity_id" => "dl_semantic",
               "replacement_activity_context" => %{
                 "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1"
               }
             }
           ] = artifact["deltas"]

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:error, report} =
             artifact
             |> Map.delete("source_candidate_diff_report")
             |> Schema.validate_artifact()

    assert Enum.any?(
             report["errors"],
             &(&1["path"] ==
                 "$.activities[0].repair.replacement_ranking.rows[0].semantic_candidate_diff_match")
           )
  end

  defp candidate_refresh_artifact(candidates, opts) do
    candidate_diff_report = Keyword.get(opts, :candidate_diff_report)

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
      "candidate_diff_report" => candidate_diff_report,
      "freshness_report" => Keyword.get(opts, :freshness_report),
      "invalidated_candidates" =>
        Map.get(candidate_diff_report || %{}, "invalidated_candidates", []),
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
