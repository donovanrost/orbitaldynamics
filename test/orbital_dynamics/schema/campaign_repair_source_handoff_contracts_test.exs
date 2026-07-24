defmodule OrbitalDynamics.Schema.CampaignRepairSourceHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "validates checked-in repair readiness source handoff fixture" do
    fixture = read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")

    assert repair_readiness_source_handoff_fixture() == fixture

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(fixture)

    assert fixture["source_operational_readiness_report"]["schema_contract"] ==
             "operational_readiness_report.v1"

    assert fixture["source_quality_gate_report"]["schema_contract"] ==
             "quality_gate_report.v1"

    assert %{
             "evaluated_candidate_count" => 1,
             "global_optimization" => false,
             "model" => "greedy_repair_replacement_ranking",
             "selected_candidate_id" => "dl_ready",
             "selection_scope" => "viable_unique_candidates_within_repair_intent",
             "rows" => [ranking_row]
           } =
             fixture["activities"]
             |> Enum.find(&(&1["id"] == "dl_ready"))
             |> get_in(["repair", "replacement_ranking"])

    assert ranking_row === %{
             "candidate_diff_priority" => 1,
             "candidate_id" => "dl_ready",
             "candidate_score" => 10.0,
             "contact_contention_resolution_pressure_penalty" => 0.0,
             "contact_intent_pressure_penalty" => 0.0,
             "link_capacity_pressure_penalty" => 0.0,
             "rank" => 1,
             "ranking_score" => -94.0,
             "resource_projection_pressure_penalty" => 0.0,
             "schedule_churn_penalty" => -100.0,
             "schedule_churn_s" => 400.0,
             "schedule_move_penalty" => -4.0,
             "selected" => true,
             "semantic_candidate_diff_match" => false,
             "station_calendar_pressure_penalty" => 0.0
           }

    assert %{
             "operational_readiness_review_count" => 2,
             "quality_gate_review_count" => 1
           } = fixture["operator_review_package"]

    assert %{
             "review_type" => "operational_readiness_review",
             "source" => "campaign_repair.source_operational_readiness_report",
             "required_operator_action" => "review_operational_readiness",
             "source_operational_readiness_report" => %{
               "report_id" => "operational_readiness:planned_activity.v1:repair_source_fixture"
             }
           } =
             Enum.find(
               fixture["operator_review_package"]["rows"],
               &(&1["review_type"] == "operational_readiness_review")
             )

    assert %{
             "review_type" => "quality_gate_review",
             "source" => "campaign_repair.source_quality_gate_report.rows",
             "required_operator_action" => "review_quality_gate",
             "quality_gate_id" => "operator_review",
             "source_quality_gate_report" => %{
               "report_id" => "quality_gate:planned_activity.v1:repair_source_fixture"
             }
           } =
             Enum.find(
               fixture["operator_review_package"]["rows"],
               &(&1["review_type"] == "quality_gate_review")
             )

    readiness_import_rows =
      Enum.filter(
        fixture["cadence_import_manifest"]["rows"],
        &(&1["import_action"] == "review_operational_readiness")
      )

    assert Enum.map(readiness_import_rows, & &1["source"]) == [
             "campaign_repair.source_operational_readiness_report",
             "campaign_repair.source_operational_readiness_report.gates"
           ]

    assert Enum.all?(
             readiness_import_rows,
             &(&1["source_review_type"] == "operational_readiness_review")
           )

    assert [
             %{
               "import_action" => "review_quality_gate",
               "source_review_type" => "quality_gate_review",
               "source" => "campaign_repair.source_quality_gate_report.rows"
             }
           ] =
             Enum.filter(
               fixture["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_quality_gate")
             )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  defp repair_readiness_source_handoff_fixture do
    OrbitalDynamics.campaign_repair(repair_readiness_source_handoff_request())
  end

  defp repair_readiness_source_handoff_request do
    %{
      prior_plan:
        Map.merge(base_repair_source_plan(), %{
          "activities" => [repair_source_downlink("dl_committed", 100.0, 160.0)],
          "candidate_activities" => [repair_source_downlink("dl_stale", 700.0, 760.0)]
        }),
      realized_state: %{activities: [%{id: "dl_committed", status: "missed"}]},
      current_epoch_s: 165.0,
      remaining_horizon: %{"starts_at_s" => 165.0, "ends_at_s" => 600.0},
      generated_at: ~U[2026-05-14 00:00:00Z],
      candidate_refresh: %{
        "schema_version" => 1,
        "schema_contract" => "candidate_refresh.v1",
        "artifact_type" => "candidate_refresh",
        "generated_at" => "2026-05-14T00:00:00Z",
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "refresh_id" => "candidate_refresh:repair_source_fixture",
        "study_id" => "test",
        "snapshot_id" => "ops-state-1",
        "current_epoch_s" => 165.0,
        "remaining_horizon" => %{
          "starts_at_s" => 165.0,
          "ends_at_s" => 600.0,
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
        "candidate_activities" => [
          repair_source_refreshed_downlink("dl_ready", 500.0, 560.0)
        ],
        "contact_intents" => [],
        "resource_summaries" => [],
        "invalidated_candidates" => [],
        "validation_records" => [],
        "warnings" => [],
        "assumptions" => %{},
        "provenance" => %{},
        "source_window_lineage" => [],
        "source_operational_readiness_report" => repair_source_readiness_report(),
        "source_quality_gate_report" => repair_source_quality_gate_report()
      }
    }
  end

  defp base_repair_source_plan do
    %{
      "schema_version" => 1,
      "generated_at" => "2026-05-13T00:00:00Z",
      "planner" => "OrbitalDynamics.CampaignPlanner.V1",
      "plan_id" => "campaign_plan:test:2026-05-13T00:00:00Z",
      "study_id" => "test",
      "planning_horizon" => %{"duration_s" => 1_000.0, "output_step_s" => 60.0},
      "activities" => [],
      "candidate_activities" => [],
      "assumptions" => %{
        "constraints" => %{},
        "scoring_policy" => %{}
      },
      "provenance" => %{},
      "ranking_explanation" => %{
        "policy" => %{
          "target_value_weight" => 1.0,
          "contact_value_weight" => 0.2,
          "schedule_churn_cost_weight" => 100.0,
          "schedule_move_cost_weight" => 0.01
        }
      }
    }
  end

  defp repair_source_downlink(id, starts_at_s, ends_at_s) do
    %{
      "id" => id,
      "type" => "downlink",
      "scenario_id" => "leo_1",
      "ground_station_id" => "equator_prime",
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "duration_s" => ends_at_s - starts_at_s,
      "score" => 10.0
    }
  end

  defp repair_source_refreshed_downlink(id, starts_at_s, ends_at_s) do
    id
    |> repair_source_downlink(starts_at_s, ends_at_s)
    |> Map.merge(%{
      "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
      "source_window" => %{
        "id" => "window:leo_1:ground_station_access:equator_prime:1",
        "type" => "ground_station_access"
      },
      "score_terms" => %{"contact_value" => 10.0},
      "cadence_import" => %{
        "activity_type" => "contact",
        "external_id" => id,
        "schema_contract" => "proposed_contact.v1"
      },
      "direction" => "downlink",
      "estimated_throughput_mb" => ends_at_s - starts_at_s
    })
  end

  defp repair_source_readiness_report do
    %{
      "schema_contract" => "operational_readiness_report.v1",
      "schema_version" => 1,
      "model" => "artifact_only_operational_readiness_classifier",
      "report_id" => "operational_readiness:planned_activity.v1:repair_source_fixture",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "repair_source_fixture",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "status" => "review_required",
      "gate_count" => 1,
      "passed_gate_count" => 0,
      "review_gate_count" => 1,
      "analysis_gate_count" => 0,
      "blocked_gate_count" => 0,
      "gates" => [
        %{
          "id" => "operator_review",
          "status" => "review_required",
          "classification" => "review_only",
          "reason" => "operator review required"
        }
      ],
      "evidence" => %{},
      "assumptions" => [
        "classification_uses_declared_operator_review_and_cadence_import_manifest_evidence",
        "cadence_import_manifest_rows_are_adapter_handoff_not_external_import_writes"
      ],
      "model_limits" => [
        "artifact_only",
        "does_not_write_cadence",
        "does_not_approve_operator_actions",
        "does_not_execute_commands",
        "uses_declared_review_and_import_evidence"
      ]
    }
  end

  defp repair_source_quality_gate_report do
    OrbitalDynamics.operational_quality_gate_report(repair_source_readiness_report())
  end
end
