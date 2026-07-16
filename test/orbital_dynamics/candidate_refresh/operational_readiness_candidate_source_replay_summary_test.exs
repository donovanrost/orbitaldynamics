defmodule OrbitalDynamics.CandidateRefresh.OperationalReadinessCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "operational readiness replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "operational_readiness_report" => %{
              "contract" => "operational_readiness_report.v1",
              "count" => 1,
              "row_count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_operational_readiness_report"
              ],
              "readiness_level_counts" => %{"operator_review" => 1},
              "import_classification_counts" => %{"review_only" => 1},
              "status_counts" => %{"review_required" => 1},
              "gate_count" => 3,
              "passed_gate_count" => 1,
              "review_gate_count" => 1,
              "analysis_gate_count" => 1,
              "analysis_mode_counts" => %{"not_for_execution" => 1},
              "blocked_gate_count" => 1,
              "ready_for_import_count" => 0,
              "manifest_review_required_count" => 1,
              "blocked_import_count" => 1,
              "missing_import_count" => 1,
              "invalid_cadence_import_count" => 1,
              "review_required_count" => 1,
              "stale_freshness_count" => 1,
              "freshness_status_counts" => %{"stale" => 1},
              "schema_validation_fail_count" => 1,
              "schema_validation_error_count" => 1,
              "schema_validation_status_counts" => %{"fail" => 1},
              "import_status_counts" => %{"review_required_before_import" => 1},
              "cadence_import_status_counts" => %{"missing" => 1},
              "adapter_trust_boundary_missing_count" => 1,
              "adapter_boundary_status_counts" => %{"missing" => 1},
              "resource_availability_pressure_count" => 1,
              "resource_availability_reason_counts" => %{"antenna_unavailable" => 1},
              "resource_availability_reason_ids" => ["antenna_unavailable"],
              "station_availability_reason_ids" => ["ground_station_reserved"],
              "station_availability_reason_counts" => %{"ground_station_reserved" => 1},
              "unavailable_resource_reason_ids" => ["antenna_unavailable"],
              "resource_blocking_dimension_counts" => %{"communications" => 1},
              "review_type_counts" => %{"operational_readiness_review" => 1},
              "import_action_counts" => %{"review_operational_readiness" => 1},
              "source_review_type_counts" => %{"operational_readiness_review" => 1},
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_operational_readiness"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.operational_readiness_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.operational_readiness_report"

    assert summary["contract"] == "operational_readiness_report.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_operational_readiness_report"
           ]

    assert summary["readiness_level_counts"] == %{"operator_review" => 1}
    assert summary["import_classification_counts"] == %{"review_only" => 1}
    assert summary["status_counts"] == %{"review_required" => 1}
    assert summary["gate_count"] == 3
    assert summary["passed_gate_count"] == 1
    assert summary["review_gate_count"] == 1
    assert summary["analysis_gate_count"] == 1
    assert summary["analysis_mode_counts"] == %{"not_for_execution" => 1}
    assert summary["blocked_gate_count"] == 1
    assert summary["manifest_review_required_count"] == 1
    assert summary["blocked_import_count"] == 1
    assert summary["missing_import_count"] == 1
    assert summary["invalid_cadence_import_count"] == 1
    assert summary["review_required_count"] == 1
    assert summary["stale_freshness_count"] == 1
    assert summary["freshness_status_counts"] == %{"stale" => 1}
    assert summary["schema_validation_fail_count"] == 1
    assert summary["schema_validation_error_count"] == 1
    assert summary["schema_validation_status_counts"] == %{"fail" => 1}
    assert summary["import_status_counts"] == %{"review_required_before_import" => 1}
    assert summary["cadence_import_status_counts"] == %{"missing" => 1}
    assert summary["adapter_trust_boundary_missing_count"] == 1
    assert summary["adapter_boundary_status_counts"] == %{"missing" => 1}
    assert summary["resource_availability_pressure_count"] == 1
    assert summary["resource_availability_reason_counts"] == %{"antenna_unavailable" => 1}
    assert summary["resource_availability_reason_ids"] == ["antenna_unavailable"]
    assert summary["station_availability_reason_ids"] == ["ground_station_reserved"]
    assert summary["station_availability_reason_counts"] == %{"ground_station_reserved" => 1}
    assert summary["unavailable_resource_reason_ids"] == ["antenna_unavailable"]
    assert summary["resource_blocking_dimension_counts"] == %{"communications" => 1}
    assert summary["review_type_counts"] == %{"operational_readiness_review" => 1}
    assert summary["import_action_counts"] == %{"review_operational_readiness" => 1}
    assert summary["source_review_type_counts"] == %{"operational_readiness_review" => 1}
    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_operational_readiness"]
    assert summary["branch_local_review_pressure"]
    assert summary["branch_local_import_pressure"]
    assert summary["branch_local_resource_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "operational_readiness_candidate_source_report_summary_only"

    assert %{
             "source_report_operational_readiness_branch_local_review_pressure" => true,
             "source_report_operational_readiness_branch_local_import_pressure" => true,
             "source_report_operational_readiness_branch_local_execution_boundary_pressure" =>
               false,
             "source_report_operational_readiness_branch_local_resource_pressure" => true,
             "source_report_operational_readiness_branch_local_timeline_publication_pressure" =>
               false
           } = CandidateRefresh.source_report_summary(artifact)

    assert OrbitalDynamics.candidate_refresh_operational_readiness_replay_summary(artifact) ==
             summary
  end

  test "operational readiness replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "operational_readiness_report" => %{
            "contract" => "operational_readiness_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_operational_readiness_report"
            ],
            "review_type_counts" => %{"operational_readiness_review" => 1},
            "import_action_counts" => %{"review_operational_readiness" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.operational_readiness_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.operational_readiness_report"

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_operational_readiness_report"
           ]

    assert summary["review_type_counts"] == %{"operational_readiness_review" => 1}
    assert summary["import_action_counts"] == %{"review_operational_readiness" => 1}
    assert summary["branch_local_review_pressure"]
    assert summary["branch_local_import_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "operational_readiness_candidate_source_report_summary_only"
  end

  test "operational readiness replay falls back when branch summary is empty" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{"operational_readiness_report" => %{}}
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "operational_readiness_report" => %{
            "contract" => "operational_readiness_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["provenance.source_reports.operational_readiness_report"],
            "readiness_level_counts" => %{"operator_review" => 1},
            "review_type_counts" => %{"operational_readiness_review" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.operational_readiness_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.operational_readiness_report"

    assert summary["source_report_paths"] == [
             "provenance.source_reports.operational_readiness_report"
           ]

    assert summary["readiness_level_counts"] == %{"operator_review" => 1}
    assert summary["review_type_counts"] == %{"operational_readiness_review" => 1}
    assert summary["branch_local_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "operational_readiness_source_report_provenance_only"
  end

  test "operational readiness replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "operational_readiness_report" => %{
              "contract" => "operational_readiness_report.v1",
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_operational_readiness_report"
              ],
              "resource_availability_reason_counts" => %{"antenna_unavailable" => 1}
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "operational_readiness_report" => %{
            "contract" => "operational_readiness_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["provenance.source_reports.operational_readiness_report"],
            "review_gate_count" => 9,
            "manifest_review_required_count" => 9,
            "resource_availability_pressure_count" => 9,
            "readiness_level_counts" => %{"blocked" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.operational_readiness_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.operational_readiness_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_operational_readiness_report"
           ]

    assert summary["review_gate_count"] == 0
    assert summary["manifest_review_required_count"] == 0
    assert summary["resource_availability_pressure_count"] == 0
    assert summary["readiness_level_counts"] == %{}
    assert summary["resource_availability_reason_counts"] == %{"antenna_unavailable" => 1}
    refute summary["branch_local_review_pressure"]
    refute summary["branch_local_import_pressure"]
    assert summary["branch_local_resource_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "operational_readiness_candidate_source_report_summary_only"

    source_summary = CandidateRefresh.source_report_summary(artifact)

    refute source_summary["source_report_operational_readiness_branch_local_review_pressure"]
    refute source_summary["source_report_operational_readiness_branch_local_import_pressure"]

    assert source_summary[
             "source_report_operational_readiness_branch_local_resource_pressure"
           ]
  end
end
