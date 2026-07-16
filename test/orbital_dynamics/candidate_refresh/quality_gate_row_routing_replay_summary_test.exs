defmodule OrbitalDynamics.CandidateRefresh.QualityGateRowRoutingReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "quality gate replay derives raw provenance row routing from status maps" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "quality_gate_report" => %{
            "contract" => "quality_gate_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.quality_gate_report"],
            "review_gate_count" => 0,
            "blocked_gate_count" => 0,
            "quality_gate_row_ids_by_status" => %{
              "review_required" => ["quality_gate:raw:review"],
              "blocked" => ["quality_gate:raw:blocked"],
              "passed" => ["quality_gate:raw:ready"],
              "analysis_only" => ["quality_gate:raw:analysis"]
            },
            "review_required_quality_gate_row_ids" => ["stale_review"],
            "blocked_quality_gate_row_ids" => ["stale_blocked"],
            "ready_quality_gate_row_ids" => ["stale_ready"],
            "analysis_only_quality_gate_row_ids" => ["stale_analysis"]
          }
        }
      }
    }

    assert %{
             "source_report_quality_gate_review_required_quality_gate_row_ids" => [
               "quality_gate:raw:review"
             ],
             "source_report_quality_gate_blocked_quality_gate_row_ids" => [
               "quality_gate:raw:blocked"
             ],
             "source_report_quality_gate_ready_quality_gate_row_ids" => [
               "quality_gate:raw:ready"
             ],
             "source_report_quality_gate_analysis_only_quality_gate_row_ids" => [
               "quality_gate:raw:analysis"
             ]
           } = CandidateRefresh.source_report_summary(artifact)

    assert %{
             "quality_gate_row_ids_by_status" => %{
               "review_required" => ["quality_gate:raw:review"],
               "blocked" => ["quality_gate:raw:blocked"],
               "passed" => ["quality_gate:raw:ready"],
               "analysis_only" => ["quality_gate:raw:analysis"]
             },
             "review_required_quality_gate_row_ids" => ["quality_gate:raw:review"],
             "blocked_quality_gate_row_ids" => ["quality_gate:raw:blocked"],
             "ready_quality_gate_row_ids" => ["quality_gate:raw:ready"],
             "analysis_only_quality_gate_row_ids" => ["quality_gate:raw:analysis"]
           } = CandidateRefresh.quality_gate_replay_summary(artifact)
  end

  test "source report summary derives direct compact quality-gate summary row routing from status maps" do
    refresh = %{
      "source_operational_quality_gate_summary" => %{
        "schema_contract" => "operational_quality_gate_summary.v1",
        "model" => "artifact_only_quality_gate_summary",
        "rows" => [],
        "quality_gate_row_ids_by_status" => %{
          "review_required" => ["quality_gate:direct:review"],
          "blocked" => ["quality_gate:direct:blocked"],
          "passed" => ["quality_gate:direct:ready"],
          "analysis_only" => ["quality_gate:direct:analysis"]
        },
        "review_required_quality_gate_row_ids" => ["stale_review"],
        "blocked_quality_gate_row_ids" => ["stale_blocked"],
        "ready_quality_gate_row_ids" => ["stale_ready"],
        "analysis_only_quality_gate_row_ids" => ["stale_analysis"]
      }
    }

    assert %{
             "source_report_quality_gate_review_required_quality_gate_row_ids" => [
               "quality_gate:direct:review"
             ],
             "source_report_quality_gate_blocked_quality_gate_row_ids" => [
               "quality_gate:direct:blocked"
             ],
             "source_report_quality_gate_ready_quality_gate_row_ids" => [
               "quality_gate:direct:ready"
             ],
             "source_report_quality_gate_analysis_only_quality_gate_row_ids" => [
               "quality_gate:direct:analysis"
             ],
             "source_reports" => %{
               "quality_gate_report" => %{
                 "review_required_quality_gate_row_ids" => ["quality_gate:direct:review"],
                 "blocked_quality_gate_row_ids" => ["quality_gate:direct:blocked"],
                 "ready_quality_gate_row_ids" => ["quality_gate:direct:ready"],
                 "analysis_only_quality_gate_row_ids" => ["quality_gate:direct:analysis"]
               }
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert CandidateRefresh.quality_gate_replay_summary(artifact) ==
             CandidateRefresh.quality_gate_replay_summary(refresh)
  end

  test "quality gate replay lets empty status maps block stale row routing arrays" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "quality_gate_report" => %{
            "contract" => "quality_gate_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.quality_gate_report"],
            "review_gate_count" => 0,
            "blocked_gate_count" => 0,
            "quality_gate_row_ids_by_status" => %{},
            "review_required_quality_gate_row_ids" => ["stale_review"],
            "blocked_quality_gate_row_ids" => ["stale_blocked"],
            "ready_quality_gate_row_ids" => ["stale_ready"],
            "analysis_only_quality_gate_row_ids" => ["stale_analysis"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.quality_gate_replay_summary(artifact)

    assert Map.get(
             source_summary,
             "source_report_quality_gate_review_required_quality_gate_row_ids",
             []
           ) == []

    assert Map.get(
             source_summary,
             "source_report_quality_gate_blocked_quality_gate_row_ids",
             []
           ) == []

    assert Map.get(source_summary, "source_report_quality_gate_ready_quality_gate_row_ids", []) ==
             []

    assert Map.get(
             source_summary,
             "source_report_quality_gate_analysis_only_quality_gate_row_ids",
             []
           ) == []

    assert replay_summary["quality_gate_row_ids_by_status"] == %{}
    assert replay_summary["review_required_quality_gate_row_ids"] == []
    assert replay_summary["blocked_quality_gate_row_ids"] == []
    assert replay_summary["ready_quality_gate_row_ids"] == []
    assert replay_summary["analysis_only_quality_gate_row_ids"] == []
  end

  test "source report summary lets direct compact summary empty status maps block stale row routing arrays" do
    refresh = %{
      "source_operational_quality_gate_summary" => %{
        "schema_contract" => "operational_quality_gate_summary.v1",
        "model" => "artifact_only_quality_gate_summary",
        "rows" => [],
        "quality_gate_row_ids_by_status" => %{},
        "review_required_quality_gate_row_ids" => ["stale_review"],
        "blocked_quality_gate_row_ids" => ["stale_blocked"],
        "ready_quality_gate_row_ids" => ["stale_ready"],
        "analysis_only_quality_gate_row_ids" => ["stale_analysis"]
      }
    }

    source_summary = CandidateRefresh.source_report_summary(refresh)

    assert get_in(source_summary, [
             "source_reports",
             "quality_gate_report",
             "review_required_quality_gate_row_ids"
           ]) in [nil, []]

    assert get_in(source_summary, [
             "source_reports",
             "quality_gate_report",
             "blocked_quality_gate_row_ids"
           ]) in [nil, []]

    assert get_in(source_summary, [
             "source_reports",
             "quality_gate_report",
             "ready_quality_gate_row_ids"
           ]) in [nil, []]

    assert get_in(source_summary, [
             "source_reports",
             "quality_gate_report",
             "analysis_only_quality_gate_row_ids"
           ]) in [nil, []]
  end
end
