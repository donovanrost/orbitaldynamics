Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyQualityGateSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state quality-gate reports into branch refresh requests" do
    quality_gate_report = fn prefix,
                             readiness_level,
                             import_classification,
                             status,
                             gate_classification ->
      gate_id = "#{prefix}_quality_gate"

      %{
        "schema_contract" => "quality_gate_report.v1",
        "model" => "artifact_only_operational_quality_gate_report",
        "report_id" => "quality_gate:planned_activity.v1:#{prefix}",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "#{prefix}_activity",
        "source_readiness_report_id" => "operational_readiness:planned_activity.v1:#{prefix}",
        "readiness_level" => readiness_level,
        "import_classification" => import_classification,
        "status" => status,
        "gate_count" => 1,
        "passed_gate_count" => 0,
        "review_gate_count" => if(gate_classification == "review_only", do: 1, else: 0),
        "analysis_gate_count" => if(gate_classification == "analysis_only", do: 1, else: 0),
        "blocked_gate_count" => if(gate_classification == "blocked", do: 1, else: 0),
        "gate_status_counts" => %{status => 1},
        "gate_classification_counts" => %{gate_classification => 1},
        "rows" => [
          %{
            "id" => "quality_gate:#{prefix}:1",
            "gate_id" => gate_id,
            "status" => status,
            "classification" => gate_classification,
            "reason" => "#{prefix} quality gate requires branch-local routing",
            "manifest_review_required_count" => 1,
            "blocked_import_count" => if(gate_classification == "blocked", do: 1, else: 0),
            "missing_import_count" => 1,
            "invalid_cadence_import_count" => 1,
            "freshness_status_counts" => %{"stale" => 1},
            "schema_validation_status_counts" => %{"fail" => 1},
            "import_status_counts" => %{"review_required_before_import" => 1},
            "cadence_import_status_counts" => %{"missing" => 1},
            "resource_availability_pressure_count" => 2,
            "resource_availability_reason_counts" => %{
              "ground_station_reserved" => 1,
              "payload_unavailable" => 1
            },
            "station_availability_reason_ids" => ["ground_station_reserved"],
            "unavailable_resource_reason_ids" => ["payload_unavailable"],
            "resource_blocking_dimension_counts" => %{"communications" => 1}
          }
        ],
        "assumptions" => %{"source" => "campaign_planner_test.#{prefix}.quality_gate"},
        "model_limits" => ["artifact_only"],
        "provenance" => %{"trust_boundary" => "#{prefix}_quality_gate_boundary"}
      }
    end

    direct_report =
      quality_gate_report.(
        "direct",
        "operator_review",
        "review_only",
        "review_required",
        "review_only"
      )

    canonical_report =
      quality_gate_report.(
        "canonical",
        "operator_review",
        "review_only",
        "review_required",
        "review_only"
      )

    source_wrapped_report =
      quality_gate_report.("source_wrapped", "blocked", "blocked", "blocked", "blocked")

    result_wrapped_report =
      quality_gate_report.(
        "result_wrapped",
        "analysis_only",
        "analysis_only",
        "analysis_only",
        "analysis_only"
      )

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_quality_gate_report", direct_report)
      |> Map.put("quality_gate_report", canonical_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "quality_gate_report" => Map.delete(source_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "source_wrapped_quality_gate_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_quality_gate_report" => Map.delete(result_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "result_wrapped_quality_gate_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = urgent["assumptions"]["candidate_source"]

    for source_path <- [
          "mission_state.source_quality_gate_report",
          "mission_state.quality_gate_report",
          "mission_state.source_result_artifact.quality_gate_report",
          "mission_state.result_artifact.source_quality_gate_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_quality_gate_readiness_level_counts" => %{
               "analysis_only" => 1,
               "blocked" => 1,
               "operator_review" => 2
             },
             "source_report_quality_gate_import_classification_counts" => %{
               "analysis_only" => 1,
               "blocked" => 1,
               "review_only" => 2
             },
             "source_report_quality_gate_status_counts" => %{
               "analysis_only" => 1,
               "blocked" => 1,
               "review_required" => 2
             },
             "source_report_quality_gate_gate_count" => 4,
             "source_report_quality_gate_review_gate_count" => 2,
             "source_report_quality_gate_analysis_gate_count" => 1,
             "source_report_quality_gate_blocked_gate_count" => 1,
             "source_report_quality_gate_gate_status_counts" => %{
               "analysis_only" => 1,
               "blocked" => 1,
               "review_required" => 2
             },
             "source_report_quality_gate_gate_classification_counts" => %{
               "analysis_only" => 1,
               "blocked" => 1,
               "review_only" => 2
             },
             "source_report_quality_gate_manifest_review_required_count" => 4,
             "source_report_quality_gate_resource_availability_pressure_count" => 8,
             "source_report_quality_gate_resource_availability_reason_counts" => %{
               "ground_station_reserved" => 4,
               "payload_unavailable" => 4
             },
             "source_report_quality_gate_station_availability_reason_counts" => %{
               "ground_station_reserved" => 4
             },
             "source_report_quality_gate_resource_blocking_dimension_counts" => %{
               "communications" => 4
             },
             "source_report_quality_gate_source_readiness_report_count" => 4
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "quality_gate_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_paths" => replay_source_paths,
             "readiness_level_counts" => %{
               "analysis_only" => 1,
               "blocked" => 1,
               "operator_review" => 2
             },
             "gate_count" => 4,
             "manifest_review_required_count" => 4,
             "resource_availability_pressure_count" => 8,
             "resource_availability_reason_counts" => %{
               "ground_station_reserved" => 4,
               "payload_unavailable" => 4
             },
             "station_availability_reason_counts" => %{"ground_station_reserved" => 4},
             "resource_blocking_dimension_counts" => %{"communications" => 4},
             "source_readiness_report_count" => 4,
             "branch_local_review_pressure" => true,
             "branch_local_import_pressure" => true,
             "branch_local_resource_pressure" => true
           } = CandidateRefresh.quality_gate_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.quality_gate_report",
             "mission_state.result_artifact.source_quality_gate_report",
             "mission_state.source_quality_gate_report",
             "mission_state.source_result_artifact.quality_gate_report"
           ]

    assert_quality_gate_pressure_score_terms(urgent, artifact)

    urgent_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))

    assert "quality_gate_pressure" in urgent_row["risk_types"]

    assert urgent_row["branch_quality_gate_readiness_levels"] == [
             "analysis_only",
             "blocked",
             "operator_review"
           ]

    assert urgent_row["branch_quality_gate_import_classifications"] == [
             "analysis_only",
             "blocked",
             "review_only"
           ]

    assert urgent_row["branch_quality_gate_statuses"] == [
             "analysis_only",
             "blocked",
             "review_required"
           ]

    assert urgent_row["branch_quality_gate_gate_classifications"] == [
             "analysis_only",
             "blocked",
             "review_only"
           ]

    assert urgent_row["branch_quality_gate_source_report_paths"] == [
             "mission_state.quality_gate_report",
             "mission_state.result_artifact.source_quality_gate_report",
             "mission_state.source_quality_gate_report",
             "mission_state.source_result_artifact.quality_gate_report"
           ]

    quality_gate_review_row =
      artifact["operator_review_package"]["rows"]
      |> Enum.find(
        &(&1["review_type"] == "strategy_tradeoff" and &1["branch_id"] == "urgent" and
            &1["source"] == "campaign_strategy.branch_comparison_report.rows")
      )

    assert quality_gate_review_row["branch_quality_gate_readiness_levels"] == [
             "analysis_only",
             "blocked",
             "operator_review"
           ]

    assert quality_gate_review_row["branch_quality_gate_gate_classifications"] == [
             "analysis_only",
             "blocked",
             "review_only"
           ]

    assert quality_gate_review_row["branch_quality_gate_source_report_paths"] == [
             "mission_state.quality_gate_report",
             "mission_state.result_artifact.source_quality_gate_report",
             "mission_state.source_quality_gate_report",
             "mission_state.source_result_artifact.quality_gate_report"
           ]

    assert get_in(quality_gate_review_row, [
             "source_branch_comparison",
             "branch_quality_gate_source_report_paths"
           ]) == [
             "mission_state.quality_gate_report",
             "mission_state.result_artifact.source_quality_gate_report",
             "mission_state.source_quality_gate_report",
             "mission_state.source_result_artifact.quality_gate_report"
           ]

    quality_gate_import_row =
      artifact["cadence_import_manifest"]["rows"]
      |> Enum.find(
        &(&1["source_review_type"] == "strategy_branch_comparison" and
            &1["branch_id"] == "urgent")
      )

    assert quality_gate_import_row["branch_quality_gate_import_classifications"] == [
             "analysis_only",
             "blocked",
             "review_only"
           ]

    assert quality_gate_import_row["branch_quality_gate_source_report_paths"] == [
             "mission_state.quality_gate_report",
             "mission_state.result_artifact.source_quality_gate_report",
             "mission_state.source_quality_gate_report",
             "mission_state.source_result_artifact.quality_gate_report"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_quality_gate_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    quality_gate_pressure_count =
      Enum.count(branch["risk_indicators"], &(&1["type"] == "quality_gate_pressure"))

    assert quality_gate_pressure_count > 0

    assert branch["score_terms"]["approval_boundary_pressure_penalty"] == 0.0

    assert branch["score_terms"]["quality_gate_pressure_penalty"] ==
             -quality_gate_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - quality_gate_pressure_count) * risk_weight

    assert "quality_gate_pressure_penalty" in artifact["score_term_report"]["score_term_keys"]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "quality_gate_pressure_penalty" and &1["value"] < 0.0)
           )
  end
end
