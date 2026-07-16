defmodule OrbitalDynamics.CandidateRefresh.FreshnessCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "freshness replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "freshness_report" => %{
              "contract" => "freshness_report.v1",
              "count" => 1,
              "row_count" => 1,
              "paths" => ["candidate_source.candidate_refresh_request.source_freshness_report"],
              "status_counts" => %{"stale" => 1},
              "stale_reason_count" => 0,
              "unknown_reason_count" => 0,
              "stale_reasons" => ["accepted_snapshot_older_than_policy"],
              "stale_reason_counts" => %{"accepted_snapshot_older_than_policy" => 1},
              "unknown_reasons" => ["accepted_snapshot_age_unknown"],
              "unknown_reason_counts" => %{"accepted_snapshot_age_unknown" => 1},
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_freshness"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "freshness_report" => %{
            "contract" => "freshness_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["source_freshness_report"],
            "status_counts" => %{},
            "stale_reason_count" => 0,
            "unknown_reason_count" => 0,
            "stale_reasons" => [],
            "unknown_reasons" => []
          }
        }
      }
    }

    summary = CandidateRefresh.freshness_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.freshness_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_freshness_report"
           ]

    assert summary["status_counts"] == %{"stale" => 1}
    assert summary["stale_reasons"] == ["accepted_snapshot_older_than_policy"]
    assert summary["stale_reason_counts"] == %{"accepted_snapshot_older_than_policy" => 1}
    assert summary["unknown_reasons"] == ["accepted_snapshot_age_unknown"]
    assert summary["unknown_reason_counts"] == %{"accepted_snapshot_age_unknown" => 1}
    assert summary["trust_boundaries"] == ["branch_freshness"]
    assert summary["branch_local_stale_pressure"]
    assert summary["branch_local_unknown_pressure"]
    assert summary["branch_local_freshness_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "freshness_candidate_source_report_summary_only"

    assert %{
             "source_report_freshness_branch_local_stale_pressure" => true,
             "source_report_freshness_branch_local_unknown_pressure" => true,
             "source_report_freshness_branch_local_freshness_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert OrbitalDynamics.candidate_refresh_freshness_replay_summary(artifact) == summary
  end
end
