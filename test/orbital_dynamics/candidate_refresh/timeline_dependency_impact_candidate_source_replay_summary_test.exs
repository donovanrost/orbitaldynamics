defmodule OrbitalDynamics.CandidateRefresh.TimelineDependencyImpactCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "timeline dependency impact replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_dependency_impact_summary" => %{
              "contract" => "timeline_dependency_impact_summary.v1",
              "count" => 1,
              "row_count" => 2,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_dependency_impact_summary"
              ],
              "source_activity_count" => 2,
              "replacement_activity_count" => 2,
              "changed_source_activity_count" => 1,
              "changed_source_timeline_count" => 1,
              "dependent_activity_count" => 2,
              "source_dependent_activity_count" => 1,
              "replacement_dependent_activity_count" => 1,
              "dependency_impact_status_counts" => %{"review_required" => 2},
              "dependency_impact_scope_counts" => %{"replacement" => 1, "source" => 1},
              "required_operator_action_counts" => %{"review_timeline_integrity" => 2},
              "impacted_source_activity_id_counts" => %{"health_gate" => 1},
              "impacted_source_timeline_id_counts" => %{"timeline:health_gate" => 1},
              "impacted_dependency_activity_id_counts" => %{"dependency_gate" => 1},
              "impacted_dependency_timeline_id_counts" => %{"timeline:dependency_gate" => 1},
              "impacted_exclusive_activity_id_counts" => %{"exclusive_gate" => 1},
              "impacted_exclusive_timeline_id_counts" => %{"timeline:exclusive_gate" => 1},
              "dependent_activity_id_counts" => %{"cmd_combo" => 2},
              "dependent_timeline_id_counts" => %{"timeline:cmd_combo" => 2},
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_dependency_impact"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.timeline_dependency_impact_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_dependency_impact_summary"

    assert summary["contract"] == "timeline_dependency_impact_summary.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 2

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_dependency_impact_summary"
           ]

    assert summary["source_activity_count"] == 2
    assert summary["replacement_activity_count"] == 2
    assert summary["changed_source_activity_count"] == 1
    assert summary["changed_source_timeline_count"] == 1
    assert summary["dependent_activity_count"] == 2
    assert summary["source_dependent_activity_count"] == 1
    assert summary["replacement_dependent_activity_count"] == 1
    assert summary["dependency_impact_status_counts"] == %{"review_required" => 2}
    assert summary["dependency_impact_scope_counts"] == %{"replacement" => 1, "source" => 1}
    assert summary["required_operator_action_counts"] == %{"review_timeline_integrity" => 2}
    assert summary["impacted_source_activity_id_counts"] == %{"health_gate" => 1}
    assert summary["impacted_source_timeline_id_counts"] == %{"timeline:health_gate" => 1}
    assert summary["impacted_dependency_activity_id_counts"] == %{"dependency_gate" => 1}
    assert summary["impacted_dependency_timeline_id_counts"] == %{"timeline:dependency_gate" => 1}
    assert summary["impacted_exclusive_activity_id_counts"] == %{"exclusive_gate" => 1}
    assert summary["impacted_exclusive_timeline_id_counts"] == %{"timeline:exclusive_gate" => 1}
    assert summary["dependent_activity_id_counts"] == %{"cmd_combo" => 2}
    assert summary["dependent_timeline_id_counts"] == %{"timeline:cmd_combo" => 2}
    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_dependency_impact"]
    assert summary["branch_local_timeline_dependency_impact_pressure"]
    assert summary["branch_local_changed_source_pressure"]
    assert summary["branch_local_dependency_pressure"]
    assert summary["branch_local_exclusivity_pressure"]
    assert summary["branch_local_dependent_activity_pressure"]
    assert summary["branch_local_operator_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_dependency_impact_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_timeline_dependency_impact_replay_summary(artifact) ==
             summary
  end

  test "timeline dependency impact replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "timeline_dependency_impact_summary" => %{
            "contract" => "timeline_dependency_impact_summary.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_timeline_dependency_impact_summary"
            ],
            "dependent_activity_id_counts" => %{"direct_dependent_activity" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_dependency_impact_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_dependency_impact_summary"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_dependency_impact_summary"
           ]

    assert summary["dependent_activity_id_counts"] == %{"direct_dependent_activity" => 1}
    assert summary["branch_local_timeline_dependency_impact_pressure"]
    assert summary["branch_local_dependent_activity_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_dependency_impact_candidate_source_report_summary_only"
  end

  test "timeline dependency impact replay falls back to provenance when branch summary lacks usable family" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_dependency_impact_summary" => %{},
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
          "timeline_dependency_impact_summary" => %{
            "contract" => "timeline_dependency_impact_summary.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_timeline_dependency_impact_summary"],
            "dependent_activity_id_counts" => %{"provenance_dependent_activity" => 1},
            "required_operator_action_counts" => %{"review_timeline_integrity" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_dependency_impact_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.timeline_dependency_impact_summary"

    assert summary["source_report_paths"] == ["source_timeline_dependency_impact_summary"]
    assert summary["dependent_activity_id_counts"] == %{"provenance_dependent_activity" => 1}
    assert summary["required_operator_action_counts"] == %{"review_timeline_integrity" => 1}
    assert summary["branch_local_timeline_dependency_impact_pressure"]
    assert summary["branch_local_dependent_activity_pressure"]
    assert summary["branch_local_operator_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_dependency_impact_source_report_provenance_only"
  end

  test "timeline dependency impact replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_dependency_impact_summary" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_dependency_impact_summary"
              ],
              "dependent_activity_id_counts" => %{"branch_dependent_activity" => 1}
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_dependency_impact_summary" => %{
            "contract" => "timeline_dependency_impact_summary.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_timeline_dependency_impact_summary"],
            "required_operator_action_counts" => %{"review_timeline_integrity" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_dependency_impact_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_dependency_impact_summary"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_dependency_impact_summary"
           ]

    assert summary["dependent_activity_id_counts"] == %{"branch_dependent_activity" => 1}
    assert summary["required_operator_action_counts"] == %{}
    assert summary["branch_local_timeline_dependency_impact_pressure"]
    assert summary["branch_local_dependent_activity_pressure"]
    refute summary["branch_local_operator_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_dependency_impact_candidate_source_report_summary_only"
  end
end
