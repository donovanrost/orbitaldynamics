defmodule OrbitalDynamics.CandidateRefresh.CommandWindowReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary aggregates command window feedback routing keys" do
    refresh = %{
      "source_command_window_report" => %{
        "schema_contract" => "command_window_report.v1",
        "rows" => [
          %{
            "id" => "cmd_failed",
            "activity_id" => "cmd_failed",
            "direction" => "s-band command",
            "window_type" => "command_window",
            "command_success" => false,
            "required_operator_action" => "review_command_window",
            "provenance" => %{"trust_boundary" => "ops_command_window"}
          },
          %{
            "id" => "cmd_partial",
            "activity_id" => "cmd_partial",
            "direction" => "tracking_pass",
            "window_type" => "tracking_window",
            "command_success_factor" => 0.5,
            "required_operator_action" => "review_command_result",
            "provenance" => %{"trust_boundary" => "ops_command_window"}
          },
          %{
            "id" => "cmd_no_feedback",
            "activity_id" => "cmd_no_feedback",
            "direction" => "Up Link",
            "window_type" => "uplink_window",
            "command_result" => "success",
            "required_operator_action" => "none"
          }
        ],
        "direction_counts" => %{"stale_direction" => 99},
        "activity_ids_by_direction" => %{"stale_direction" => ["stale_activity"]},
        "window_ids_by_direction" => %{"stale_direction" => ["stale_window"]},
        "required_operator_action_counts" => %{"stale_action" => 99}
      }
    }

    expected_direction_routing = %{
      "command" => %{
        "activity_count" => 1,
        "activity_ids" => ["cmd_failed"],
        "window_ids" => ["cmd_failed"]
      },
      "tracking" => %{
        "activity_count" => 1,
        "activity_ids" => ["cmd_partial"],
        "window_ids" => ["cmd_partial"]
      },
      "uplink" => %{
        "activity_count" => 1,
        "activity_ids" => ["cmd_no_feedback"],
        "window_ids" => ["cmd_no_feedback"]
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_command_window_contract" => "command_window_report.v1",
             "source_report_command_window_count" => 1,
             "source_report_command_window_row_count" => 3,
             "source_report_command_window_paths" => ["source_command_window_report"],
             "source_report_command_window_command_feedback_count" => 2,
             "source_report_command_window_input_keys" => ["command_success_rate"],
             "source_report_command_window_direction_counts" => %{
               "command" => 1,
               "tracking" => 1,
               "uplink" => 1
             },
             "source_report_command_window_activity_ids_by_direction" => %{
               "command" => ["cmd_failed"],
               "tracking" => ["cmd_partial"],
               "uplink" => ["cmd_no_feedback"]
             },
             "source_report_command_window_window_ids_by_direction" => %{
               "command" => ["cmd_failed"],
               "tracking" => ["cmd_partial"],
               "uplink" => ["cmd_no_feedback"]
             },
             "source_report_command_window_direction_routing" => ^expected_direction_routing,
             "source_report_command_window_required_operator_action_counts" => %{
               "none" => 1,
               "review_command_result" => 1,
               "review_command_window" => 1
             },
             "source_report_command_window_branch_local_command_window_pressure" => true,
             "source_report_command_window_branch_local_command_feedback_pressure" => true,
             "source_report_command_window_branch_local_command_window_action_pressure" => true,
             "source_reports" => %{
               "command_window_report" => %{
                 "row_count" => 3,
                 "command_feedback_count" => 2,
                 "input_keys" => ["command_success_rate"],
                 "direction_counts" => %{
                   "command" => 1,
                   "tracking" => 1,
                   "uplink" => 1
                 },
                 "activity_ids_by_direction" => %{
                   "command" => ["cmd_failed"],
                   "tracking" => ["cmd_partial"],
                   "uplink" => ["cmd_no_feedback"]
                 },
                 "window_ids_by_direction" => %{
                   "command" => ["cmd_failed"],
                   "tracking" => ["cmd_partial"],
                   "uplink" => ["cmd_no_feedback"]
                 },
                 "direction_routing" => ^expected_direction_routing,
                 "required_operator_action_counts" => %{
                   "none" => 1,
                   "review_command_result" => 1,
                   "review_command_window" => 1
                 }
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = %{
      "model" => "artifact_only_candidate_refresh_command_window_replay_summary",
      "source" => "candidate_refresh.source_report_provenance.command_window_report",
      "contract" => "command_window_report.v1",
      "source_report_count" => 1,
      "source_report_row_count" => 3,
      "source_report_paths" => ["source_command_window_report"],
      "command_feedback_count" => 2,
      "input_keys" => ["command_success_rate"],
      "direction_counts" => %{
        "command" => 1,
        "tracking" => 1,
        "uplink" => 1
      },
      "activity_ids_by_direction" => %{
        "command" => ["cmd_failed"],
        "tracking" => ["cmd_partial"],
        "uplink" => ["cmd_no_feedback"]
      },
      "window_ids_by_direction" => %{
        "command" => ["cmd_failed"],
        "tracking" => ["cmd_partial"],
        "uplink" => ["cmd_no_feedback"]
      },
      "direction_routing" => expected_direction_routing,
      "required_operator_action_counts" => %{
        "none" => 1,
        "review_command_result" => 1,
        "review_command_window" => 1
      },
      "trust_boundary_status" => "declared",
      "trust_boundaries" => ["ops_command_window"],
      "branch_local_command_window_pressure" => true,
      "branch_local_command_feedback_pressure" => true,
      "branch_local_command_window_action_pressure" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "command_window_source_report_provenance_only",
        "operator_authority" => "not_granted_by_command_window_replay_summary",
        "command_execution" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_command_window_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }

    assert CandidateRefresh.command_window_replay_summary(refresh) == replay_summary

    assert OrbitalDynamics.candidate_refresh_command_window_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_command_window_contract" => "command_window_report.v1",
             "source_report_command_window_count" => 1,
             "source_report_command_window_row_count" => 3,
             "source_report_command_window_paths" => ["source_command_window_report"],
             "source_report_command_window_command_feedback_count" => 2,
             "source_report_command_window_input_keys" => ["command_success_rate"],
             "source_report_command_window_direction_counts" => %{
               "command" => 1,
               "tracking" => 1,
               "uplink" => 1
             },
             "source_report_command_window_activity_ids_by_direction" => %{
               "command" => ["cmd_failed"],
               "tracking" => ["cmd_partial"],
               "uplink" => ["cmd_no_feedback"]
             },
             "source_report_command_window_window_ids_by_direction" => %{
               "command" => ["cmd_failed"],
               "tracking" => ["cmd_partial"],
               "uplink" => ["cmd_no_feedback"]
             },
             "source_report_command_window_direction_routing" => ^expected_direction_routing,
             "source_report_command_window_required_operator_action_counts" => %{
               "none" => 1,
               "review_command_result" => 1,
               "review_command_window" => 1
             },
             "source_report_command_window_branch_local_command_window_pressure" => true,
             "source_report_command_window_branch_local_command_feedback_pressure" => true,
             "source_report_command_window_branch_local_command_window_action_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.command_window_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_command_window_replay_summary(artifact) ==
             replay_summary
  end

  test "command window replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.command_window_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_command_window_contract")
    refute Map.has_key?(source_summary, "source_report_command_window_count")
    refute Map.has_key?(source_summary, "source_report_command_window_row_count")
    refute Map.has_key?(source_summary, "source_report_command_window_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_command_window_pressure"]
  end

  test "command window source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "command_window_report.v1"},
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.command_window_report"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.command_window_report"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "command_window_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_command_window_contract"] ==
                 "command_window_report.v1"
      else
        refute Map.has_key?(source_summary, "source_report_command_window_contract")
      end

      refute Map.has_key?(source_summary, "source_report_command_window_count")
      refute Map.has_key?(source_summary, "source_report_command_window_row_count")
      refute Map.has_key?(source_summary, "source_report_command_window_paths")
    end
  end

  test "command window source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "command_window_report" => %{
            "contract" => "command_window_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.command_window_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_command_window_contract"] ==
             "command_window_report.v1"

    assert source_summary["source_report_command_window_count"] == 0
    assert source_summary["source_report_command_window_row_count"] == 0

    assert source_summary["source_report_command_window_paths"] == [
             "provenance.source_reports.command_window_report"
           ]
  end

  test "command window source summary omits missing identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "command_window_report" => %{
            "contract" => "command_window_report.v1",
            "count" => 1,
            "row_count" => 2
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_command_window_contract"] ==
             "command_window_report.v1"

    assert source_summary["source_report_command_window_count"] == 1
    assert source_summary["source_report_command_window_row_count"] == 2
    refute Map.has_key?(source_summary, "source_report_command_window_paths")
  end

  test "command window source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "command_window_report" => %{
            "contract" => "command_window_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_command_window_contract"] ==
             "command_window_report.v1"

    assert source_summary["source_report_command_window_count"] == 1
    assert source_summary["source_report_command_window_row_count"] == 2
    assert source_summary["source_report_command_window_paths"] == []
  end

  test "command window replay treats preserved feedback and routing maps as pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "command_window_report" => %{
            "contract" => "command_window_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_command_window_report"],
            "command_feedback_count" => 0,
            "input_keys" => ["command_success_rate"],
            "direction_counts" => %{"command" => 1},
            "activity_ids_by_direction" => %{"command" => ["cmd_map_only"]},
            "window_ids_by_direction" => %{"command" => ["window_map_only"]},
            "required_operator_action_counts" => %{"review_command_window" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.command_window_replay_summary(artifact)

    assert summary["command_feedback_count"] == 0
    assert summary["input_keys"] == ["command_success_rate"]
    assert summary["direction_counts"] == %{"command" => 1}
    assert summary["activity_ids_by_direction"] == %{"command" => ["cmd_map_only"]}
    assert summary["window_ids_by_direction"] == %{"command" => ["window_map_only"]}
    assert summary["required_operator_action_counts"] == %{"review_command_window" => 1}
    assert summary["branch_local_command_window_pressure"]
    assert summary["branch_local_command_feedback_pressure"]
    assert summary["branch_local_command_window_action_pressure"]
  end

  test "command window replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "command_window_report" => %{
              "contract" => "command_window_report.v1",
              "count" => 1,
              "row_count" => 2,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_command_window_report"
              ],
              "command_feedback_count" => 1,
              "input_keys" => ["command_success_rate"],
              "direction_counts" => %{"command" => 1},
              "activity_ids_by_direction" => %{"command" => ["cmd_branch_review"]},
              "window_ids_by_direction" => %{"command" => ["window_branch_review"]},
              "direction_routing" => %{
                "command" => %{
                  "activity_count" => 1,
                  "activity_ids" => ["cmd_branch_review"],
                  "window_ids" => ["window_branch_review"]
                }
              },
              "required_operator_action_counts" => %{"review_command_window" => 1},
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_command_window"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.command_window_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.command_window_report"

    assert summary["contract"] == "command_window_report.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 2

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_command_window_report"
           ]

    assert summary["command_feedback_count"] == 1
    assert summary["input_keys"] == ["command_success_rate"]
    assert summary["direction_counts"] == %{"command" => 1}
    assert summary["activity_ids_by_direction"] == %{"command" => ["cmd_branch_review"]}
    assert summary["window_ids_by_direction"] == %{"command" => ["window_branch_review"]}

    assert summary["direction_routing"] == %{
             "command" => %{
               "activity_count" => 1,
               "activity_ids" => ["cmd_branch_review"],
               "window_ids" => ["window_branch_review"]
             }
           }

    assert summary["required_operator_action_counts"] == %{"review_command_window" => 1}
    assert summary["trust_boundaries"] == ["branch_command_window"]
    assert summary["branch_local_command_window_pressure"]
    assert summary["branch_local_command_feedback_pressure"]
    assert summary["branch_local_command_window_action_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "command_window_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_command_window_replay_summary(artifact) ==
             summary
  end

  test "command window replay falls back to provenance when branch summary lacks usable family" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "command_window_report" => %{},
            "maneuver_review_report" => %{
              "contract" => "maneuver_review_report.v1",
              "count" => 1,
              "row_count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_maneuver_review_report"
              ]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "command_window_report" => %{
            "contract" => "command_window_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_command_window_report"],
            "command_feedback_count" => 0,
            "direction_counts" => %{"command" => 1},
            "activity_ids_by_direction" => %{"command" => ["cmd_provenance"]},
            "window_ids_by_direction" => %{"command" => ["window_provenance"]},
            "required_operator_action_counts" => %{"review_command_window" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.command_window_replay_summary(artifact)

    assert summary["source"] == "candidate_refresh.source_report_provenance.command_window_report"
    assert summary["source_report_paths"] == ["source_command_window_report"]
    assert summary["activity_ids_by_direction"] == %{"command" => ["cmd_provenance"]}
    assert summary["window_ids_by_direction"] == %{"command" => ["window_provenance"]}
    assert summary["required_operator_action_counts"] == %{"review_command_window" => 1}
    assert summary["branch_local_command_window_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "command_window_source_report_provenance_only"
  end

  test "command window replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "command_window_report" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_command_window_report"
              ],
              "direction_counts" => %{"command" => 1}
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "command_window_report" => %{
            "contract" => "command_window_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_command_window_report"],
            "command_feedback_count" => 9,
            "direction_counts" => %{"uplink" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.command_window_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.command_window_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_command_window_report"
           ]

    assert summary["command_feedback_count"] == 0
    assert summary["direction_counts"] == %{"command" => 1}
    assert summary["branch_local_command_window_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "command_window_candidate_source_report_summary_only"
  end
end
