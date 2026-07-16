defmodule OrbitalDynamics.CandidateRefresh.RefreshBudgetCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "refresh budget replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "refresh_budget_report" => %{
              "contract" => "refresh_budget_report.v1",
              "count" => 1,
              "row_count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_refresh_budget_report"
              ],
              "input_candidate_count" => 4,
              "kept_candidate_count" => 2,
              "dropped_candidate_count" => 0,
              "invalid_candidate_limit_policy_count" => 0,
              "invalid_candidate_limit_policy_reason_counts" => %{
                "max_candidate_activities_must_be_integer" => 1
              },
              "kept_candidate_ids" => ["branch_kept"],
              "dropped_candidate_ids" => ["branch_dropped"],
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_refresh_budget"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "refresh_budget_report" => %{
            "contract" => "refresh_budget_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["source_refresh_budget_report"],
            "input_candidate_count" => 0,
            "kept_candidate_count" => 0,
            "dropped_candidate_count" => 0,
            "invalid_candidate_limit_policy_count" => 0,
            "invalid_candidate_limit_policy_reason_counts" => %{},
            "kept_candidate_ids" => [],
            "dropped_candidate_ids" => []
          }
        }
      }
    }

    summary = CandidateRefresh.refresh_budget_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.refresh_budget_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_refresh_budget_report"
           ]

    assert summary["input_candidate_count"] == 4
    assert summary["kept_candidate_count"] == 2
    assert summary["dropped_candidate_count"] == 0
    assert summary["invalid_candidate_limit_policy_count"] == 0

    assert summary["invalid_candidate_limit_policy_reason_counts"] == %{
             "max_candidate_activities_must_be_integer" => 1
           }

    assert summary["kept_candidate_ids"] == ["branch_kept"]
    assert summary["dropped_candidate_ids"] == ["branch_dropped"]
    assert summary["trust_boundaries"] == ["branch_refresh_budget"]
    assert summary["branch_local_budget_pressure"]
    assert summary["branch_local_dropped_candidate_pressure"]
    assert summary["branch_local_invalid_limit_pressure"]
    assert summary["branch_local_candidate_limit_applied"]

    assert summary["assumptions"]["replay_scope"] ==
             "refresh_budget_candidate_source_report_summary_only"

    assert %{
             "source_report_refresh_budget_branch_local_budget_pressure" => true,
             "source_report_refresh_budget_branch_local_dropped_candidate_pressure" => true,
             "source_report_refresh_budget_branch_local_invalid_limit_pressure" => true,
             "source_report_refresh_budget_branch_local_candidate_limit_applied" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert OrbitalDynamics.candidate_refresh_refresh_budget_replay_summary(artifact) == summary
  end
end
