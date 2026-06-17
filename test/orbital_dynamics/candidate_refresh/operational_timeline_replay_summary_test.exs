defmodule OrbitalDynamics.CandidateRefresh.OperationalTimelineReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Schema, Timeline}

  test "source report summary derives operational timeline replay maps from rows" do
    report =
      Timeline.operational_report(
        [
          %{
            id: :ops_contact_feedback,
            type: :downlink,
            scenario_id: :leo_1,
            spacecraft_id: :sat_1,
            ground_station_id: :equator_prime,
            direction: :downlink,
            starts_at_s: 10.0,
            ends_at_s: 40.0,
            contact_success_factor: 0.4,
            actual_throughput_mb: 20.0,
            estimated_throughput_mb: 50.0,
            station_reservation_id: :reservation_ops,
            station_reservation_expires_at_s: 360.0,
            provenance: %{trust_boundary: :ops_operational_timeline_rows}
          }
        ],
        source: "ops.timeline"
      )
      |> Map.put("status_counts", %{"stale_feedback_status" => 99})
      |> Map.put("feedback_kind_counts", %{"stale_feedback_kind" => 99})
      |> Map.put("match_strategy_counts", %{"stale_match_strategy" => 99})
      |> Map.put("activity_id_counts", %{"stale_activity" => 99})
      |> Map.put("cadence_import_status_counts", %{"stale_import_status" => 99})
      |> Map.merge(%{
        "activity_status_counts" => %{"stale_activity_status" => 99},
        "approval_status_counts" => %{"stale_approval_status" => 99},
        "required_operator_action_counts" => %{"stale_required_action" => 99},
        "cadence_import_status_counts" => %{"stale_cadence_import_status" => 99},
        "operational_kind_counts" => %{"stale_operational_kind" => 99},
        "timeline_integrity_issue_count" => 99,
        "dependency_issue_count" => 99,
        "exclusivity_issue_count" => 99,
        "timeline_integrity_issue_type_counts" => %{"stale_integrity_issue" => 99}
      })

    refresh = %{"source_operational_timeline_report" => report}

    assert %{
             "source_report_family_count" => 1,
             "source_report_operational_timeline_contract" => "operational_timeline_report.v1",
             "source_report_operational_timeline_count" => 1,
             "source_report_operational_timeline_row_count" => 1,
             "source_report_operational_timeline_paths" => [
               "source_operational_timeline_report"
             ],
             "source_report_operational_timeline_operational_kind_counts" => %{
               "contact" => 1
             },
             "source_report_operational_timeline_activity_id_counts" => %{
               "ops_contact_feedback" => 1
             },
             "source_report_operational_timeline_activity_status_counts" => %{
               "planned" => 1
             },
             "source_report_operational_timeline_approval_status_counts" => %{
               "not_evaluated" => 1
             },
             "source_report_operational_timeline_required_operator_action_counts" => %{
               "review_activity_approval" => 1
             },
             "source_report_operational_timeline_cadence_import_status_counts" => %{
               "missing" => 1
             },
             "source_report_operational_timeline_branch_local_operational_timeline_pressure" =>
               true,
             "source_report_operational_timeline_branch_local_feedback_pressure" => true,
             "source_report_operational_timeline_branch_local_activity_routing_pressure" => true,
             "source_report_operational_timeline_branch_local_integrity_pressure" => false,
             "source_report_operational_timeline_branch_local_station_reservation_pressure" =>
               true,
             "source_reports" => %{
               "operational_timeline_report" => %{
                 "row_count" => 1,
                 "contact_feedback_count" => 1,
                 "command_feedback_count" => 0,
                 "maneuver_feedback_count" => 0,
                 "observation_feedback_count" => 0,
                 "station_throughput_feedback_count" => 1,
                 "operational_kind_counts" => %{"contact" => 1},
                 "activity_id_counts" => %{"ops_contact_feedback" => 1},
                 "activity_status_counts" => %{"planned" => 1},
                 "approval_status_counts" => %{"not_evaluated" => 1},
                 "required_operator_action_counts" => %{"review_activity_approval" => 1},
                 "cadence_import_status_counts" => %{"missing" => 1},
                 "timeline_integrity_issue_count" => 0,
                 "dependency_integrity_issue_count" => 0,
                 "exclusivity_integrity_issue_count" => 0,
                 "station_reservation_evidence_row_count" => 1,
                 "station_reservation_expiration_evidence_row_count" => 1,
                 "input_keys" => [
                   "contact_success_rate",
                   "station_throughput_factor"
                 ]
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = %{
      "model" => "artifact_only_candidate_refresh_operational_timeline_replay_summary",
      "source" => "candidate_refresh.source_report_provenance.operational_timeline_report",
      "contract" => "operational_timeline_report.v1",
      "source_report_count" => 1,
      "source_report_row_count" => 1,
      "source_report_paths" => ["source_operational_timeline_report"],
      "contact_feedback_count" => 1,
      "command_feedback_count" => 0,
      "maneuver_feedback_count" => 0,
      "observation_feedback_count" => 0,
      "station_throughput_feedback_count" => 1,
      "operational_kind_counts" => %{"contact" => 1},
      "activity_id_counts" => %{"ops_contact_feedback" => 1},
      "activity_status_counts" => %{"planned" => 1},
      "approval_status_counts" => %{"not_evaluated" => 1},
      "required_operator_action_counts" => %{"review_activity_approval" => 1},
      "cadence_import_status_counts" => %{"missing" => 1},
      "timeline_integrity_issue_count" => 0,
      "dependency_integrity_issue_count" => 0,
      "exclusivity_integrity_issue_count" => 0,
      "timeline_integrity_issue_type_counts" => %{},
      "station_reservation_evidence_row_count" => 1,
      "station_reservation_expiration_evidence_row_count" => 1,
      "input_keys" => [
        "contact_success_rate",
        "station_throughput_factor"
      ],
      "trust_boundary_status" => "declared",
      "trust_boundaries" => ["ops_operational_timeline_rows"],
      "branch_local_operational_timeline_pressure" => true,
      "branch_local_feedback_pressure" => true,
      "branch_local_activity_routing_pressure" => true,
      "branch_local_integrity_pressure" => false,
      "branch_local_station_reservation_pressure" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "operational_timeline_source_report_provenance_only",
        "operator_authority" => "not_granted_by_operational_timeline_replay_summary",
        "operational_feedback_application" => "not_performed_by_summary",
        "timeline_mutation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_operational_timeline_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }

    assert CandidateRefresh.operational_timeline_replay_summary(refresh) == replay_summary

    assert OrbitalDynamics.candidate_refresh_operational_timeline_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_operational_timeline_contract" => "operational_timeline_report.v1",
             "source_report_operational_timeline_count" => 1,
             "source_report_operational_timeline_row_count" => 1,
             "source_report_operational_timeline_paths" => [
               "source_operational_timeline_report"
             ],
             "source_report_operational_timeline_operational_kind_counts" => %{
               "contact" => 1
             },
             "source_report_operational_timeline_activity_id_counts" => %{
               "ops_contact_feedback" => 1
             },
             "source_report_operational_timeline_activity_status_counts" => %{
               "planned" => 1
             },
             "source_report_operational_timeline_approval_status_counts" => %{
               "not_evaluated" => 1
             },
             "source_report_operational_timeline_required_operator_action_counts" => %{
               "review_activity_approval" => 1
             },
             "source_report_operational_timeline_cadence_import_status_counts" => %{
               "missing" => 1
             },
             "source_report_operational_timeline_branch_local_operational_timeline_pressure" =>
               true,
             "source_report_operational_timeline_branch_local_feedback_pressure" => true,
             "source_report_operational_timeline_branch_local_activity_routing_pressure" => true,
             "source_report_operational_timeline_branch_local_integrity_pressure" => false,
             "source_report_operational_timeline_branch_local_station_reservation_pressure" =>
               true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.operational_timeline_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_operational_timeline_replay_summary(artifact) ==
             replay_summary
  end

  test "source report summary replays exact operational timeline reports from result artifacts" do
    source_report =
      Timeline.operational_report(
        [
          %{
            id: :exact_ops_contact,
            type: :downlink,
            status: :planned,
            approval_status: :pending,
            scenario_id: :leo_1,
            spacecraft_id: :sat_1,
            ground_station_id: :equator_prime,
            direction: :downlink,
            starts_at_s: 10.0,
            ends_at_s: 40.0,
            contact_success_factor: 0.4,
            actual_throughput_mb: 20.0,
            estimated_throughput_mb: 50.0,
            provenance: %{trust_boundary: :exact_source_ops_row}
          }
        ],
        source: "exact.source.ops"
      )
      |> Map.put("provenance", %{"trust_boundary" => "exact_source_ops_report"})

    result_report =
      Timeline.operational_report(
        [
          %{
            id: :exact_ops_reservation,
            type: :downlink,
            status: :planned,
            approval_status: :approved,
            scenario_id: :leo_1,
            spacecraft_id: :sat_1,
            ground_station_id: :polar_prime,
            direction: :downlink,
            starts_at_s: 50.0,
            ends_at_s: 90.0,
            station_reservation_id: :reservation_exact_ops,
            station_reservation_expires_at_s: 360.0,
            provenance: %{trust_boundary: :exact_result_ops_row}
          }
        ],
        source: "exact.result.ops"
      )
      |> Map.put("provenance", %{"trust_boundary" => "exact_result_ops_report"})

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(source_report)

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(result_report)

    refresh = %{
      "source_result_artifact" => source_report,
      "result_artifact" => result_report
    }

    assert %{
             "source_report_operational_timeline_activity_id_counts" => %{
               "exact_ops_contact" => 1,
               "exact_ops_reservation" => 1
             },
             "source_report_operational_timeline_required_operator_action_counts" => %{
               "prepare_cadence_import" => 1,
               "review_activity_approval" => 1
             },
             "source_report_operational_timeline_cadence_import_status_counts" => %{
               "missing" => 2
             },
             "source_reports" => %{
               "operational_timeline_report" => %{
                 "paths" => ["source_result_artifact", "result_artifact"],
                 "contract" => "operational_timeline_report.v1",
                 "count" => 2,
                 "row_count" => 2,
                 "contact_feedback_count" => 1,
                 "station_throughput_feedback_count" => 1,
                 "operational_kind_counts" => %{"contact" => 2},
                 "activity_id_counts" => %{
                   "exact_ops_contact" => 1,
                   "exact_ops_reservation" => 1
                 },
                 "activity_status_counts" => %{"planned" => 2},
                 "approval_status_counts" => %{"approved" => 1, "pending" => 1},
                 "required_operator_action_counts" => %{
                   "prepare_cadence_import" => 1,
                   "review_activity_approval" => 1
                 },
                 "cadence_import_status_counts" => %{
                   "missing" => 2
                 },
                 "station_reservation_evidence_row_count" => 1,
                 "station_reservation_expiration_evidence_row_count" => 1,
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => [
                   "exact_result_ops_report",
                   "exact_result_ops_row",
                   "exact_source_ops_report",
                   "exact_source_ops_row"
                 ]
               }
             }
           } = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "contract" => "operational_timeline_report.v1",
             "source_report_count" => 2,
             "source_report_row_count" => 2,
             "source_report_paths" => ["source_result_artifact", "result_artifact"],
             "contact_feedback_count" => 1,
             "station_throughput_feedback_count" => 1,
             "operational_kind_counts" => %{"contact" => 2},
             "activity_id_counts" => %{
               "exact_ops_contact" => 1,
               "exact_ops_reservation" => 1
             },
             "activity_status_counts" => %{"planned" => 2},
             "approval_status_counts" => %{"approved" => 1, "pending" => 1},
             "required_operator_action_counts" => %{
               "prepare_cadence_import" => 1,
               "review_activity_approval" => 1
             },
             "cadence_import_status_counts" => %{"missing" => 2},
             "station_reservation_evidence_row_count" => 1,
             "station_reservation_expiration_evidence_row_count" => 1,
             "trust_boundaries" => [
               "exact_result_ops_report",
               "exact_result_ops_row",
               "exact_source_ops_report",
               "exact_source_ops_row"
             ],
             "branch_local_operational_timeline_pressure" => true,
             "branch_local_feedback_pressure" => true,
             "branch_local_activity_routing_pressure" => true,
             "branch_local_station_reservation_pressure" => true
           } = CandidateRefresh.operational_timeline_replay_summary(refresh)
  end

  test "operational timeline replay treats station reservation evidence as family pressure" do
    refresh = %{
      "source_operational_timeline_report" => %{
        "schema_contract" => "operational_timeline_report.v1",
        "rows" => [
          %{
            "station_reservation_id" => "reservation_ops_only",
            "station_reservation_expires_at_s" => 420.0,
            "trust_boundary" => "ops_operational_timeline_rows"
          }
        ],
        "provenance" => %{"trust_boundary" => "ops_operational_timeline_report"}
      }
    }

    summary = CandidateRefresh.operational_timeline_replay_summary(refresh)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1
    assert summary["contact_feedback_count"] == 0
    assert summary["command_feedback_count"] == 0
    assert summary["maneuver_feedback_count"] == 0
    assert summary["observation_feedback_count"] == 0
    assert summary["station_throughput_feedback_count"] == 0
    assert summary["input_keys"] == []
    assert summary["activity_id_counts"] == %{}
    assert summary["operational_kind_counts"] == %{}
    assert summary["cadence_import_status_counts"] == %{}
    assert summary["timeline_integrity_issue_count"] == 0
    assert summary["dependency_integrity_issue_count"] == 0
    assert summary["exclusivity_integrity_issue_count"] == 0
    assert summary["station_reservation_evidence_row_count"] == 1
    assert summary["station_reservation_expiration_evidence_row_count"] == 1
    assert summary["branch_local_operational_timeline_pressure"]
    assert summary["branch_local_station_reservation_pressure"]
    refute summary["branch_local_feedback_pressure"]
    refute summary["branch_local_activity_routing_pressure"]
    refute summary["branch_local_integrity_pressure"]
  end

  test "operational timeline replay treats required action maps as family pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "operational_timeline_report" => %{
            "contract" => "operational_timeline_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_operational_timeline_report"],
            "contact_feedback_count" => 0,
            "command_feedback_count" => 0,
            "maneuver_feedback_count" => 0,
            "observation_feedback_count" => 0,
            "station_throughput_feedback_count" => 0,
            "operational_kind_counts" => %{},
            "activity_id_counts" => %{},
            "activity_status_counts" => %{},
            "approval_status_counts" => %{},
            "required_operator_action_counts" => %{"review_activity_approval" => 1},
            "cadence_import_status_counts" => %{},
            "timeline_integrity_issue_count" => 0,
            "dependency_integrity_issue_count" => 0,
            "exclusivity_integrity_issue_count" => 0,
            "timeline_integrity_issue_type_counts" => %{},
            "station_reservation_evidence_row_count" => 0,
            "station_reservation_expiration_evidence_row_count" => 0,
            "input_keys" => [],
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["ops_operational_timeline_rows"]
          }
        }
      }
    }

    summary = CandidateRefresh.operational_timeline_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1
    assert summary["required_operator_action_counts"] == %{"review_activity_approval" => 1}
    assert summary["branch_local_operational_timeline_pressure"]
    refute summary["branch_local_feedback_pressure"]
    refute summary["branch_local_activity_routing_pressure"]
    refute summary["branch_local_integrity_pressure"]
    refute summary["branch_local_station_reservation_pressure"]
  end

  test "operational timeline replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.operational_timeline_replay_summary(artifact)
    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_operational_timeline_pressure"]
    refute Map.has_key?(source_summary, "source_report_operational_timeline_contract")
    refute Map.has_key?(source_summary, "source_report_operational_timeline_count")
    refute Map.has_key?(source_summary, "source_report_operational_timeline_row_count")
    refute Map.has_key?(source_summary, "source_report_operational_timeline_paths")
  end

  test "operational timeline source summary keeps declared contract without partial identity placeholders" do
    placeholder_fields = [
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.operational_timeline_report"]},
      %{"count" => nil, "row_count" => 2},
      %{"count" => 1, "row_count" => nil}
    ]

    for placeholder <- placeholder_fields do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "operational_timeline_report" =>
              Map.put(
                placeholder,
                "contract",
                "operational_timeline_report.v1"
              )
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      assert source_summary["source_report_operational_timeline_contract"] ==
               "operational_timeline_report.v1"

      refute Map.has_key?(source_summary, "source_report_operational_timeline_count")
      refute Map.has_key?(source_summary, "source_report_operational_timeline_row_count")
      refute Map.has_key?(source_summary, "source_report_operational_timeline_paths")
    end
  end

  test "operational timeline source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "operational_timeline_report" => %{
            "contract" => "operational_timeline_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.operational_timeline_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_operational_timeline_contract"] ==
             "operational_timeline_report.v1"

    assert source_summary["source_report_operational_timeline_count"] == 0
    assert source_summary["source_report_operational_timeline_row_count"] == 0

    assert source_summary["source_report_operational_timeline_paths"] == [
             "provenance.source_reports.operational_timeline_report"
           ]
  end

  test "operational timeline source summary omits missing identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "operational_timeline_report" => %{
            "contract" => "operational_timeline_report.v1",
            "count" => 1,
            "row_count" => 2
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_operational_timeline_contract"] ==
             "operational_timeline_report.v1"

    assert source_summary["source_report_operational_timeline_count"] == 1
    assert source_summary["source_report_operational_timeline_row_count"] == 2
    refute Map.has_key?(source_summary, "source_report_operational_timeline_paths")
  end

  test "operational timeline source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "operational_timeline_report" => %{
            "contract" => "operational_timeline_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_operational_timeline_contract"] ==
             "operational_timeline_report.v1"

    assert source_summary["source_report_operational_timeline_count"] == 1
    assert source_summary["source_report_operational_timeline_row_count"] == 2
    assert source_summary["source_report_operational_timeline_paths"] == []
  end

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
