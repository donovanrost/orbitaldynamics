defmodule OrbitalDynamics.CandidateRefresh.TimelineFeedbackReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary derives timeline feedback replay maps from rows" do
    refresh = %{
      "source_timeline_feedback_report" => %{
        "schema_contract" => "timeline_feedback_report.v1",
        "rows" => [
          %{
            "id" => "timeline_feedback:contact",
            "activity_id" => "dl_feedback_activity",
            "feedback_kind" => "contact",
            "status" => "matched",
            "match_strategy" => "activity_id",
            "ground_station_id" => "equator_prime",
            "contact_success_factor" => 0.8,
            "actual_throughput_mb" => 40.0,
            "planned_estimated_throughput_mb" => 50.0,
            "station_reservation_id" => "reservation_feedback",
            "station_reservation_expires_at_s" => 240.0,
            "cadence_import_status" => "review_required",
            "trust_boundary" => "ops_timeline_feedback_rows"
          }
        ],
        "status_counts" => %{"stale_status" => 99},
        "feedback_kind_counts" => %{"stale_kind" => 99},
        "match_strategy_counts" => %{"stale_strategy" => 99},
        "activity_id_counts" => %{"stale_activity" => 99},
        "cadence_import_status_counts" => %{"stale_import_status" => 99},
        "trust_boundary" => "ops_timeline_feedback_report"
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_timeline_feedback_contract" => "timeline_feedback_report.v1",
             "source_report_timeline_feedback_count" => 1,
             "source_report_timeline_feedback_row_count" => 1,
             "source_report_timeline_feedback_paths" => ["source_timeline_feedback_report"],
             "source_report_timeline_feedback_cadence_import_status_counts" => %{
               "review_required" => 1
             },
             "source_report_timeline_feedback_activity_id_counts" => %{
               "dl_feedback_activity" => 1
             },
             "source_report_timeline_feedback_branch_local_timeline_feedback_pressure" => true,
             "source_report_timeline_feedback_branch_local_feedback_input_pressure" => true,
             "source_report_timeline_feedback_branch_local_activity_routing_pressure" => true,
             "source_report_timeline_feedback_branch_local_match_review_pressure" => true,
             "source_report_timeline_feedback_branch_local_import_review_pressure" => true,
             "source_report_timeline_feedback_branch_local_station_reservation_pressure" => true,
             "source_reports" => %{
               "timeline_feedback_report" => %{
                 "row_count" => 1,
                 "input_keys" => [
                   "contact_success_rate",
                   "station_throughput_factor"
                 ],
                 "status_counts" => %{"matched" => 1},
                 "feedback_kind_counts" => %{"contact" => 1},
                 "match_strategy_counts" => %{"activity_id" => 1},
                 "activity_id_counts" => %{"dl_feedback_activity" => 1},
                 "cadence_import_status_counts" => %{"review_required" => 1},
                 "station_reservation_evidence_row_count" => 1,
                 "station_reservation_expiration_evidence_row_count" => 1
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = %{
      "model" => "artifact_only_candidate_refresh_timeline_feedback_replay_summary",
      "source" => "candidate_refresh.source_report_provenance.timeline_feedback_report",
      "contract" => "timeline_feedback_report.v1",
      "source_report_count" => 1,
      "source_report_row_count" => 1,
      "source_report_paths" => ["source_timeline_feedback_report"],
      "input_keys" => [
        "contact_success_rate",
        "station_throughput_factor"
      ],
      "status_counts" => %{"matched" => 1},
      "feedback_kind_counts" => %{"contact" => 1},
      "match_strategy_counts" => %{"activity_id" => 1},
      "activity_id_counts" => %{"dl_feedback_activity" => 1},
      "cadence_import_status_counts" => %{"review_required" => 1},
      "station_reservation_evidence_row_count" => 1,
      "station_reservation_expiration_evidence_row_count" => 1,
      "trust_boundary_status" => "declared",
      "trust_boundaries" => ["ops_timeline_feedback_report", "ops_timeline_feedback_rows"],
      "branch_local_timeline_feedback_pressure" => true,
      "branch_local_feedback_input_pressure" => true,
      "branch_local_activity_routing_pressure" => true,
      "branch_local_match_review_pressure" => true,
      "branch_local_import_review_pressure" => true,
      "branch_local_station_reservation_pressure" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "timeline_feedback_source_report_provenance_only",
        "operator_authority" => "not_granted_by_timeline_feedback_replay_summary",
        "operational_feedback_application" => "not_performed_by_summary",
        "timeline_mutation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_timeline_feedback_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }

    assert CandidateRefresh.timeline_feedback_replay_summary(refresh) == replay_summary

    assert OrbitalDynamics.candidate_refresh_timeline_feedback_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_timeline_feedback_cadence_import_status_counts" => %{
               "review_required" => 1
             },
             "source_report_timeline_feedback_activity_id_counts" => %{
               "dl_feedback_activity" => 1
             },
             "source_report_timeline_feedback_branch_local_timeline_feedback_pressure" => true,
             "source_report_timeline_feedback_branch_local_feedback_input_pressure" => true,
             "source_report_timeline_feedback_branch_local_activity_routing_pressure" => true,
             "source_report_timeline_feedback_branch_local_match_review_pressure" => true,
             "source_report_timeline_feedback_branch_local_import_review_pressure" => true,
             "source_report_timeline_feedback_branch_local_station_reservation_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.timeline_feedback_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_timeline_feedback_replay_summary(artifact) ==
             replay_summary
  end

  test "source report summary replays exact timeline feedback reports from result artifacts" do
    source_report = %{
      "schema_contract" => "timeline_feedback_report.v1",
      "rows" => [
        %{
          "id" => "timeline_feedback:exact_source",
          "activity_id" => "exact_feedback_source_activity",
          "feedback_kind" => "contact",
          "status" => "matched",
          "match_strategy" => "activity_id",
          "cadence_import_status" => "review_required",
          "trust_boundary" => "exact_source_feedback_row"
        }
      ],
      "provenance" => %{"trust_boundary" => "exact_source_feedback_report"}
    }

    result_report = %{
      "schema_contract" => "timeline_feedback_report.v1",
      "rows" => [
        %{
          "id" => "timeline_feedback:exact_result",
          "activity_id" => "exact_feedback_result_activity",
          "feedback_kind" => "maneuver",
          "status" => "partial",
          "match_strategy" => "timeline_id",
          "cadence_import_status" => "ready",
          "station_reservation_id" => "exact_feedback_reservation",
          "station_reservation_expires_at_s" => 300.0,
          "trust_boundary" => "exact_result_feedback_row"
        }
      ],
      "provenance" => %{"trust_boundary" => "exact_result_feedback_report"}
    }

    refresh = %{
      "source_result_artifact" => source_report,
      "result_artifact" => result_report
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 2,
             "source_report_counts_by_contract" => %{"timeline_feedback_report.v1" => 2},
             "source_reports" => %{
               "timeline_feedback_report" => %{
                 "paths" => ["source_result_artifact", "result_artifact"],
                 "contract" => "timeline_feedback_report.v1",
                 "count" => 2,
                 "row_count" => 2,
                 "status_counts" => %{"matched" => 1, "partial" => 1},
                 "feedback_kind_counts" => %{"contact" => 1, "maneuver" => 1},
                 "match_strategy_counts" => %{"activity_id" => 1, "timeline_id" => 1},
                 "activity_id_counts" => %{
                   "exact_feedback_result_activity" => 1,
                   "exact_feedback_source_activity" => 1
                 },
                 "cadence_import_status_counts" => %{"ready" => 1, "review_required" => 1},
                 "station_reservation_evidence_row_count" => 1,
                 "station_reservation_expiration_evidence_row_count" => 1,
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => [
                   "exact_result_feedback_report",
                   "exact_result_feedback_row",
                   "exact_source_feedback_report",
                   "exact_source_feedback_row"
                 ]
               }
             }
           } = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "contract" => "timeline_feedback_report.v1",
             "source_report_count" => 2,
             "source_report_row_count" => 2,
             "source_report_paths" => ["source_result_artifact", "result_artifact"],
             "status_counts" => %{"matched" => 1, "partial" => 1},
             "feedback_kind_counts" => %{"contact" => 1, "maneuver" => 1},
             "match_strategy_counts" => %{"activity_id" => 1, "timeline_id" => 1},
             "activity_id_counts" => %{
               "exact_feedback_result_activity" => 1,
               "exact_feedback_source_activity" => 1
             },
             "cadence_import_status_counts" => %{"ready" => 1, "review_required" => 1},
             "station_reservation_evidence_row_count" => 1,
             "station_reservation_expiration_evidence_row_count" => 1,
             "trust_boundaries" => [
               "exact_result_feedback_report",
               "exact_result_feedback_row",
               "exact_source_feedback_report",
               "exact_source_feedback_row"
             ],
             "branch_local_timeline_feedback_pressure" => true,
             "branch_local_activity_routing_pressure" => true,
             "branch_local_match_review_pressure" => true,
             "branch_local_import_review_pressure" => true,
             "branch_local_station_reservation_pressure" => true
           } = CandidateRefresh.timeline_feedback_replay_summary(refresh)
  end

  test "timeline feedback replay treats station reservation evidence as family pressure" do
    refresh = %{
      "source_timeline_feedback_report" => %{
        "schema_contract" => "timeline_feedback_report.v1",
        "rows" => [
          %{
            "id" => "timeline_feedback:reservation_only",
            "station_reservation_id" => "reservation_feedback_only",
            "station_reservation_expires_at_s" => 240.0,
            "trust_boundary" => "ops_timeline_feedback_rows"
          }
        ],
        "provenance" => %{"trust_boundary" => "ops_timeline_feedback_report"}
      }
    }

    summary = CandidateRefresh.timeline_feedback_replay_summary(refresh)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1
    assert summary["input_keys"] == []
    assert summary["status_counts"] == %{}
    assert summary["feedback_kind_counts"] == %{}
    assert summary["activity_id_counts"] == %{}
    assert summary["cadence_import_status_counts"] == %{}
    assert summary["station_reservation_evidence_row_count"] == 1
    assert summary["station_reservation_expiration_evidence_row_count"] == 1
    assert summary["branch_local_timeline_feedback_pressure"]
    assert summary["branch_local_station_reservation_pressure"]
    refute summary["branch_local_feedback_input_pressure"]
    refute summary["branch_local_activity_routing_pressure"]
    refute summary["branch_local_import_review_pressure"]
  end

  test "timeline feedback replay treats match strategy maps as family pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_feedback_report" => %{
            "contract" => "timeline_feedback_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_timeline_feedback_report"],
            "input_keys" => [],
            "status_counts" => %{},
            "feedback_kind_counts" => %{},
            "match_strategy_counts" => %{"activity_id" => 1},
            "activity_id_counts" => %{},
            "cadence_import_status_counts" => %{},
            "station_reservation_evidence_row_count" => 0,
            "station_reservation_expiration_evidence_row_count" => 0,
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["ops_timeline_feedback_rows"]
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_feedback_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1
    assert summary["match_strategy_counts"] == %{"activity_id" => 1}
    assert summary["branch_local_timeline_feedback_pressure"]
    assert summary["branch_local_match_review_pressure"]
    refute summary["branch_local_feedback_input_pressure"]
    refute summary["branch_local_activity_routing_pressure"]
    refute summary["branch_local_import_review_pressure"]
    refute summary["branch_local_station_reservation_pressure"]
  end

  test "timeline feedback replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.timeline_feedback_replay_summary(artifact)
    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_timeline_feedback_pressure"]
    refute Map.has_key?(source_summary, "source_report_timeline_feedback_contract")
    refute Map.has_key?(source_summary, "source_report_timeline_feedback_count")
    refute Map.has_key?(source_summary, "source_report_timeline_feedback_row_count")
    refute Map.has_key?(source_summary, "source_report_timeline_feedback_paths")
  end

  test "timeline feedback direct parser remains map-only for source report slots" do
    report = %{
      "schema_contract" => "timeline_feedback_report.v1",
      "rows" => [
        %{
          "id" => "timeline_feedback:list_ignored",
          "activity_id" => "list_ignored_activity",
          "feedback_kind" => "contact",
          "status" => "matched"
        }
      ]
    }

    refresh = %{"source_timeline_feedback_report" => [report]}

    source_summary = CandidateRefresh.source_report_summary(refresh)
    replay_summary = CandidateRefresh.timeline_feedback_replay_summary(refresh)

    refute Map.has_key?(source_summary, "source_report_timeline_feedback_contract")
    refute Map.has_key?(source_summary, "source_report_timeline_feedback_count")
    refute Map.has_key?(source_summary, "source_report_timeline_feedback_row_count")
    refute Map.has_key?(source_summary, "source_report_timeline_feedback_paths")
    assert replay_summary["source_report_count"] == 0
    assert replay_summary["source_report_row_count"] == 0
    assert replay_summary["source_report_paths"] == []
  end

  test "timeline feedback source summary keeps declared contract without partial identity placeholders" do
    placeholder_fields = [
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.timeline_feedback_report"]},
      %{"count" => nil, "row_count" => 2},
      %{"count" => 1, "row_count" => nil}
    ]

    for placeholder <- placeholder_fields do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "timeline_feedback_report" =>
              Map.put(
                placeholder,
                "contract",
                "timeline_feedback_report.v1"
              )
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      assert source_summary["source_report_timeline_feedback_contract"] ==
               "timeline_feedback_report.v1"

      refute Map.has_key?(source_summary, "source_report_timeline_feedback_count")
      refute Map.has_key?(source_summary, "source_report_timeline_feedback_row_count")
      refute Map.has_key?(source_summary, "source_report_timeline_feedback_paths")
    end
  end

  test "timeline feedback source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_feedback_report" => %{
            "contract" => "timeline_feedback_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.timeline_feedback_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_feedback_contract"] ==
             "timeline_feedback_report.v1"

    assert source_summary["source_report_timeline_feedback_count"] == 0
    assert source_summary["source_report_timeline_feedback_row_count"] == 0

    assert source_summary["source_report_timeline_feedback_paths"] == [
             "provenance.source_reports.timeline_feedback_report"
           ]
  end

  test "timeline feedback source summary omits missing identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_feedback_report" => %{
            "contract" => "timeline_feedback_report.v1",
            "count" => 1,
            "row_count" => 2
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_feedback_contract"] ==
             "timeline_feedback_report.v1"

    assert source_summary["source_report_timeline_feedback_count"] == 1
    assert source_summary["source_report_timeline_feedback_row_count"] == 2
    refute Map.has_key?(source_summary, "source_report_timeline_feedback_paths")
  end

  test "timeline feedback source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_feedback_report" => %{
            "contract" => "timeline_feedback_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_feedback_contract"] ==
             "timeline_feedback_report.v1"

    assert source_summary["source_report_timeline_feedback_count"] == 1
    assert source_summary["source_report_timeline_feedback_row_count"] == 2
    assert source_summary["source_report_timeline_feedback_paths"] == []
  end

  test "timeline feedback replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_feedback_report" => %{
              "contract" => "timeline_feedback_report.v1",
              "count" => 1,
              "row_count" => 3,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_feedback_report"
              ],
              "input_keys" => ["contact_success_rate"],
              "status_counts" => %{"matched" => 2, "review_required" => 1},
              "feedback_kind_counts" => %{"command" => 1, "contact" => 2},
              "match_strategy_counts" => %{"activity_id" => 3},
              "activity_id_counts" => %{"branch_feedback_activity" => 3},
              "cadence_import_status_counts" => %{"present" => 2, "review_required" => 1},
              "station_reservation_evidence_row_count" => 1,
              "station_reservation_expiration_evidence_row_count" => 1,
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_timeline_feedback"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.timeline_feedback_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_feedback_report"

    assert summary["contract"] == "timeline_feedback_report.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 3

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_feedback_report"
           ]

    assert summary["input_keys"] == ["contact_success_rate"]
    assert summary["status_counts"] == %{"matched" => 2, "review_required" => 1}
    assert summary["feedback_kind_counts"] == %{"command" => 1, "contact" => 2}
    assert summary["match_strategy_counts"] == %{"activity_id" => 3}
    assert summary["activity_id_counts"] == %{"branch_feedback_activity" => 3}
    assert summary["cadence_import_status_counts"] == %{"present" => 2, "review_required" => 1}
    assert summary["station_reservation_evidence_row_count"] == 1
    assert summary["station_reservation_expiration_evidence_row_count"] == 1
    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_timeline_feedback"]
    assert summary["branch_local_timeline_feedback_pressure"]
    assert summary["branch_local_feedback_input_pressure"]
    assert summary["branch_local_activity_routing_pressure"]
    assert summary["branch_local_match_review_pressure"]
    assert summary["branch_local_import_review_pressure"]
    assert summary["branch_local_station_reservation_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_feedback_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_timeline_feedback_replay_summary(artifact) ==
             summary
  end

  test "timeline feedback replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "timeline_feedback_report" => %{
            "contract" => "timeline_feedback_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_timeline_feedback_report"
            ],
            "activity_id_counts" => %{"direct_feedback_activity" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_feedback_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_feedback_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_feedback_report"
           ]

    assert summary["activity_id_counts"] == %{"direct_feedback_activity" => 1}
    assert summary["branch_local_timeline_feedback_pressure"]
    assert summary["branch_local_activity_routing_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_feedback_candidate_source_report_summary_only"
  end

  test "timeline feedback replay falls back to provenance when branch summary lacks usable family" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_feedback_report" => %{},
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
          "timeline_feedback_report" => %{
            "contract" => "timeline_feedback_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_timeline_feedback_report"],
            "activity_id_counts" => %{"provenance_feedback_activity" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_feedback_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.timeline_feedback_report"

    assert summary["source_report_paths"] == ["source_timeline_feedback_report"]
    assert summary["activity_id_counts"] == %{"provenance_feedback_activity" => 1}
    assert summary["branch_local_timeline_feedback_pressure"]
    assert summary["branch_local_activity_routing_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_feedback_source_report_provenance_only"
  end

  test "timeline feedback replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_feedback_report" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_feedback_report"
              ],
              "input_keys" => ["command_success_rate"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_feedback_report" => %{
            "contract" => "timeline_feedback_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_timeline_feedback_report"],
            "activity_id_counts" => %{"provenance_feedback_activity" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_feedback_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_feedback_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_feedback_report"
           ]

    assert summary["input_keys"] == ["command_success_rate"]
    assert summary["activity_id_counts"] == %{}
    assert summary["contract"] == "timeline_feedback_report.v1"
    assert summary["branch_local_timeline_feedback_pressure"]
    assert summary["branch_local_feedback_input_pressure"]
    refute summary["branch_local_activity_routing_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_feedback_candidate_source_report_summary_only"
  end
end
