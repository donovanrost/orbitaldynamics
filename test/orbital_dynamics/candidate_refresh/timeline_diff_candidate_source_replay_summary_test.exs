defmodule OrbitalDynamics.CandidateRefresh.TimelineDiffCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "timeline diff replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_diff_report" => %{
              "contract" => "timeline_diff_report.v1",
              "count" => 1,
              "row_count" => 3,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_diff_report"
              ],
              "duplicate_timeline_identity_count" => 1,
              "duplicate_source_timeline_identity_count" => 1,
              "duplicate_replacement_timeline_identity_count" => 0,
              "removed_downlink_count" => 1,
              "removed_observation_count" => 0,
              "changed_downlink_shortfall_count" => 1,
              "changed_contact_feedback_count" => 1,
              "changed_observation_count" => 0,
              "changed_observation_quality_feedback_count" => 0,
              "changed_command_feedback_count" => 1,
              "changed_maneuver_feedback_count" => 0,
              "diff_status_counts" => %{"changed" => 3, "duplicate" => 1, "removed" => 1},
              "required_operator_action_counts" => %{
                "review_duplicate_timeline_identity" => 1,
                "review_removed_activity" => 1,
                "review_timeline_change" => 3
              },
              "duplicate_timeline_identity_scope_counts" => %{"source" => 1},
              "source_activity_id_counts" => %{
                "branch_command_source" => 1,
                "branch_downlink_removed" => 1
              },
              "replacement_activity_id_counts" => %{
                "branch_command_replacement" => 1,
                "branch_contact_replacement" => 1
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_timeline_diff"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.timeline_diff_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_diff_report"

    assert summary["contract"] == "timeline_diff_report.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 3

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_diff_report"
           ]

    assert summary["duplicate_timeline_identity_count"] == 1
    assert summary["duplicate_source_timeline_identity_count"] == 1
    assert summary["duplicate_replacement_timeline_identity_count"] == 0
    assert summary["removed_downlink_count"] == 1
    assert summary["removed_observation_count"] == 0
    assert summary["changed_downlink_shortfall_count"] == 1
    assert summary["changed_contact_feedback_count"] == 1
    assert summary["changed_observation_count"] == 0
    assert summary["changed_observation_quality_feedback_count"] == 0
    assert summary["changed_command_feedback_count"] == 1
    assert summary["changed_maneuver_feedback_count"] == 0

    assert summary["diff_status_counts"] == %{"changed" => 3, "duplicate" => 1, "removed" => 1}

    assert summary["required_operator_action_counts"] == %{
             "review_duplicate_timeline_identity" => 1,
             "review_removed_activity" => 1,
             "review_timeline_change" => 3
           }

    assert summary["duplicate_timeline_identity_scope_counts"] == %{"source" => 1}

    assert summary["source_activity_id_counts"] == %{
             "branch_command_source" => 1,
             "branch_downlink_removed" => 1
           }

    assert summary["replacement_activity_id_counts"] == %{
             "branch_command_replacement" => 1,
             "branch_contact_replacement" => 1
           }

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_timeline_diff"]
    assert summary["branch_local_timeline_diff_pressure"]
    assert summary["branch_local_duplicate_identity_pressure"]
    assert summary["branch_local_removed_activity_pressure"]
    assert summary["branch_local_changed_activity_pressure"]
    assert summary["branch_local_activity_routing_pressure"]
    assert summary["branch_local_operator_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_diff_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_timeline_diff_replay_summary(artifact) ==
             summary
  end

  test "timeline diff replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "timeline_diff_report" => %{
            "contract" => "timeline_diff_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_timeline_diff_report"
            ],
            "duplicate_timeline_identity_scope_counts" => %{"source" => 1},
            "source_activity_id_counts" => %{"direct_source_activity" => 1},
            "replacement_activity_id_counts" => %{"direct_replacement_activity" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_diff_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_diff_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_diff_report"
           ]

    assert summary["duplicate_timeline_identity_scope_counts"] == %{"source" => 1}
    assert summary["source_activity_id_counts"] == %{"direct_source_activity" => 1}
    assert summary["replacement_activity_id_counts"] == %{"direct_replacement_activity" => 1}
    assert summary["branch_local_timeline_diff_pressure"]
    assert summary["branch_local_duplicate_identity_pressure"]
    assert summary["branch_local_activity_routing_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_diff_candidate_source_report_summary_only"
  end

  test "timeline diff replay falls back to provenance when branch summary lacks usable family" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_diff_report" => %{},
            "command_window_report" => %{
              "contract" => "command_window_report.v1",
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_command_window_report"
              ]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_diff_report" => %{
            "contract" => "timeline_diff_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_timeline_diff_report"],
            "removed_downlink_count" => 1,
            "diff_status_counts" => %{"removed" => 1},
            "required_operator_action_counts" => %{"review_removed_activity" => 1},
            "source_activity_id_counts" => %{"provenance_removed" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_diff_replay_summary(artifact)

    assert summary["source"] == "candidate_refresh.source_report_provenance.timeline_diff_report"
    assert summary["source_report_paths"] == ["source_timeline_diff_report"]
    assert summary["removed_downlink_count"] == 1
    assert summary["diff_status_counts"] == %{"removed" => 1}
    assert summary["required_operator_action_counts"] == %{"review_removed_activity" => 1}
    assert summary["source_activity_id_counts"] == %{"provenance_removed" => 1}
    assert summary["branch_local_timeline_diff_pressure"]
    assert summary["branch_local_removed_activity_pressure"]
    assert summary["branch_local_operator_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_diff_source_report_provenance_only"
  end

  test "timeline diff replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_diff_report" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_diff_report"
              ],
              "source_activity_id_counts" => %{"branch_source_activity" => 1}
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_diff_report" => %{
            "contract" => "timeline_diff_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_timeline_diff_report"],
            "removed_downlink_count" => 9,
            "diff_status_counts" => %{"removed" => 9},
            "source_activity_id_counts" => %{"provenance_source_activity" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_diff_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_diff_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_diff_report"
           ]

    assert summary["removed_downlink_count"] == 0
    assert summary["diff_status_counts"] == %{}
    assert summary["source_activity_id_counts"] == %{"branch_source_activity" => 1}
    assert summary["branch_local_timeline_diff_pressure"]
    refute summary["branch_local_removed_activity_pressure"]
    assert summary["branch_local_activity_routing_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_diff_candidate_source_report_summary_only"
  end
end
