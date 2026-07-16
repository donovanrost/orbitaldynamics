defmodule OrbitalDynamics.CandidateRefresh.CommandWindowCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

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
