defmodule OrbitalDynamics.CandidateRefresh.TimelineIntegrityCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "timeline integrity replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_integrity_report" => %{
              "contract" => "timeline_integrity_report.v1",
              "count" => 1,
              "row_count" => 2,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_integrity_report"
              ],
              "timeline_integrity_issue_count" => 7,
              "timeline_integrity_review_count" => 2,
              "dependency_issue_count" => 4,
              "exclusivity_issue_count" => 3,
              "timeline_integrity_status_counts" => %{"review_required" => 2},
              "timeline_integrity_issue_type_counts" => %{
                "missing_dependency_activity" => 1,
                "exclusivity_overlap" => 1
              },
              "required_operator_action_counts" => %{"review_timeline_integrity" => 2},
              "operator_action_reason_counts" => %{"timeline_integrity_issue" => 2},
              "review_activity_id_counts" => %{"cmd_main" => 1, "dl_conflict" => 1},
              "review_timeline_id_counts" => %{
                "timeline:command:dss_14:10.0" => 1,
                "timeline:downlink:12.0" => 1
              },
              "missing_dependency_activity_id_counts" => %{"missing_gate" => 1},
              "missing_dependency_timeline_id_counts" => %{"timeline:missing_gate" => 1},
              "self_dependency_activity_id_counts" => %{"cmd_self" => 1},
              "self_dependency_timeline_id_counts" => %{"timeline:cmd_self" => 1},
              "dependency_cycle_activity_id_counts" => %{"cmd_cycle" => 1},
              "dependency_cycle_timeline_id_counts" => %{"timeline:cmd_cycle" => 1},
              "dependency_order_violation_activity_id_counts" => %{"cmd_order" => 1},
              "dependency_order_violation_timeline_id_counts" => %{"timeline:cmd_order" => 1},
              "exclusivity_violation_activity_id_counts" => %{"cmd_main" => 1},
              "exclusivity_violation_timeline_id_counts" => %{
                "timeline:command:dss_14:10.0" => 1
              },
              "exclusivity_violation_group_counts" => %{"conflict_group" => 1},
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_timeline_integrity"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.timeline_integrity_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_integrity_report"

    assert summary["contract"] == "timeline_integrity_report.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 2

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_integrity_report"
           ]

    assert summary["timeline_integrity_issue_count"] == 7
    assert summary["timeline_integrity_review_count"] == 2
    assert summary["dependency_issue_count"] == 4
    assert summary["exclusivity_issue_count"] == 3
    assert summary["timeline_integrity_status_counts"] == %{"review_required" => 2}

    assert summary["timeline_integrity_issue_type_counts"] == %{
             "missing_dependency_activity" => 1,
             "exclusivity_overlap" => 1
           }

    assert summary["required_operator_action_counts"] == %{"review_timeline_integrity" => 2}
    assert summary["operator_action_reason_counts"] == %{"timeline_integrity_issue" => 2}
    assert summary["review_activity_id_counts"] == %{"cmd_main" => 1, "dl_conflict" => 1}

    assert summary["review_timeline_id_counts"] == %{
             "timeline:command:dss_14:10.0" => 1,
             "timeline:downlink:12.0" => 1
           }

    assert summary["missing_dependency_activity_id_counts"] == %{"missing_gate" => 1}
    assert summary["missing_dependency_timeline_id_counts"] == %{"timeline:missing_gate" => 1}
    assert summary["self_dependency_activity_id_counts"] == %{"cmd_self" => 1}
    assert summary["self_dependency_timeline_id_counts"] == %{"timeline:cmd_self" => 1}
    assert summary["dependency_cycle_activity_id_counts"] == %{"cmd_cycle" => 1}
    assert summary["dependency_cycle_timeline_id_counts"] == %{"timeline:cmd_cycle" => 1}
    assert summary["dependency_order_violation_activity_id_counts"] == %{"cmd_order" => 1}

    assert summary["dependency_order_violation_timeline_id_counts"] == %{
             "timeline:cmd_order" => 1
           }

    assert summary["exclusivity_violation_activity_id_counts"] == %{"cmd_main" => 1}

    assert summary["exclusivity_violation_timeline_id_counts"] == %{
             "timeline:command:dss_14:10.0" => 1
           }

    assert summary["exclusivity_violation_group_counts"] == %{"conflict_group" => 1}
    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_timeline_integrity"]
    assert summary["branch_local_timeline_integrity_pressure"]
    assert summary["branch_local_timeline_integrity_review_pressure"]
    assert summary["branch_local_dependency_integrity_pressure"]
    assert summary["branch_local_exclusivity_integrity_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_integrity_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_timeline_integrity_replay_summary(artifact) ==
             summary
  end

  test "timeline integrity replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "timeline_integrity_report" => %{
            "contract" => "timeline_integrity_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_timeline_integrity_report"
            ],
            "timeline_integrity_review_count" => 1,
            "required_operator_action_counts" => %{"review_timeline_integrity" => 1},
            "review_activity_id_counts" => %{"direct_review_activity" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_integrity_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_integrity_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_integrity_report"
           ]

    assert summary["timeline_integrity_review_count"] == 1
    assert summary["required_operator_action_counts"] == %{"review_timeline_integrity" => 1}
    assert summary["review_activity_id_counts"] == %{"direct_review_activity" => 1}
    assert summary["branch_local_timeline_integrity_pressure"]
    assert summary["branch_local_timeline_integrity_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_integrity_candidate_source_report_summary_only"
  end

  test "timeline integrity replay falls back to provenance when branch summary lacks usable family" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_integrity_report" => %{},
            "timeline_diff_report" => %{
              "contract" => "timeline_diff_report.v1",
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_diff_report"
              ]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_integrity_report" => %{
            "contract" => "timeline_integrity_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_timeline_integrity_report"],
            "timeline_integrity_review_count" => 1,
            "required_operator_action_counts" => %{"review_timeline_integrity" => 1},
            "review_activity_id_counts" => %{"provenance_review_activity" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_integrity_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.timeline_integrity_report"

    assert summary["source_report_paths"] == ["source_timeline_integrity_report"]
    assert summary["timeline_integrity_review_count"] == 1
    assert summary["required_operator_action_counts"] == %{"review_timeline_integrity" => 1}
    assert summary["review_activity_id_counts"] == %{"provenance_review_activity" => 1}
    assert summary["branch_local_timeline_integrity_pressure"]
    assert summary["branch_local_timeline_integrity_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_integrity_source_report_provenance_only"
  end

  test "timeline integrity replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_integrity_report" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_integrity_report"
              ],
              "missing_dependency_activity_id_counts" => %{"branch_missing_gate" => 1}
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_integrity_report" => %{
            "contract" => "timeline_integrity_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_timeline_integrity_report"],
            "timeline_integrity_review_count" => 9,
            "required_operator_action_counts" => %{"review_timeline_integrity" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_integrity_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_integrity_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_integrity_report"
           ]

    assert summary["timeline_integrity_review_count"] == 0
    assert summary["required_operator_action_counts"] == %{}
    assert summary["missing_dependency_activity_id_counts"] == %{"branch_missing_gate" => 1}
    assert summary["branch_local_timeline_integrity_pressure"]
    refute summary["branch_local_timeline_integrity_review_pressure"]
    assert summary["branch_local_dependency_integrity_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_integrity_candidate_source_report_summary_only"
  end
end
