defmodule OrbitalDynamics.CandidateRefresh.OperationalReadinessImportEligibilityReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary replays compact operational import eligibility summaries" do
    summary = operational_import_eligibility_summary_fixture()

    refresh = %{
      "accepted_planning_state" => %{"operational_import_eligibility_summary" => summary},
      "mission_state" => %{"source_operational_import_eligibility_summary" => summary},
      "source_operational_import_eligibility_summary" => summary,
      "source_result_artifact" => %{"operational_import_eligibility_summary" => summary}
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_counts_by_contract" => %{
               "operational_import_eligibility_summary.v1" => 4
             },
             "source_report_row_counts_by_contract" => %{
               "operational_import_eligibility_summary.v1" => 4
             },
             "source_report_operational_readiness_contract" =>
               "operational_import_eligibility_summary.v1",
             "source_report_operational_readiness_count" => 4,
             "source_report_operational_readiness_row_count" => 4,
             "source_report_operational_readiness_paths" => [
               "accepted_planning_state.operational_import_eligibility_summary",
               "mission_state.source_operational_import_eligibility_summary",
               "source_operational_import_eligibility_summary",
               "source_result_artifact.operational_import_eligibility_summary"
             ],
             "source_report_operational_readiness_readiness_level_counts" => %{
               "operator_review" => 4
             },
             "source_report_operational_readiness_import_classification_counts" => %{
               "review_only" => 4
             },
             "source_report_operational_readiness_status_counts" => %{
               "review_required" => 4
             },
             "source_report_operational_readiness_gate_count" => 20,
             "source_report_operational_readiness_passed_gate_count" => 8,
             "source_report_operational_readiness_review_gate_count" => 4,
             "source_report_operational_readiness_analysis_gate_count" => 4,
             "source_report_operational_readiness_blocked_gate_count" => 4,
             "source_reports" => %{
               "operational_readiness_report" => %{
                 "paths" => [
                   "accepted_planning_state.operational_import_eligibility_summary",
                   "mission_state.source_operational_import_eligibility_summary",
                   "source_operational_import_eligibility_summary",
                   "source_result_artifact.operational_import_eligibility_summary"
                 ],
                 "contract" => "operational_import_eligibility_summary.v1",
                 "count" => 4,
                 "row_count" => 4,
                 "source_summary_model_counts" => %{
                   "artifact_only_import_eligibility_summary" => 4
                 },
                 "source_summary_schema_contract_counts" => %{
                   "operational_import_eligibility_summary.v1" => 4
                 },
                 "source_artifact_type_counts" => %{"planned_activity.v1" => 4},
                 "readiness_level_counts" => %{"operator_review" => 4},
                 "import_classification_counts" => %{"review_only" => 4},
                 "status_counts" => %{"review_required" => 4},
                 "import_ineligible_count" => 4,
                 "gate_count" => 20,
                 "passed_gate_count" => 8,
                 "review_gate_count" => 4,
                 "analysis_gate_count" => 4,
                 "blocked_gate_count" => 4,
                 "non_passed_gate_count" => 12,
                 "non_passed_gate_ids" => [
                   "cadence_import",
                   "operational_mode",
                   "operator_review"
                 ],
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["ops_import_eligibility_summary"]
               }
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = CandidateRefresh.operational_readiness_replay_summary(refresh)

    assert replay_summary["contract"] == "operational_import_eligibility_summary.v1"
    assert replay_summary["source_report_count"] == 4
    assert replay_summary["source_report_row_count"] == 4
    assert replay_summary["import_eligible_count"] == 0
    assert replay_summary["import_ineligible_count"] == 4
    assert replay_summary["gate_count"] == 20
    assert replay_summary["passed_gate_count"] == 8
    assert replay_summary["review_gate_count"] == 4
    assert replay_summary["analysis_gate_count"] == 4
    assert replay_summary["blocked_gate_count"] == 4
    assert replay_summary["non_passed_gate_count"] == 12

    assert replay_summary["non_passed_gate_ids"] == [
             "cadence_import",
             "operational_mode",
             "operator_review"
           ]

    assert replay_summary["trust_boundary_status"] == "declared"
    assert replay_summary["trust_boundaries"] == ["ops_import_eligibility_summary"]
    assert replay_summary["branch_local_review_pressure"]
    assert replay_summary["branch_local_import_pressure"]
    refute replay_summary["branch_local_resource_pressure"]

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert CandidateRefresh.operational_readiness_replay_summary(artifact) == replay_summary
  end

  test "source report summary replays wrapped operational import eligibility summaries" do
    direct_summary =
      operational_import_eligibility_summary_fixture()
      |> Map.put("source", "ops_import.direct")

    nested_summary =
      operational_import_eligibility_summary_fixture()
      |> Map.put("source", "ops_import.nested")

    refresh = %{
      "source_result_artifact" => [
        direct_summary,
        %{
          "schema_contract" => "result_artifact.v1",
          "operational_import_eligibility_summary" => nested_summary
        }
      ]
    }

    source_summary = CandidateRefresh.source_report_summary(refresh)

    assert get_in(source_summary, ["source_reports", "operational_readiness_report", "paths"]) ==
             [
               "source_result_artifact[0]",
               "source_result_artifact[1].operational_import_eligibility_summary"
             ]

    assert get_in(source_summary, ["source_reports", "operational_readiness_report", "contract"]) ==
             "operational_import_eligibility_summary.v1"

    assert get_in(source_summary, ["source_reports", "operational_readiness_report", "count"]) ==
             2

    assert get_in(source_summary, ["source_reports", "operational_readiness_report", "row_count"]) ==
             2

    assert get_in(source_summary, [
             "source_reports",
             "operational_readiness_report",
             "import_ineligible_count"
           ]) == 2

    assert get_in(source_summary, [
             "source_reports",
             "operational_readiness_report",
             "non_passed_gate_count"
           ]) == 6

    replay_summary = CandidateRefresh.operational_readiness_replay_summary(refresh)

    assert replay_summary["source_report_paths"] == [
             "source_result_artifact[0]",
             "source_result_artifact[1].operational_import_eligibility_summary"
           ]

    assert replay_summary["contract"] == "operational_import_eligibility_summary.v1"
    assert replay_summary["import_ineligible_count"] == 2
    assert replay_summary["non_passed_gate_count"] == 6
    assert replay_summary["branch_local_import_pressure"]
  end

  defp operational_import_eligibility_summary_fixture do
    %{
      "schema_contract" => "operational_import_eligibility_summary.v1",
      "model" => "artifact_only_import_eligibility_summary",
      "source" => "operational_readiness_report.v1",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "activity_1",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "status" => "review_required",
      "import_eligible" => false,
      "gate_count" => 5,
      "passed_gate_count" => 2,
      "review_gate_count" => 1,
      "analysis_gate_count" => 1,
      "blocked_gate_count" => 1,
      "non_passed_gate_count" => 3,
      "non_passed_gates" => [
        %{"id" => "operational_mode"},
        %{"id" => "operator_review"},
        %{"id" => "cadence_import"}
      ],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "operational_readiness_report.v1",
        "operator_authority" => "not_granted_by_summary"
      },
      "model_limits" => [
        "operational_import_eligibility_summary_routes_only",
        "operational_import_eligibility_summary_does_not_approve_or_import"
      ],
      "provenance" => %{"trust_boundary" => "ops_import_eligibility_summary"}
    }
  end
end
