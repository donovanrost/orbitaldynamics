Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairCandidateRefreshResourceFilterTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "repair excludes supplied candidate refresh candidates suppressed by resource filters" do
    blocked_candidate =
      "dl_resource_blocked"
      |> refreshed_downlink(200.0, 260.0)
      |> Map.put("score", 100.0)
      |> put_in(["score_terms", "contact_value"], 100.0)

    available_candidate = refreshed_downlink("dl_available", 500.0, 560.0)

    resource_filter_report =
      resource_filter_report()
      |> Map.merge(%{
        "input_candidate_count" => 2,
        "kept_candidate_count" => 1,
        "suppressed_candidate_count" => 1,
        "suppressed_candidates" => [
          %{
            "id" => "resource_filter:dl_resource_blocked",
            "contact_id" => "dl_resource_blocked",
            "type" => "downlink",
            "scenario_id" => "leo_1",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 200.0,
            "ends_at_s" => 260.0,
            "suppressed_reason" => "antenna_unavailable",
            "resource_blocking_dimension" => "antenna",
            "antenna_available" => false
          }
        ]
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
          [blocked_candidate, available_candidate]
          |> candidate_refresh_artifact(
            resource_summaries: [
              %{
                "schema_contract" => "resource_summary.v1",
                "spacecraft_id" => "leo_1",
                "antenna_available" => false,
                "payload_available" => true
              }
            ],
            resource_filter_report: resource_filter_report
          )
      )

    assert [%{"id" => "dl_available", "repair" => %{"action" => "moved"}}] =
             artifact["activities"]

    assert Enum.map(artifact["source_candidate_activities"], & &1["id"]) == ["dl_available"]

    assert artifact["source_suppressed_candidate_activities"] == [blocked_candidate]

    assert %{
             "schema_contract" => "resource_filter_report.v1",
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "resource_filter:dl_resource_blocked",
                 "contact_id" => "dl_resource_blocked",
                 "suppressed_reason" => "antenna_unavailable"
               }
             ]
           } = artifact["source_resource_filter_report"]

    assert artifact["score_terms"]["resource_filter_pressure_penalty"] == -1.0

    assert "resource_filter_pressure_penalty" in artifact["score_term_report"]["score_term_keys"]

    assert [
             %{
               "term_key" => "resource_filter_pressure_penalty",
               "value" => -1.0,
               "selected" => true
             }
           ] =
             Enum.filter(
               artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "resource_filter_pressure_penalty")
             )

    assert Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "resource_suppression" and
                 &1["source"] ==
                   "campaign_repair.source_resource_filter_report.suppressed_candidates" and
                 &1["activity_id"] == "resource_filter:dl_resource_blocked" and
                 &1["required_operator_action"] == "review_suppressed_contact" and
                 get_in(&1, ["source_resource_suppression", "contact_id"]) ==
                   "dl_resource_blocked")
           )

    assert Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &(&1["import_action"] == "review_resource_suppression" and
                 &1["source_review_type"] == "resource_suppression" and
                 &1["activity_id"] == "resource_filter:dl_resource_blocked" and
                 get_in(&1, ["source_resource_suppression", "contact_id"]) ==
                   "dl_resource_blocked")
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

  defp resource_filter_report do
    %{
      "schema_contract" => "resource_filter_report.v1",
      "model" => "resource_summary_availability_and_margin_filter",
      "input_candidate_count" => 2,
      "kept_candidate_count" => 1,
      "suppressed_candidate_count" => 1,
      "suppressed_candidates" => [
        %{
          "id" => "obs_suppressed_resource",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "starts_at_s" => 300.0,
          "ends_at_s" => 360.0,
          "suppressed_reason" => "payload_unavailable"
        }
      ]
    }
  end
end
