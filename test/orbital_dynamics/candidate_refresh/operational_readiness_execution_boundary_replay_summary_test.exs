defmodule OrbitalDynamics.CandidateRefresh.OperationalReadinessExecutionBoundaryReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary replays compact operational execution boundary summaries" do
    summary = operational_execution_boundary_summary_fixture()

    refresh = %{
      "accepted_planning_state" => %{"operational_execution_boundary_summary" => summary},
      "mission_state" => %{"source_operational_execution_boundary_summary" => summary},
      "source_operational_execution_boundary_summary" => summary,
      "source_result_artifact" => %{"operational_execution_boundary_summary" => summary}
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_counts_by_contract" => %{
               "operational_execution_boundary_summary.v1" => 4
             },
             "source_report_row_counts_by_contract" => %{
               "operational_execution_boundary_summary.v1" => 4
             },
             "source_report_operational_readiness_contract" =>
               "operational_execution_boundary_summary.v1",
             "source_report_operational_readiness_count" => 4,
             "source_report_operational_readiness_row_count" => 4,
             "source_report_operational_readiness_paths" => [
               "accepted_planning_state.operational_execution_boundary_summary",
               "mission_state.source_operational_execution_boundary_summary",
               "source_operational_execution_boundary_summary",
               "source_result_artifact.operational_execution_boundary_summary"
             ],
             "source_report_operational_readiness_readiness_level_counts" => %{
               "analysis_only" => 4
             },
             "source_report_operational_readiness_import_classification_counts" => %{
               "analysis_only" => 4
             },
             "source_report_operational_readiness_status_counts" => %{"analysis_only" => 4},
             "source_report_operational_readiness_gate_count" => 20,
             "source_report_operational_readiness_passed_gate_count" => 16,
             "source_report_operational_readiness_analysis_gate_count" => 4,
             "source_report_operational_readiness_analysis_mode_counts" => %{
               "simulation" => 4
             },
             "source_reports" => %{
               "operational_readiness_report" => %{
                 "paths" => [
                   "accepted_planning_state.operational_execution_boundary_summary",
                   "mission_state.source_operational_execution_boundary_summary",
                   "source_operational_execution_boundary_summary",
                   "source_result_artifact.operational_execution_boundary_summary"
                 ],
                 "contract" => "operational_execution_boundary_summary.v1",
                 "count" => 4,
                 "row_count" => 4,
                 "source_summary_model_counts" => %{
                   "artifact_only_operational_execution_boundary_summary" => 4
                 },
                 "source_summary_schema_contract_counts" => %{
                   "operational_execution_boundary_summary.v1" => 4
                 },
                 "source_artifact_type_counts" => %{"planned_activity.v1" => 4},
                 "readiness_level_counts" => %{"analysis_only" => 4},
                 "import_classification_counts" => %{"analysis_only" => 4},
                 "status_counts" => %{"analysis_only" => 4},
                 "import_ineligible_count" => 4,
                 "execution_boundary_counts" => %{"analysis_only_not_for_execution" => 4},
                 "analysis_mode_counts" => %{"simulation" => 4},
                 "analysis_mode_source_counts" => %{"root" => 4},
                 "handoff_only_count" => 4,
                 "execution_denied_count" => 4,
                 "cadence_write_denied_count" => 4,
                 "operator_authority_denied_count" => 4,
                 "gate_count" => 20,
                 "passed_gate_count" => 16,
                 "analysis_gate_count" => 4,
                 "non_passed_gate_count" => 4,
                 "non_passed_gate_ids" => ["operational_mode"],
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["ops_execution_boundary_summary"]
               }
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = CandidateRefresh.operational_readiness_replay_summary(refresh)

    assert replay_summary["contract"] == "operational_execution_boundary_summary.v1"
    assert replay_summary["source_report_count"] == 4
    assert replay_summary["source_report_row_count"] == 4
    assert replay_summary["import_ineligible_count"] == 4

    assert replay_summary["execution_boundary_counts"] == %{
             "analysis_only_not_for_execution" => 4
           }

    assert replay_summary["analysis_mode_counts"] == %{"simulation" => 4}
    assert replay_summary["analysis_mode_source_counts"] == %{"root" => 4}
    assert replay_summary["handoff_only_count"] == 4
    assert replay_summary["execution_denied_count"] == 4
    assert replay_summary["cadence_write_denied_count"] == 4
    assert replay_summary["operator_authority_denied_count"] == 4
    assert replay_summary["non_passed_gate_count"] == 4
    assert replay_summary["non_passed_gate_ids"] == ["operational_mode"]
    assert replay_summary["trust_boundary_status"] == "declared"
    assert replay_summary["trust_boundaries"] == ["ops_execution_boundary_summary"]
    assert replay_summary["branch_local_review_pressure"]
    assert replay_summary["branch_local_import_pressure"]
    assert replay_summary["branch_local_execution_boundary_pressure"]
    refute replay_summary["branch_local_resource_pressure"]

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert CandidateRefresh.operational_readiness_replay_summary(artifact) == replay_summary
  end

  test "source report summary replays wrapped operational execution boundary summaries" do
    direct_summary =
      operational_execution_boundary_summary_fixture()
      |> Map.put("source", "ops_execution.direct")

    nested_summary =
      operational_execution_boundary_summary_fixture()
      |> Map.put("source", "ops_execution.nested")

    refresh = %{
      "source_result_artifact" => [
        direct_summary,
        %{
          "schema_contract" => "result_artifact.v1",
          "operational_execution_boundary_summary" => nested_summary
        }
      ]
    }

    source_summary = CandidateRefresh.source_report_summary(refresh)

    assert get_in(source_summary, ["source_reports", "operational_readiness_report", "paths"]) ==
             [
               "source_result_artifact[0]",
               "source_result_artifact[1].operational_execution_boundary_summary"
             ]

    assert get_in(source_summary, ["source_reports", "operational_readiness_report", "contract"]) ==
             "operational_execution_boundary_summary.v1"

    assert get_in(source_summary, ["source_reports", "operational_readiness_report", "count"]) ==
             2

    assert get_in(source_summary, ["source_reports", "operational_readiness_report", "row_count"]) ==
             2

    assert get_in(source_summary, [
             "source_reports",
             "operational_readiness_report",
             "execution_denied_count"
           ]) == 2

    replay_summary = CandidateRefresh.operational_readiness_replay_summary(refresh)

    assert replay_summary["source_report_paths"] == [
             "source_result_artifact[0]",
             "source_result_artifact[1].operational_execution_boundary_summary"
           ]

    assert replay_summary["contract"] == "operational_execution_boundary_summary.v1"
    assert replay_summary["execution_denied_count"] == 2
    assert replay_summary["branch_local_execution_boundary_pressure"]
  end

  defp operational_execution_boundary_summary_fixture do
    %{
      "schema_contract" => "operational_execution_boundary_summary.v1",
      "model" => "artifact_only_operational_execution_boundary_summary",
      "source" => "operational_readiness_report.v1",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "activity_1",
      "readiness_level" => "analysis_only",
      "import_classification" => "analysis_only",
      "status" => "analysis_only",
      "import_eligible" => false,
      "handoff_only" => true,
      "execution_allowed" => false,
      "cadence_write_allowed" => false,
      "operator_authority_granted" => false,
      "execution_boundary" => "analysis_only_not_for_execution",
      "analysis_mode" => "simulation",
      "analysis_mode_source" => "root",
      "operational_mode_gate" => %{
        "id" => "operational_mode",
        "status" => "analysis_only",
        "classification" => "analysis_only",
        "analysis_mode" => "simulation",
        "analysis_mode_source" => "root"
      },
      "gate_count" => 5,
      "passed_gate_count" => 4,
      "review_gate_count" => 0,
      "analysis_gate_count" => 1,
      "blocked_gate_count" => 0,
      "non_passed_gate_count" => 1,
      "non_passed_gate_ids" => ["operational_mode"],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write_no_command_execution",
        "source" => "operational_readiness_report.v1",
        "operator_authority" => "not_granted_by_execution_boundary_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "model_limits" => [
        "operational_execution_boundary_summary_routes_only",
        "operational_execution_boundary_summary_does_not_execute_or_import"
      ],
      "provenance" => %{"trust_boundary" => "ops_execution_boundary_summary"}
    }
  end
end
