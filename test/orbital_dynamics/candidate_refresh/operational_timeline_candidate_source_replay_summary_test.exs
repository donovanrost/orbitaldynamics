defmodule OrbitalDynamics.CandidateRefresh.OperationalTimelineCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "operational timeline replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "operational_timeline_report" => %{
              "contract" => "operational_timeline_report.v1",
              "count" => 1,
              "row_count" => 4,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_operational_timeline_report"
              ],
              "contact_feedback_count" => 1,
              "command_feedback_count" => 1,
              "maneuver_feedback_count" => 1,
              "observation_feedback_count" => 1,
              "station_throughput_feedback_count" => 1,
              "operational_kind_counts" => %{
                "command" => 1,
                "contact" => 1,
                "maneuver" => 1,
                "observation" => 1
              },
              "activity_id_counts" => %{"branch_ops_activity" => 4},
              "activity_status_counts" => %{"partial" => 1, "planned" => 3},
              "approval_status_counts" => %{"review_required" => 4},
              "required_operator_action_counts" => %{"review_branch_ops_timeline" => 4},
              "cadence_import_status_counts" => %{"review" => 4},
              "timeline_integrity_issue_count" => 1,
              "dependency_integrity_issue_count" => 1,
              "exclusivity_integrity_issue_count" => 1,
              "timeline_integrity_issue_type_counts" => %{
                "dependency_missing" => 1,
                "exclusive_overlap" => 1
              },
              "station_reservation_evidence_row_count" => 1,
              "station_reservation_expiration_evidence_row_count" => 1,
              "input_keys" => [
                "command_success_rate",
                "contact_success_rate",
                "station_throughput_factor"
              ],
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_operational_timeline"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.operational_timeline_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.operational_timeline_report"

    assert summary["contract"] == "operational_timeline_report.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 4

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_operational_timeline_report"
           ]

    assert summary["contact_feedback_count"] == 1
    assert summary["command_feedback_count"] == 1
    assert summary["maneuver_feedback_count"] == 1
    assert summary["observation_feedback_count"] == 1
    assert summary["station_throughput_feedback_count"] == 1

    assert summary["operational_kind_counts"] == %{
             "command" => 1,
             "contact" => 1,
             "maneuver" => 1,
             "observation" => 1
           }

    assert summary["activity_id_counts"] == %{"branch_ops_activity" => 4}
    assert summary["activity_status_counts"] == %{"partial" => 1, "planned" => 3}
    assert summary["approval_status_counts"] == %{"review_required" => 4}
    assert summary["required_operator_action_counts"] == %{"review_branch_ops_timeline" => 4}
    assert summary["cadence_import_status_counts"] == %{"review" => 4}
    assert summary["timeline_integrity_issue_count"] == 1
    assert summary["dependency_integrity_issue_count"] == 1
    assert summary["exclusivity_integrity_issue_count"] == 1

    assert summary["timeline_integrity_issue_type_counts"] == %{
             "dependency_missing" => 1,
             "exclusive_overlap" => 1
           }

    assert summary["station_reservation_evidence_row_count"] == 1
    assert summary["station_reservation_expiration_evidence_row_count"] == 1

    assert summary["input_keys"] == [
             "command_success_rate",
             "contact_success_rate",
             "station_throughput_factor"
           ]

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_operational_timeline"]
    assert summary["branch_local_operational_timeline_pressure"]
    assert summary["branch_local_feedback_pressure"]
    assert summary["branch_local_activity_routing_pressure"]
    assert summary["branch_local_integrity_pressure"]
    assert summary["branch_local_station_reservation_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "operational_timeline_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_operational_timeline_replay_summary(artifact) ==
             summary
  end

  test "operational timeline replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "operational_timeline_report" => %{
            "contract" => "operational_timeline_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_operational_timeline_report"
            ],
            "command_feedback_count" => 1,
            "operational_kind_counts" => %{"command" => 1},
            "activity_id_counts" => %{"direct_ops_activity" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.operational_timeline_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.operational_timeline_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_operational_timeline_report"
           ]

    assert summary["command_feedback_count"] == 1
    assert summary["operational_kind_counts"] == %{"command" => 1}
    assert summary["activity_id_counts"] == %{"direct_ops_activity" => 1}
    assert summary["branch_local_operational_timeline_pressure"]
    assert summary["branch_local_feedback_pressure"]
    assert summary["branch_local_activity_routing_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "operational_timeline_candidate_source_report_summary_only"
  end

  test "operational timeline replay falls back to provenance when branch summary lacks usable family" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "operational_timeline_report" => %{},
            "timeline_feedback_report" => %{
              "contract" => "timeline_feedback_report.v1",
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_feedback_report"
              ]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "operational_timeline_report" => %{
            "contract" => "operational_timeline_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_operational_timeline_report"],
            "activity_id_counts" => %{"provenance_ops_activity" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.operational_timeline_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.operational_timeline_report"

    assert summary["source_report_paths"] == ["source_operational_timeline_report"]
    assert summary["activity_id_counts"] == %{"provenance_ops_activity" => 1}
    assert summary["branch_local_operational_timeline_pressure"]
    assert summary["branch_local_activity_routing_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "operational_timeline_source_report_provenance_only"
  end

  test "operational timeline replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "operational_timeline_report" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_operational_timeline_report"
              ],
              "input_keys" => ["command_success_rate"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "operational_timeline_report" => %{
            "contract" => "operational_timeline_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_operational_timeline_report"],
            "activity_id_counts" => %{"provenance_ops_activity" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.operational_timeline_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.operational_timeline_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_operational_timeline_report"
           ]

    assert summary["input_keys"] == ["command_success_rate"]
    assert summary["activity_id_counts"] == %{}
    assert summary["contract"] == "operational_timeline_report.v1"
    assert summary["branch_local_operational_timeline_pressure"]
    refute summary["branch_local_feedback_pressure"]
    refute summary["branch_local_activity_routing_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "operational_timeline_candidate_source_report_summary_only"
  end
end
