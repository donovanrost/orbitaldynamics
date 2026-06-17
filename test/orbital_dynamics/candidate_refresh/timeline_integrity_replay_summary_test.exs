defmodule OrbitalDynamics.CandidateRefresh.TimelineIntegrityReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, CandidateRefresh, OperatorReview, Schema, Timeline}

  test "source report summary replays timeline integrity reports from row evidence" do
    report =
      Timeline.integrity_report(
        [
          %{id: :health_gate, type: :health_check, starts_at_s: 20.0, ends_at_s: 30.0},
          %{
            id: :dl_conflict,
            type: :downlink,
            timeline_id: :"timeline:downlink:12.0",
            starts_at_s: 12.0,
            ends_at_s: 25.0,
            exclusive_with: [:cmd_main],
            exclusive_with_timeline_ids: [
              :"timeline:command:dss_14:10.0",
              :"timeline:command:dss_14:10.0"
            ]
          },
          %{
            id: :cmd_main,
            type: :command,
            timeline_id: :"timeline:command:dss_14:10.0",
            starts_at_s: 10.0,
            ends_at_s: 15.0,
            ground_station_id: :dss_14,
            dependency_activity_ids: [:missing_gate, :health_gate, :health_gate],
            dependency_timeline_ids: [
              :"timeline:missing_gate",
              :"timeline:health_gate",
              :"timeline:health_gate"
            ],
            exclusive_with: [:dl_conflict],
            exclusive_with_timeline_ids: [:"timeline:downlink:12.0"]
          }
        ],
        source: "selected_activities"
      )
      |> Map.put("timeline_integrity_issue_count", 99)
      |> Map.put("timeline_integrity_review_count", 99)
      |> Map.put("dependency_issue_count", 99)
      |> Map.put("exclusivity_issue_count", 99)
      |> Map.put("timeline_integrity_issue_type_counts", %{"stale_issue" => 99})
      |> Map.put("required_operator_action_counts", %{"stale_action" => 99})
      |> Map.put("provenance", %{"trust_boundary" => "timeline_integrity_rows"})

    refresh = %{
      "accepted_planning_state" => %{"timeline_integrity_report" => report},
      "mission_state" => %{"source_timeline_integrity_report" => report},
      "source_timeline_integrity_report" => report,
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "provenance" => %{"trust_boundary" => "wrapped_timeline_integrity"},
        "timeline_integrity_report" => Map.delete(report, "provenance")
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 4,
             "source_report_row_count" => 8,
             "source_report_counts_by_contract" => %{"timeline_integrity_report.v1" => 4},
             "source_report_timeline_integrity_contract" => "timeline_integrity_report.v1",
             "source_report_timeline_integrity_count" => 4,
             "source_report_timeline_integrity_row_count" => 8,
             "source_report_timeline_integrity_paths" => [
               "accepted_planning_state.timeline_integrity_report",
               "mission_state.source_timeline_integrity_report",
               "source_timeline_integrity_report",
               "source_result_artifact.timeline_integrity_report"
             ],
             "source_report_timeline_integrity_issue_count" => 44,
             "source_report_timeline_integrity_review_count" => 8,
             "source_report_timeline_integrity_dependency_issue_count" => 24,
             "source_report_timeline_integrity_exclusivity_issue_count" => 20,
             "source_report_timeline_integrity_status_counts" => %{
               "review_required" => 8
             },
             "source_report_timeline_integrity_required_operator_action_counts" => %{
               "review_timeline_integrity" => 8
             },
             "source_report_timeline_integrity_review_activity_id_counts" => %{
               "cmd_main" => 4,
               "dl_conflict" => 4
             },
             "source_report_timeline_integrity_review_timeline_id_counts" => %{
               "timeline:command:dss_14:10.0" => 4,
               "timeline:downlink:12.0" => 4
             },
             "source_report_timeline_integrity_missing_dependency_activity_id_counts" => %{
               "missing_gate" => 4
             },
             "source_report_timeline_integrity_missing_dependency_timeline_id_counts" => %{
               "timeline:health_gate" => 4,
               "timeline:missing_gate" => 4
             },
             "source_report_timeline_integrity_exclusivity_violation_activity_id_counts" => %{
               "cmd_main" => 4,
               "dl_conflict" => 4
             },
             "source_report_timeline_integrity_exclusivity_violation_timeline_id_counts" => %{
               "timeline:command:dss_14:10.0" => 4,
               "timeline:downlink:12.0" => 4
             },
             "source_report_timeline_integrity_branch_local_timeline_integrity_pressure" => true,
             "source_report_timeline_integrity_branch_local_timeline_integrity_review_pressure" =>
               true,
             "source_report_timeline_integrity_branch_local_dependency_integrity_pressure" =>
               true,
             "source_report_timeline_integrity_branch_local_exclusivity_integrity_pressure" =>
               true,
             "source_reports" => %{
               "timeline_integrity_report" => %{
                 "contract" => "timeline_integrity_report.v1",
                 "count" => 4,
                 "row_count" => 8,
                 "timeline_integrity_issue_count" => 44,
                 "timeline_integrity_review_count" => 8,
                 "dependency_issue_count" => 24,
                 "exclusivity_issue_count" => 20,
                 "timeline_integrity_issue_type_counts" => %{
                   "dependency_order_violation" => 4,
                   "duplicate_dependency_activity" => 4,
                   "duplicate_dependency_timeline" => 4,
                   "duplicate_exclusivity_timeline" => 4,
                   "exclusivity_overlap" => 16,
                   "missing_dependency_activity" => 4,
                   "missing_dependency_timeline" => 8
                 },
                 "operator_action_reason_counts" => %{"timeline_integrity_issue" => 8},
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => [
                   "timeline_integrity_rows",
                   "wrapped_timeline_integrity"
                 ]
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = CandidateRefresh.timeline_integrity_replay_summary(refresh)

    assert %{
             "model" => "artifact_only_candidate_refresh_timeline_integrity_replay_summary",
             "source" => "candidate_refresh.source_report_provenance.timeline_integrity_report",
             "contract" => "timeline_integrity_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 8,
             "source_report_paths" => [
               "accepted_planning_state.timeline_integrity_report",
               "mission_state.source_timeline_integrity_report",
               "source_timeline_integrity_report",
               "source_result_artifact.timeline_integrity_report"
             ],
             "timeline_integrity_issue_count" => 44,
             "timeline_integrity_review_count" => 8,
             "dependency_issue_count" => 24,
             "exclusivity_issue_count" => 20,
             "required_operator_action_counts" => %{"review_timeline_integrity" => 8},
             "review_activity_id_counts" => %{"cmd_main" => 4, "dl_conflict" => 4},
             "missing_dependency_timeline_id_counts" => %{
               "timeline:health_gate" => 4,
               "timeline:missing_gate" => 4
             },
             "exclusivity_violation_timeline_id_counts" => %{
               "timeline:command:dss_14:10.0" => 4,
               "timeline:downlink:12.0" => 4
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "timeline_integrity_rows",
               "wrapped_timeline_integrity"
             ],
             "branch_local_timeline_integrity_pressure" => true,
             "branch_local_timeline_integrity_review_pressure" => true,
             "branch_local_dependency_integrity_pressure" => true,
             "branch_local_exclusivity_integrity_pressure" => true
           } = replay_summary

    assert OrbitalDynamics.candidate_refresh_timeline_integrity_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_timeline_integrity_branch_local_timeline_integrity_pressure" => true,
             "source_report_timeline_integrity_branch_local_timeline_integrity_review_pressure" =>
               true,
             "source_report_timeline_integrity_branch_local_dependency_integrity_pressure" =>
               true,
             "source_report_timeline_integrity_branch_local_exclusivity_integrity_pressure" =>
               true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.timeline_integrity_replay_summary(artifact) == replay_summary
  end

  test "timeline integrity replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.timeline_integrity_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_timeline_integrity_contract")
    refute Map.has_key?(source_summary, "source_report_timeline_integrity_count")
    refute Map.has_key?(source_summary, "source_report_timeline_integrity_row_count")
    refute Map.has_key?(source_summary, "source_report_timeline_integrity_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_timeline_integrity_pressure"]
  end

  test "timeline integrity source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "timeline_integrity_report.v1"},
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.timeline_integrity_report"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.timeline_integrity_report"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "timeline_integrity_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_timeline_integrity_contract"] ==
                 "timeline_integrity_report.v1"
      else
        refute Map.has_key?(source_summary, "source_report_timeline_integrity_contract")
      end

      refute Map.has_key?(source_summary, "source_report_timeline_integrity_count")
      refute Map.has_key?(source_summary, "source_report_timeline_integrity_row_count")
      refute Map.has_key?(source_summary, "source_report_timeline_integrity_paths")
    end
  end

  test "timeline integrity source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_integrity_report" => %{
            "contract" => "timeline_integrity_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.timeline_integrity_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_integrity_contract"] ==
             "timeline_integrity_report.v1"

    assert source_summary["source_report_timeline_integrity_count"] == 0
    assert source_summary["source_report_timeline_integrity_row_count"] == 0

    assert source_summary["source_report_timeline_integrity_paths"] == [
             "provenance.source_reports.timeline_integrity_report"
           ]
  end

  test "timeline integrity source summary omits missing identity paths after preserving counts" do
    summaries = [
      {"missing paths",
       %{
         "contract" => "timeline_integrity_report.v1",
         "count" => 1,
         "row_count" => 2
       }},
      {"nil paths",
       %{
         "contract" => "timeline_integrity_report.v1",
         "count" => 1,
         "row_count" => 2,
         "paths" => nil
       }}
    ]

    for {label, timeline_integrity_summary} <- summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "timeline_integrity_report" => timeline_integrity_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      assert source_summary["source_report_timeline_integrity_contract"] ==
               "timeline_integrity_report.v1",
             label

      assert source_summary["source_report_timeline_integrity_count"] == 1, label
      assert source_summary["source_report_timeline_integrity_row_count"] == 2, label
      refute Map.has_key?(source_summary, "source_report_timeline_integrity_paths"), label
    end
  end

  test "timeline integrity source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_integrity_report" => %{
            "contract" => "timeline_integrity_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_integrity_contract"] ==
             "timeline_integrity_report.v1"

    assert source_summary["source_report_timeline_integrity_count"] == 1
    assert source_summary["source_report_timeline_integrity_row_count"] == 2
    assert source_summary["source_report_timeline_integrity_paths"] == []
  end

  test "timeline integrity replay preserves pressure maps with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_integrity_report" => %{
            "contract" => "timeline_integrity_report.v1",
            "count" => 1,
            "timeline_integrity_status_counts" => %{"review_required" => 1},
            "timeline_integrity_issue_type_counts" => %{"missing_dependency_timeline" => 1},
            "required_operator_action_counts" => %{"review_timeline_integrity" => 1},
            "review_activity_id_counts" => %{"cmd_main" => 1},
            "missing_dependency_timeline_id_counts" => %{"timeline:missing_gate" => 1},
            "exclusivity_violation_timeline_id_counts" => %{
              "timeline:downlink:12.0" => 1
            }
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_timeline_integrity_count")
    refute Map.has_key?(source_summary, "source_report_timeline_integrity_row_count")
    refute Map.has_key?(source_summary, "source_report_timeline_integrity_paths")

    assert source_summary["source_report_timeline_integrity_status_counts"] == %{
             "review_required" => 1
           }

    assert source_summary["source_report_timeline_integrity_issue_type_counts"] == %{
             "missing_dependency_timeline" => 1
           }

    assert source_summary[
             "source_report_timeline_integrity_required_operator_action_counts"
           ] == %{"review_timeline_integrity" => 1}

    assert source_summary[
             "source_report_timeline_integrity_review_activity_id_counts"
           ] == %{"cmd_main" => 1}

    assert source_summary[
             "source_report_timeline_integrity_missing_dependency_timeline_id_counts"
           ] == %{"timeline:missing_gate" => 1}

    assert source_summary[
             "source_report_timeline_integrity_exclusivity_violation_timeline_id_counts"
           ] == %{"timeline:downlink:12.0" => 1}

    summary = CandidateRefresh.timeline_integrity_replay_summary(artifact)

    assert summary["branch_local_timeline_integrity_pressure"]
    assert summary["branch_local_timeline_integrity_review_pressure"]
    assert summary["branch_local_dependency_integrity_pressure"]
    assert summary["branch_local_exclusivity_integrity_pressure"]
  end

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

  test "operator review and import lift timeline integrity reports from candidate refresh artifacts" do
    integrity_report = fn source ->
      Timeline.integrity_report(
        [
          %{id: :health_gate, type: :health_check, starts_at_s: 20.0, ends_at_s: 30.0},
          %{
            id: :"#{source}_dl_conflict",
            type: :downlink,
            timeline_id: :"timeline:#{source}:downlink:12.0",
            starts_at_s: 12.0,
            ends_at_s: 25.0,
            exclusive_with: [:"#{source}_cmd_main"],
            exclusive_with_timeline_ids: [
              :"timeline:#{source}:command:dss_14:10.0",
              :"timeline:#{source}:command:dss_14:10.0"
            ]
          },
          %{
            id: :"#{source}_cmd_main",
            type: :command,
            timeline_id: :"timeline:#{source}:command:dss_14:10.0",
            starts_at_s: 10.0,
            ends_at_s: 15.0,
            ground_station_id: :dss_14,
            dependency_activity_ids: [:missing_gate, :health_gate, :health_gate],
            dependency_timeline_ids: [
              :"timeline:missing_gate",
              :"timeline:health_gate",
              :"timeline:health_gate"
            ],
            exclusive_with: [:"#{source}_dl_conflict"],
            exclusive_with_timeline_ids: [:"timeline:#{source}:downlink:12.0"]
          }
        ],
        source: source
      )
    end

    direct_report = integrity_report.("direct_integrity")
    canonical_report = integrity_report.("canonical_integrity")
    wrapped_report = integrity_report.("wrapped_integrity")
    nested_report = integrity_report.("nested_integrity")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:timeline_integrity_handoff",
      "source_timeline_integrity_report" => [direct_report],
      "timeline_integrity_report" => canonical_report,
      "source_result_artifact" => [
        wrapped_report,
        %{
          "schema_contract" => "result_artifact.v1",
          "timeline_integrity_report" => nested_report
        }
      ]
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    integrity_rows =
      Enum.filter(review["rows"], &(&1["review_type"] == "timeline_integrity_review"))

    assert length(integrity_rows) == 8

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "timeline_integrity_review_count" => 8,
             "review_type_counts" => %{"timeline_integrity_review" => 8}
           } = review

    assert Enum.sort(Enum.map(integrity_rows, & &1["source"]) |> Enum.uniq()) == [
             "candidate_refresh.source_result_artifact[0].rows",
             "candidate_refresh.source_result_artifact[1].timeline_integrity_report.rows",
             "candidate_refresh.source_timeline_integrity_report[0].rows",
             "candidate_refresh.timeline_integrity_report.rows"
           ]

    assert Enum.any?(
             integrity_rows,
             &match?(
               %{
                 "source" => "candidate_refresh.timeline_integrity_report.rows",
                 "activity_id" => "canonical_integrity_cmd_main",
                 "timeline_id" => "timeline:canonical_integrity:command:dss_14:10.0",
                 "timeline_integrity_status" => "review_required",
                 "required_operator_action" => "review_timeline_integrity",
                 "missing_dependency_activity_ids" => ["missing_gate"],
                 "missing_dependency_timeline_ids" => [
                   "timeline:health_gate",
                   "timeline:missing_gate"
                 ],
                 "source_timeline_integrity" => %{
                   "activity_id" => "canonical_integrity_cmd_main",
                   "timeline_integrity_status" => "review_required"
                 }
               },
               &1
             )
           )

    assert Enum.any?(
             integrity_rows,
             &match?(
               %{
                 "source" => "candidate_refresh.timeline_integrity_report.rows",
                 "activity_id" => "canonical_integrity_dl_conflict",
                 "exclusivity_violation_activity_ids" => ["canonical_integrity_cmd_main"],
                 "exclusivity_violation_timeline_ids" => [
                   "timeline:canonical_integrity:command:dss_14:10.0"
                 ],
                 "duplicate_exclusivity_timeline_ids" => [
                   "timeline:canonical_integrity:command:dss_14:10.0"
                 ]
               },
               &1
             )
           )

    import_rows =
      Enum.filter(import["rows"], &(&1["source_review_type"] == "timeline_integrity_review"))

    assert length(import_rows) == 8

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "import_action_counts" => %{"review_timeline_integrity" => 8},
             "source_review_type_counts" => %{"timeline_integrity_review" => 8}
           } = import

    assert Enum.all?(
             import_rows,
             &(&1["import_action"] == "review_timeline_integrity" and
                 &1["import_status"] == "review_required_before_import" and
                 &1["source_review_row"]["source_timeline_integrity"])
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end
end
