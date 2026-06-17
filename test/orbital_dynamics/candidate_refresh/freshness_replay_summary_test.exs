defmodule OrbitalDynamics.CandidateRefresh.FreshnessReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary aggregates freshness routing maps" do
    refresh = %{
      "source_freshness_report" => [
        %{
          "schema_contract" => "freshness_report.v1",
          "status" => "stale",
          "stale_reasons" => [
            "accepted_snapshot_older_than_policy",
            "horizon_start_before_now"
          ],
          "provenance" => %{"trust_boundary" => "ops_freshness"}
        },
        %{
          "schema_contract" => "freshness_report.v1",
          "freshness_status" => "unknown",
          "unknown_reasons" => ["missing_generated_at"],
          "provenance" => %{"trust_boundary" => "ops_freshness"}
        }
      ]
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 2,
             "source_report_row_count" => 2,
             "source_report_freshness_contract" => "freshness_report.v1",
             "source_report_freshness_count" => 2,
             "source_report_freshness_row_count" => 2,
             "source_report_freshness_paths" => [
               "source_freshness_report[0]",
               "source_freshness_report[1]"
             ],
             "source_report_freshness_status_counts" => %{
               "stale" => 1,
               "unknown" => 1
             },
             "source_report_freshness_stale_reason_count" => 2,
             "source_report_freshness_stale_reasons" => [
               "accepted_snapshot_older_than_policy",
               "horizon_start_before_now"
             ],
             "source_report_freshness_stale_reason_counts" => %{
               "accepted_snapshot_older_than_policy" => 1,
               "horizon_start_before_now" => 1
             },
             "source_report_freshness_unknown_reason_count" => 1,
             "source_report_freshness_unknown_reasons" => ["missing_generated_at"],
             "source_report_freshness_unknown_reason_counts" => %{"missing_generated_at" => 1},
             "source_report_freshness_branch_local_stale_pressure" => true,
             "source_report_freshness_branch_local_unknown_pressure" => true,
             "source_report_freshness_branch_local_freshness_pressure" => true,
             "source_reports" => %{
               "freshness_report" => %{
                 "count" => 2,
                 "row_count" => 2,
                 "status_counts" => %{
                   "stale" => 1,
                   "unknown" => 1
                 },
                 "stale_reason_count" => 2,
                 "stale_reasons" => [
                   "accepted_snapshot_older_than_policy",
                   "horizon_start_before_now"
                 ],
                 "stale_reason_counts" => %{
                   "accepted_snapshot_older_than_policy" => 1,
                   "horizon_start_before_now" => 1
                 },
                 "unknown_reason_count" => 1,
                 "unknown_reasons" => ["missing_generated_at"],
                 "unknown_reason_counts" => %{"missing_generated_at" => 1}
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "model" => "artifact_only_candidate_refresh_freshness_replay_summary",
             "source" => "candidate_refresh.source_report_provenance.freshness_report",
             "contract" => "freshness_report.v1",
             "source_report_count" => 2,
             "source_report_row_count" => 2,
             "source_report_paths" => ["source_freshness_report[0]", "source_freshness_report[1]"],
             "status_counts" => %{
               "stale" => 1,
               "unknown" => 1
             },
             "stale_reason_count" => 2,
             "stale_reasons" => [
               "accepted_snapshot_older_than_policy",
               "horizon_start_before_now"
             ],
             "stale_reason_counts" => %{
               "accepted_snapshot_older_than_policy" => 1,
               "horizon_start_before_now" => 1
             },
             "unknown_reason_count" => 1,
             "unknown_reasons" => ["missing_generated_at"],
             "unknown_reason_counts" => %{"missing_generated_at" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["ops_freshness"],
             "branch_local_stale_pressure" => true,
             "branch_local_unknown_pressure" => true,
             "branch_local_freshness_pressure" => true,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
               "replay_scope" => "freshness_source_report_provenance_only",
               "operator_authority" => "not_granted_by_freshness_replay_summary",
               "import_approval" => "not_granted_by_freshness_replay_summary",
               "cadence_write" => "not_performed_by_summary",
               "candidate_generation" => "not_performed_by_summary"
             }
           } = replay_summary = CandidateRefresh.freshness_replay_summary(refresh)

    assert OrbitalDynamics.candidate_refresh_freshness_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" =>
          Map.put(summary["source_reports"], "quality_gate_report", %{
            "contract" => "quality_gate_report.v1",
            "count" => 1,
            "row_count" => 1,
            "status_counts" => %{"stale" => 99},
            "trust_boundary_status" => "declared"
          })
      }
    }

    assert %{
             "source_report_family_count" => 2,
             "source_report_freshness_contract" => "freshness_report.v1",
             "source_report_freshness_count" => 2,
             "source_report_freshness_row_count" => 2,
             "source_report_freshness_paths" => [
               "source_freshness_report[0]",
               "source_freshness_report[1]"
             ],
             "source_report_freshness_status_counts" => %{
               "stale" => 1,
               "unknown" => 1
             },
             "source_report_freshness_stale_reason_count" => 2,
             "source_report_freshness_stale_reasons" => [
               "accepted_snapshot_older_than_policy",
               "horizon_start_before_now"
             ],
             "source_report_freshness_stale_reason_counts" => %{
               "accepted_snapshot_older_than_policy" => 1,
               "horizon_start_before_now" => 1
             },
             "source_report_freshness_unknown_reason_count" => 1,
             "source_report_freshness_unknown_reasons" => ["missing_generated_at"],
             "source_report_freshness_unknown_reason_counts" => %{"missing_generated_at" => 1},
             "source_report_freshness_branch_local_stale_pressure" => true,
             "source_report_freshness_branch_local_unknown_pressure" => true,
             "source_report_freshness_branch_local_freshness_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.freshness_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_freshness_replay_summary(artifact) ==
             replay_summary
  end

  test "freshness replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.freshness_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_freshness_contract")
    refute Map.has_key?(source_summary, "source_report_freshness_count")
    refute Map.has_key?(source_summary, "source_report_freshness_row_count")
    refute Map.has_key?(source_summary, "source_report_freshness_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_stale_pressure"]
    refute summary["branch_local_unknown_pressure"]
    refute summary["branch_local_freshness_pressure"]
  end

  test "freshness source summary keeps declared contract without partial identity placeholders" do
    placeholder_fields = [
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.freshness_report"]},
      %{"count" => nil, "row_count" => 2},
      %{"count" => 1, "row_count" => nil}
    ]

    for placeholder <- placeholder_fields do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "freshness_report" =>
              Map.put(
                placeholder,
                "contract",
                "freshness_report.v1"
              )
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      assert source_summary["source_report_freshness_contract"] ==
               "freshness_report.v1"

      refute Map.has_key?(source_summary, "source_report_freshness_count")
      refute Map.has_key?(source_summary, "source_report_freshness_row_count")
      refute Map.has_key?(source_summary, "source_report_freshness_paths")
    end
  end

  test "freshness source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "freshness_report" => %{
            "contract" => "freshness_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.freshness_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_freshness_contract"] == "freshness_report.v1"
    assert source_summary["source_report_freshness_count"] == 0
    assert source_summary["source_report_freshness_row_count"] == 0

    assert source_summary["source_report_freshness_paths"] == [
             "provenance.source_reports.freshness_report"
           ]
  end

  test "freshness source summary omits missing identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "freshness_report" => %{
            "contract" => "freshness_report.v1",
            "count" => 1,
            "row_count" => 2
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_freshness_contract"] == "freshness_report.v1"
    assert source_summary["source_report_freshness_count"] == 1
    assert source_summary["source_report_freshness_row_count"] == 2
    refute Map.has_key?(source_summary, "source_report_freshness_paths")
  end

  test "freshness source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "freshness_report" => %{
            "contract" => "freshness_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_freshness_contract"] == "freshness_report.v1"
    assert source_summary["source_report_freshness_count"] == 1
    assert source_summary["source_report_freshness_row_count"] == 2
    assert source_summary["source_report_freshness_paths"] == []
  end

  test "freshness replay treats reason lists and maps as freshness pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "freshness_report" => %{
            "contract" => "freshness_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["provenance.source_reports.freshness_report"],
            "status_counts" => %{},
            "stale_reason_count" => 0,
            "unknown_reason_count" => 0,
            "stale_reasons" => ["accepted_snapshot_older_than_policy"],
            "stale_reason_counts" => %{"accepted_snapshot_older_than_policy" => 1},
            "unknown_reasons" => ["accepted_snapshot_age_unknown"],
            "unknown_reason_counts" => %{"accepted_snapshot_age_unknown" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.freshness_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1
    assert summary["source_report_paths"] == ["provenance.source_reports.freshness_report"]
    assert summary["status_counts"] == %{}
    assert summary["stale_reason_count"] == 0
    assert summary["unknown_reason_count"] == 0
    assert summary["stale_reasons"] == ["accepted_snapshot_older_than_policy"]
    assert summary["stale_reason_counts"] == %{"accepted_snapshot_older_than_policy" => 1}
    assert summary["unknown_reasons"] == ["accepted_snapshot_age_unknown"]
    assert summary["unknown_reason_counts"] == %{"accepted_snapshot_age_unknown" => 1}
    assert summary["branch_local_stale_pressure"]
    assert summary["branch_local_unknown_pressure"]
    assert summary["branch_local_freshness_pressure"]
  end

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
