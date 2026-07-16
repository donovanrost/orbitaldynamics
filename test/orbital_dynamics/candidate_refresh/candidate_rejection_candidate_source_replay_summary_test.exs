defmodule OrbitalDynamics.CandidateRefresh.CandidateRejectionCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "candidate rejection replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "candidate_rejection_report" => %{
              "contract" => "candidate_rejection_report.v1",
              "count" => 1,
              "row_count" => 2,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_candidate_rejection_report"
              ],
              "rejected_count" => 1,
              "reviewable_count" => 1,
              "invalid_candidate_input_count" => 1,
              "rejection_reason_counts" => %{
                "invalid_candidate_input" => 1,
                "station_reserved" => 1
              },
              "required_operator_action_counts" => %{
                "none" => 1,
                "review_candidate_rejection" => 1
              },
              "candidate_rejection_candidate_id_counts" => %{
                "branch_bad_candidate" => 1,
                "branch_reserved_candidate" => 1
              },
              "candidate_rejection_ground_station_counts" => %{
                "equator_prime" => 1
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_candidate_rejection"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.candidate_rejection_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.candidate_rejection_report"

    assert summary["contract"] == "candidate_rejection_report.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 2

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_candidate_rejection_report"
           ]

    assert summary["rejected_count"] == 1
    assert summary["reviewable_count"] == 1
    assert summary["invalid_candidate_input_count"] == 1

    assert summary["rejection_reason_counts"] == %{
             "invalid_candidate_input" => 1,
             "station_reserved" => 1
           }

    assert summary["required_operator_action_counts"] == %{
             "none" => 1,
             "review_candidate_rejection" => 1
           }

    assert summary["candidate_rejection_candidate_id_counts"] == %{
             "branch_bad_candidate" => 1,
             "branch_reserved_candidate" => 1
           }

    assert summary["candidate_rejection_ground_station_counts"] == %{
             "equator_prime" => 1
           }

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_candidate_rejection"]
    assert summary["branch_local_rejection_pressure"]
    assert summary["branch_local_review_pressure"]
    assert summary["branch_local_invalid_input_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "candidate_rejection_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_candidate_rejection_replay_summary(artifact) ==
             summary
  end

  test "candidate rejection replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "candidate_rejection_report" => %{
            "contract" => "candidate_rejection_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_candidate_rejection_report"
            ],
            "rejection_reason_counts" => %{"resource_unavailable" => 1},
            "candidate_rejection_candidate_id_counts" => %{"direct_candidate" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.candidate_rejection_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.candidate_rejection_report"

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_candidate_rejection_report"
           ]

    assert summary["rejection_reason_counts"] == %{"resource_unavailable" => 1}
    assert summary["candidate_rejection_candidate_id_counts"] == %{"direct_candidate" => 1}
    assert summary["branch_local_rejection_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "candidate_rejection_candidate_source_report_summary_only"
  end

  test "candidate rejection replay falls back when branch summary is empty" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{"candidate_rejection_report" => %{}}
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "candidate_rejection_report" => %{
            "contract" => "candidate_rejection_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["provenance.source_reports.candidate_rejection_report"],
            "rejection_reason_counts" => %{"provenance_reason" => 1},
            "candidate_rejection_candidate_id_counts" => %{"provenance_candidate" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.candidate_rejection_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.candidate_rejection_report"

    assert summary["source_report_paths"] == [
             "provenance.source_reports.candidate_rejection_report"
           ]

    assert summary["rejection_reason_counts"] == %{"provenance_reason" => 1}
    assert summary["candidate_rejection_candidate_id_counts"] == %{"provenance_candidate" => 1}
    assert summary["branch_local_rejection_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "candidate_rejection_source_report_provenance_only"
  end

  test "candidate rejection replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "candidate_rejection_report" => %{
              "contract" => "candidate_rejection_report.v1",
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_candidate_rejection_report"
              ],
              "required_operator_action_counts" => %{"review_candidate_rejection" => 1}
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "candidate_rejection_report" => %{
            "contract" => "candidate_rejection_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["provenance.source_reports.candidate_rejection_report"],
            "rejected_count" => 9,
            "reviewable_count" => 9,
            "invalid_candidate_input_count" => 9,
            "rejection_reason_counts" => %{"provenance_reason" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.candidate_rejection_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.candidate_rejection_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_candidate_rejection_report"
           ]

    assert summary["rejected_count"] == 0
    assert summary["reviewable_count"] == 0
    assert summary["invalid_candidate_input_count"] == 0
    assert summary["rejection_reason_counts"] == %{}

    assert summary["required_operator_action_counts"] == %{
             "review_candidate_rejection" => 1
           }

    assert summary["branch_local_rejection_pressure"]
    assert summary["branch_local_review_pressure"]
    refute summary["branch_local_invalid_input_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "candidate_rejection_candidate_source_report_summary_only"
  end
end
