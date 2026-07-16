defmodule OrbitalDynamics.CandidateRefresh.CandidateDiffCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "candidate diff replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "candidate_diff_report" => %{
              "contract" => "candidate_diff_report.v1",
              "count" => 1,
              "row_count" => 3,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_candidate_diff_report"
              ],
              "retained_candidate_count" => 1,
              "new_candidate_count" => 1,
              "invalidated_candidate_count" => 1,
              "diff_reason_counts" => %{
                "not_present_in_prior_candidate_set" => 1,
                "present_in_prior_candidate_set_with_semantic_changes" => 1
              },
              "invalidated_reason_counts" => %{
                "not_present_in_refreshed_candidate_set" => 1
              },
              "semantic_change_reason_counts" => %{
                "contact_window_shifted" => 1
              },
              "candidate_diff_changed_field_counts" => %{
                "starts_at_s" => 1
              },
              "candidate_diff_candidate_id_counts" => %{
                "branch_new_candidate" => 1,
                "branch_retained_candidate" => 1,
                "branch_stale_candidate" => 1
              },
              "candidate_diff_ground_station_counts" => %{
                "equator_prime" => 2,
                "polar_prime" => 1
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_candidate_diff"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.candidate_diff_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.candidate_diff_report"

    assert summary["contract"] == "candidate_diff_report.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 3

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_candidate_diff_report"
           ]

    assert summary["retained_candidate_count"] == 1
    assert summary["new_candidate_count"] == 1
    assert summary["invalidated_candidate_count"] == 1

    assert summary["diff_reason_counts"] == %{
             "not_present_in_prior_candidate_set" => 1,
             "present_in_prior_candidate_set_with_semantic_changes" => 1
           }

    assert summary["invalidated_reason_counts"] == %{
             "not_present_in_refreshed_candidate_set" => 1
           }

    assert summary["semantic_change_reason_counts"] == %{
             "contact_window_shifted" => 1
           }

    assert summary["candidate_diff_changed_field_counts"] == %{
             "starts_at_s" => 1
           }

    assert summary["candidate_diff_candidate_id_counts"] == %{
             "branch_new_candidate" => 1,
             "branch_retained_candidate" => 1,
             "branch_stale_candidate" => 1
           }

    assert summary["candidate_diff_ground_station_counts"] == %{
             "equator_prime" => 2,
             "polar_prime" => 1
           }

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_candidate_diff"]
    assert summary["branch_local_diff_pressure"]
    assert summary["branch_local_new_candidate_pressure"]
    assert summary["branch_local_invalidated_candidate_pressure"]
    assert summary["branch_local_semantic_change_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "candidate_diff_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_candidate_diff_replay_summary(artifact) ==
             summary
  end

  test "candidate diff replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "candidate_diff_report" => %{
            "contract" => "candidate_diff_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_candidate_diff_report"
            ],
            "diff_reason_counts" => %{"not_present_in_prior_candidate_set" => 1},
            "candidate_diff_candidate_id_counts" => %{"direct_candidate" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.candidate_diff_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.candidate_diff_report"

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_candidate_diff_report"
           ]

    assert summary["diff_reason_counts"] == %{"not_present_in_prior_candidate_set" => 1}
    assert summary["candidate_diff_candidate_id_counts"] == %{"direct_candidate" => 1}
    assert summary["branch_local_diff_pressure"]
    assert summary["branch_local_new_candidate_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "candidate_diff_candidate_source_report_summary_only"
  end

  test "candidate diff replay falls back when branch summary is empty" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{"candidate_diff_report" => %{}}
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "candidate_diff_report" => %{
            "contract" => "candidate_diff_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["provenance.source_reports.candidate_diff_report"],
            "diff_reason_counts" => %{"provenance_reason" => 1},
            "candidate_diff_candidate_id_counts" => %{"provenance_candidate" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.candidate_diff_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.candidate_diff_report"

    assert summary["source_report_paths"] == [
             "provenance.source_reports.candidate_diff_report"
           ]

    assert summary["diff_reason_counts"] == %{"provenance_reason" => 1}
    assert summary["candidate_diff_candidate_id_counts"] == %{"provenance_candidate" => 1}
    assert summary["branch_local_diff_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "candidate_diff_source_report_provenance_only"
  end

  test "candidate diff replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "candidate_diff_report" => %{
              "contract" => "candidate_diff_report.v1",
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_candidate_diff_report"
              ],
              "semantic_change_reason_counts" => %{"station_reservation_changed" => 1}
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "candidate_diff_report" => %{
            "contract" => "candidate_diff_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["provenance.source_reports.candidate_diff_report"],
            "retained_candidate_count" => 9,
            "new_candidate_count" => 9,
            "invalidated_candidate_count" => 9,
            "diff_reason_counts" => %{"provenance_reason" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.candidate_diff_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.candidate_diff_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_candidate_diff_report"
           ]

    assert summary["retained_candidate_count"] == 0
    assert summary["new_candidate_count"] == 0
    assert summary["invalidated_candidate_count"] == 0
    assert summary["diff_reason_counts"] == %{}

    assert summary["semantic_change_reason_counts"] == %{
             "station_reservation_changed" => 1
           }

    assert summary["branch_local_diff_pressure"]
    refute summary["branch_local_new_candidate_pressure"]
    refute summary["branch_local_invalidated_candidate_pressure"]
    assert summary["branch_local_semantic_change_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "candidate_diff_candidate_source_report_summary_only"
  end
end
