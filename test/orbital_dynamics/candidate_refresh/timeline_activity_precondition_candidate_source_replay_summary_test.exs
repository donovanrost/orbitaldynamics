defmodule OrbitalDynamics.CandidateRefresh.TimelineActivityPreconditionCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "timeline activity precondition replay reads branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_activity_precondition_summary" => %{
              "contract" => "timeline_activity_precondition_summary.v1",
              "count" => 1,
              "row_count" => 3,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_activity_precondition_summary"
              ],
              "source_summary_model_counts" => %{
                "artifact_only_timeline_activity_precondition_summary" => 1
              },
              "source_summary_schema_contract_counts" => %{
                "timeline_activity_precondition_summary.v1" => 1
              },
              "precondition_status_counts" => %{"blocked" => 2, "review_required" => 1},
              "blocked_precondition_count" => 2,
              "review_precondition_count" => 1,
              "blocked_precondition_type_counts" => %{"dependency_missing" => 1},
              "review_precondition_type_counts" => %{"degraded_mode" => 1},
              "invalid_activity_input_count" => 1,
              "invalid_activity_input_reason_counts" => %{"missing_activity_type" => 1},
              "invalid_activity_input_reasons" => ["missing_activity_type"],
              "activity_id_counts" => %{"branch_precondition_activity" => 3},
              "timeline_id_counts" => %{"timeline:branch_precondition_activity" => 3},
              "dependency_activity_id_counts" => %{"branch_dependency" => 1},
              "dependency_timeline_id_counts" => %{"timeline:branch_dependency" => 1},
              "exclusive_with_activity_id_counts" => %{"branch_exclusive" => 1},
              "exclusive_with_timeline_id_counts" => %{"timeline:branch_exclusive" => 1},
              "allow_overlap_counts" => %{"false" => 1},
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_activity_precondition"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.timeline_activity_precondition_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_precondition_summary"

    assert summary["contract"] == "timeline_activity_precondition_summary.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 3

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_activity_precondition_summary"
           ]

    assert summary["source_summary_model_counts"] == %{
             "artifact_only_timeline_activity_precondition_summary" => 1
           }

    assert summary["source_summary_schema_contract_counts"] == %{
             "timeline_activity_precondition_summary.v1" => 1
           }

    assert summary["precondition_status_counts"] == %{"blocked" => 2, "review_required" => 1}
    assert summary["blocked_precondition_count"] == 2
    assert summary["review_precondition_count"] == 1
    assert summary["blocked_precondition_type_counts"] == %{"dependency_missing" => 1}
    assert summary["review_precondition_type_counts"] == %{"degraded_mode" => 1}
    assert summary["invalid_activity_input_count"] == 1
    assert summary["invalid_activity_input_reason_counts"] == %{"missing_activity_type" => 1}
    assert summary["invalid_activity_input_reasons"] == ["missing_activity_type"]
    assert summary["activity_id_counts"] == %{"branch_precondition_activity" => 3}
    assert summary["timeline_id_counts"] == %{"timeline:branch_precondition_activity" => 3}
    assert summary["dependency_activity_id_counts"] == %{"branch_dependency" => 1}
    assert summary["dependency_timeline_id_counts"] == %{"timeline:branch_dependency" => 1}
    assert summary["exclusive_with_activity_id_counts"] == %{"branch_exclusive" => 1}
    assert summary["exclusive_with_timeline_id_counts"] == %{"timeline:branch_exclusive" => 1}
    assert summary["allow_overlap_counts"] == %{"false" => 1}
    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_activity_precondition"]
    assert summary["branch_local_timeline_activity_precondition_pressure"]
    assert summary["branch_local_activity_precondition_review_pressure"]
    assert summary["branch_local_activity_precondition_dependency_pressure"]
    assert summary["branch_local_activity_precondition_exclusivity_pressure"]
    assert summary["branch_local_activity_precondition_invalid_input_pressure"]
    assert summary["branch_local_activity_precondition_routing_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_activity_precondition_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_timeline_activity_precondition_replay_summary(
             artifact
           ) == summary
  end

  test "timeline activity precondition replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "timeline_activity_precondition_summary" => %{
            "contract" => "timeline_activity_precondition_summary.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_timeline_activity_precondition_summary"
            ],
            "precondition_status_counts" => %{"blocked" => 1},
            "activity_id_counts" => %{"direct_precondition_activity" => 1},
            "dependency_activity_id_counts" => %{"direct_dependency" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_activity_precondition_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_precondition_summary"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_activity_precondition_summary"
           ]

    assert summary["precondition_status_counts"] == %{"blocked" => 1}
    assert summary["activity_id_counts"] == %{"direct_precondition_activity" => 1}
    assert summary["dependency_activity_id_counts"] == %{"direct_dependency" => 1}
    assert summary["branch_local_timeline_activity_precondition_pressure"]
    assert summary["branch_local_activity_precondition_dependency_pressure"]
    assert summary["branch_local_activity_precondition_routing_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_activity_precondition_candidate_source_report_summary_only"
  end

  test "timeline activity precondition replay falls back to provenance when branch summary lacks usable family" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_activity_precondition_summary" => %{},
            "timeline_activity_state" => %{
              "contract" => "timeline_activity_state.v1",
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_activity_state"
              ]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_activity_precondition_summary" => %{
            "contract" => "timeline_activity_precondition_summary.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_timeline_activity_precondition_summary"],
            "activity_id_counts" => %{"provenance_precondition_activity" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_activity_precondition_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.timeline_activity_precondition_summary"

    assert summary["source_report_paths"] == ["source_timeline_activity_precondition_summary"]
    assert summary["activity_id_counts"] == %{"provenance_precondition_activity" => 1}
    assert summary["branch_local_timeline_activity_precondition_pressure"]
    assert summary["branch_local_activity_precondition_routing_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_activity_precondition_summary_source_report_provenance_only"
  end

  test "timeline activity precondition replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_activity_precondition_summary" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_activity_precondition_summary"
              ],
              "dependency_activity_id_counts" => %{"branch_dependency" => 1}
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_activity_precondition_summary" => %{
            "contract" => "timeline_activity_precondition_summary.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_timeline_activity_precondition_summary"],
            "activity_id_counts" => %{"provenance_precondition_activity" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_activity_precondition_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_precondition_summary"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_activity_precondition_summary"
           ]

    assert summary["activity_id_counts"] == %{}
    assert summary["dependency_activity_id_counts"] == %{"branch_dependency" => 1}
    assert summary["contract"] == "timeline_activity_precondition_summary.v1"
    assert summary["branch_local_timeline_activity_precondition_pressure"]
    assert summary["branch_local_activity_precondition_dependency_pressure"]
    refute summary["branch_local_activity_precondition_routing_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_activity_precondition_candidate_source_report_summary_only"
  end
end
