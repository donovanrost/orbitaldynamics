defmodule OrbitalDynamics.CandidateRefresh.ModelAcceptanceCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "model acceptance replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "model_acceptance_report" => %{
              "contract" => "model_acceptance_report.v1",
              "count" => 1,
              "row_count" => 2,
              "record_count" => 2,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_model_acceptance_report"
              ],
              "intended_use_counts" => %{"operational_import" => 1},
              "status_counts" => %{"blocked" => 1, "review_required" => 1},
              "model_count" => 2,
              "accepted_count" => 0,
              "review_required_count" => 0,
              "blocked_count" => 0,
              "unknown_model_count" => 0,
              "validation_level_counts" => %{"unknown" => 1},
              "model_ids_by_status" => %{
                "blocked" => ["branch.missing_model"],
                "review_required" => ["branch.review_model"]
              },
              "model_ids_by_validation_level" => %{
                "unknown" => ["branch.missing_model"]
              },
              "model_ids_by_intended_use" => %{
                "operational_import" => ["branch.review_model", "branch.missing_model"]
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_model_acceptance"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "model_acceptance_report" => %{
            "contract" => "model_acceptance_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.model_acceptance_report"],
            "status_counts" => %{},
            "validation_level_counts" => %{},
            "model_ids_by_status" => %{},
            "model_ids_by_validation_level" => %{}
          }
        }
      }
    }

    summary = CandidateRefresh.model_acceptance_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.model_acceptance_report"

    assert summary["contract"] == "model_acceptance_report.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 2
    assert summary["source_report_record_count"] == 2

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_model_acceptance_report"
           ]

    assert summary["intended_use_counts"] == %{"operational_import" => 1}
    assert summary["status_counts"] == %{"blocked" => 1, "review_required" => 1}
    assert summary["model_count"] == 2
    assert summary["accepted_count"] == 0
    assert summary["review_required_count"] == 1
    assert summary["blocked_count"] == 1
    assert summary["unknown_model_count"] == 1
    assert summary["validation_level_counts"] == %{"unknown" => 1}

    assert summary["model_ids_by_status"] == %{
             "blocked" => ["branch.missing_model"],
             "review_required" => ["branch.review_model"]
           }

    assert summary["model_ids_by_validation_level"] == %{
             "unknown" => ["branch.missing_model"]
           }

    assert summary["model_ids_by_intended_use"] == %{
             "operational_import" => ["branch.review_model", "branch.missing_model"]
           }

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_model_acceptance"]
    assert summary["branch_local_review_pressure"]
    assert summary["branch_local_blocking_pressure"]
    assert summary["branch_local_unknown_model_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "model_acceptance_candidate_source_report_summary_only"

    assert %{
             "source_report_model_acceptance_branch_local_review_pressure" => true,
             "source_report_model_acceptance_branch_local_blocking_pressure" => true,
             "source_report_model_acceptance_branch_local_unknown_model_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert OrbitalDynamics.candidate_refresh_model_acceptance_replay_summary(artifact) ==
             summary
  end
end
