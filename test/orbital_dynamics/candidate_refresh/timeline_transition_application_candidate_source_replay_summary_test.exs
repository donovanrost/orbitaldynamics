defmodule OrbitalDynamics.CandidateRefresh.TimelineTransitionApplicationCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "timeline transition application replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_transition_application_report" => %{
              "contract" => "timeline_transition_application_report.v1",
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_transition_application_report"
              ],
              "application_count" => 3,
              "selected_activity_count" => 1,
              "selected_activity_id_counts" => %{"selected_downlink_activity" => 1},
              "review_activity_id_counts" => %{"review_downlink_activity" => 1},
              "review_required_count" => 2,
              "preserved_source_count" => 1,
              "recorded_replacement_count" => 1,
              "withheld_review_count" => 1,
              "duplicate_timeline_identity_count" => 2,
              "duplicate_source_timeline_identity_count" => 1,
              "duplicate_replacement_timeline_identity_count" => 1,
              "application_status_counts" => %{
                "operator_review_required" => 1,
                "selected" => 1,
                "source_preserved_pending_review" => 1
              },
              "transition_decision_counts" => %{
                "apply" => 1,
                "preserve_source" => 1,
                "review" => 1
              },
              "required_operator_action_counts" => %{
                "none" => 1,
                "review_timeline_change" => 1
              },
              "duplicate_timeline_identity_scope_counts" => %{
                "replacement" => 1,
                "source" => 1
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_transition_application"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.timeline_transition_application_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_transition_application_report"

    assert summary["contract"] == "timeline_transition_application_report.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 3
    assert summary["source_application_count"] == 3

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_transition_application_report"
           ]

    assert summary["selected_activity_count"] == 1
    assert summary["selected_activity_id_counts"] == %{"selected_downlink_activity" => 1}
    assert summary["review_activity_id_counts"] == %{"review_downlink_activity" => 1}
    assert summary["review_required_count"] == 2
    assert summary["preserved_source_count"] == 1
    assert summary["recorded_replacement_count"] == 1
    assert summary["withheld_review_count"] == 1
    assert summary["duplicate_timeline_identity_count"] == 2
    assert summary["duplicate_source_timeline_identity_count"] == 1
    assert summary["duplicate_replacement_timeline_identity_count"] == 1

    assert summary["application_status_counts"] == %{
             "operator_review_required" => 1,
             "selected" => 1,
             "source_preserved_pending_review" => 1
           }

    assert summary["transition_decision_counts"] == %{
             "apply" => 1,
             "preserve_source" => 1,
             "review" => 1
           }

    assert summary["required_operator_action_counts"] == %{
             "none" => 1,
             "review_timeline_change" => 1
           }

    assert summary["duplicate_timeline_identity_scope_counts"] == %{
             "replacement" => 1,
             "source" => 1
           }

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_transition_application"]
    assert summary["branch_local_timeline_transition_application_pressure"]
    assert summary["branch_local_selected_activity_pressure"]
    assert summary["branch_local_review_required_pressure"]
    assert summary["branch_local_preserved_transition_pressure"]
    assert summary["branch_local_duplicate_identity_pressure"]
    assert summary["branch_local_operator_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_transition_application_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_timeline_transition_application_replay_summary(
             artifact
           ) == summary
  end

  test "timeline transition application replay reads compact strategy branch summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_transition_application_report" => %{
              "contract" => "timeline_transition_application_summary.v1",
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_transition_application_summary"
              ],
              "application_count" => 2,
              "selected_activity_count" => 1,
              "selected_timeline_integrity_review_count" => 1,
              "selected_timeline_integrity_issue_count" => 2,
              "selected_timeline_integrity_issue_type_counts" => %{
                "missing_dependency_activity" => 1,
                "self_dependency_timeline" => 1
              },
              "selected_activity_id_counts" => %{"branch_cmd_lock" => 1},
              "review_activity_id_counts" => %{"branch_cmd_added" => 1},
              "review_required_count" => 1,
              "preserved_source_count" => 1,
              "recorded_replacement_count" => 0,
              "withheld_review_count" => 1,
              "application_status_counts" => %{
                "operator_review_required" => 1,
                "source_preserved_pending_review" => 1
              },
              "transition_decision_counts" => %{"preserve_source" => 1, "review" => 1},
              "required_operator_action_counts" => %{
                "review_added_activity" => 1,
                "review_timeline_integrity" => 1
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_compact_transition_summary"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_transition_application_report" => %{
            "contract" => "timeline_transition_application_report.v1",
            "count" => 9,
            "paths" => ["source_timeline_transition_application_report"],
            "application_count" => 9,
            "selected_activity_id_counts" => %{"stale_selected_activity" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_transition_application_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_transition_application_report"

    assert summary["contract"] == "timeline_transition_application_summary.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 2
    assert summary["source_application_count"] == 2

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_transition_application_summary"
           ]

    assert summary["selected_activity_count"] == 1
    assert summary["selected_timeline_integrity_review_count"] == 1
    assert summary["selected_timeline_integrity_issue_count"] == 2

    assert summary["selected_timeline_integrity_issue_type_counts"] == %{
             "missing_dependency_activity" => 1,
             "self_dependency_timeline" => 1
           }

    assert summary["selected_activity_id_counts"] == %{"branch_cmd_lock" => 1}
    assert summary["review_activity_id_counts"] == %{"branch_cmd_added" => 1}
    assert summary["review_required_count"] == 1
    assert summary["preserved_source_count"] == 1
    assert summary["withheld_review_count"] == 1

    assert summary["application_status_counts"] == %{
             "operator_review_required" => 1,
             "source_preserved_pending_review" => 1
           }

    assert summary["transition_decision_counts"] == %{"preserve_source" => 1, "review" => 1}

    assert summary["required_operator_action_counts"] == %{
             "review_added_activity" => 1,
             "review_timeline_integrity" => 1
           }

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_compact_transition_summary"]
    assert summary["branch_local_timeline_transition_application_pressure"]
    assert summary["branch_local_selected_activity_pressure"]
    assert summary["branch_local_selected_integrity_pressure"]
    assert summary["branch_local_review_required_pressure"]
    assert summary["branch_local_preserved_transition_pressure"]
    assert summary["branch_local_operator_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_transition_application_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_timeline_transition_application_replay_summary(
             artifact
           ) == summary
  end

  test "timeline transition application replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "timeline_transition_application_report" => %{
            "contract" => "timeline_transition_application_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_timeline_transition_application_report"
            ],
            "application_count" => 1,
            "selected_activity_id_counts" => %{"direct_selected_activity" => 1},
            "required_operator_action_counts" => %{"none" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_transition_application_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_transition_application_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1
    assert summary["source_application_count"] == 1

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_transition_application_report"
           ]

    assert summary["selected_activity_id_counts"] == %{"direct_selected_activity" => 1}
    assert summary["required_operator_action_counts"] == %{"none" => 1}
    assert summary["branch_local_timeline_transition_application_pressure"]
    assert summary["branch_local_selected_activity_pressure"]
    refute summary["branch_local_operator_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_transition_application_candidate_source_report_summary_only"
  end

  test "timeline transition application replay falls back to provenance when branch summary lacks usable family" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_transition_application_report" => %{},
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
          "timeline_transition_application_report" => %{
            "contract" => "timeline_transition_application_report.v1",
            "count" => 1,
            "paths" => ["source_timeline_transition_application_report"],
            "application_count" => 2,
            "selected_activity_id_counts" => %{"provenance_selected_activity" => 1},
            "required_operator_action_counts" => %{"review_timeline_change" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_transition_application_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.timeline_transition_application_report"

    assert summary["source_report_paths"] == ["source_timeline_transition_application_report"]
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 2
    assert summary["source_application_count"] == 2
    assert summary["selected_activity_id_counts"] == %{"provenance_selected_activity" => 1}
    assert summary["required_operator_action_counts"] == %{"review_timeline_change" => 1}
    assert summary["branch_local_timeline_transition_application_pressure"]
    assert summary["branch_local_operator_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_transition_application_source_report_provenance_only"
  end

  test "timeline transition application replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_transition_application_report" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_transition_application_report"
              ],
              "selected_activity_id_counts" => %{"branch_selected_activity" => 1}
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_transition_application_report" => %{
            "contract" => "timeline_transition_application_report.v1",
            "count" => 9,
            "paths" => ["source_timeline_transition_application_report"],
            "application_count" => 9,
            "review_required_count" => 9,
            "required_operator_action_counts" => %{"review_timeline_change" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_transition_application_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_transition_application_report"

    assert summary["source_report_count"] == 1
    assert summary["source_application_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_transition_application_report"
           ]

    assert summary["selected_activity_id_counts"] == %{"branch_selected_activity" => 1}
    assert summary["review_required_count"] == 0
    assert summary["required_operator_action_counts"] == %{}
    assert summary["branch_local_timeline_transition_application_pressure"]
    assert summary["branch_local_selected_activity_pressure"]
    refute summary["branch_local_review_required_pressure"]
    refute summary["branch_local_operator_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_transition_application_candidate_source_report_summary_only"
  end
end
