Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairCandidateRefreshBudgetFilterTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "repair excludes supplied candidate refresh candidates dropped by refresh budget" do
    dropped_candidate =
      "dl_budget_dropped"
      |> refreshed_downlink(200.0, 260.0)
      |> Map.put("score", 100.0)
      |> put_in(["score_terms", "contact_value"], 100.0)

    kept_candidate = refreshed_downlink("dl_budget_kept", 500.0, 560.0)

    refresh_budget_report =
      refresh_budget_report()
      |> Map.merge(%{
        "input_candidate_count" => 2,
        "kept_candidate_count" => 1,
        "dropped_candidate_count" => 1,
        "kept_candidate_ids" => ["dl_budget_kept"],
        "dropped_candidate_ids" => ["dl_budget_dropped"]
      })

    artifact =
      repair(
        %{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0,
        candidate_refresh:
          [dropped_candidate, kept_candidate]
          |> candidate_refresh_artifact(refresh_budget_report: refresh_budget_report)
      )

    assert [%{"id" => "dl_budget_kept", "repair" => %{"action" => "moved"}}] =
             artifact["activities"]

    assert Enum.map(artifact["source_candidate_activities"], & &1["id"]) == ["dl_budget_kept"]

    assert artifact["source_suppressed_candidate_activities"] == [dropped_candidate]

    assert %{
             "schema_contract" => "refresh_budget_report.v1",
             "dropped_candidate_count" => 1,
             "dropped_candidate_ids" => ["dl_budget_dropped"],
             "kept_candidate_ids" => ["dl_budget_kept"]
           } = artifact["source_refresh_budget_report"]

    assert artifact["score_terms"]["refresh_budget_pressure_penalty"] == -1.0

    assert "refresh_budget_pressure_penalty" in artifact["score_term_report"]["score_term_keys"]

    assert [
             %{
               "term_key" => "refresh_budget_pressure_penalty",
               "value" => -1.0,
               "selected" => true
             }
           ] =
             Enum.filter(
               artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "refresh_budget_pressure_penalty")
             )

    assert %{
             "review_type" => "refresh_budget_review",
             "source" => "campaign_repair.source_refresh_budget_report",
             "required_operator_action" => "review_refresh_budget",
             "dropped_candidate_ids" => ["dl_budget_dropped"]
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "refresh_budget_review")
             )

    assert %{
             "import_action" => "review_refresh_budget",
             "source_review_type" => "refresh_budget_review",
             "dropped_candidate_ids" => ["dl_budget_dropped"],
             "import_status" => "review_required_before_import"
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_refresh_budget")
             )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
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

  defp refresh_budget_report do
    %{
      "schema_contract" => "refresh_budget_report.v1",
      "model" => "deterministic_candidate_limit_after_filters",
      "input_candidate_count" => 2,
      "kept_candidate_count" => 1,
      "dropped_candidate_count" => 1,
      "max_candidate_activities" => 1,
      "selection_order" => "score_descending_then_start_then_id",
      "kept_candidate_ids" => ["dl_refreshed"],
      "dropped_candidate_ids" => ["dl_deferred"],
      "assumptions" => %{
        "budget_stage" => "after_contact_resource_and_allocation_filters",
        "optimizer_search_performed" => false
      }
    }
  end
end
