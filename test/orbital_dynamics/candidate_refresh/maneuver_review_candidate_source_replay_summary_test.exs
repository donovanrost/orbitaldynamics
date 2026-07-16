defmodule OrbitalDynamics.CandidateRefresh.ManeuverReviewCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "maneuver review replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "maneuver_review_report" => %{
              "contract" => "maneuver_review_report.v1",
              "count" => 1,
              "row_count" => 2,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_maneuver_review_report"
              ],
              "maneuver_success_feedback_count" => 1,
              "execution_uncertainty_declared_count" => 1,
              "execution_uncertainty_missing_count" => 0,
              "input_keys" => [
                "maneuver_execution_uncertainty",
                "maneuver_success_rate"
              ],
              "maneuver_id_counts" => %{"burn_branch_review" => 1},
              "required_operator_action_counts" => %{"review_maneuver_execution" => 1},
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_maneuver_review"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.maneuver_review_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.maneuver_review_report"

    assert summary["contract"] == "maneuver_review_report.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 2

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_maneuver_review_report"
           ]

    assert summary["maneuver_success_feedback_count"] == 1
    assert summary["execution_uncertainty_declared_count"] == 1
    assert summary["execution_uncertainty_missing_count"] == 0

    assert summary["input_keys"] == [
             "maneuver_execution_uncertainty",
             "maneuver_success_rate"
           ]

    assert summary["maneuver_id_counts"] == %{"burn_branch_review" => 1}
    assert summary["required_operator_action_counts"] == %{"review_maneuver_execution" => 1}
    assert summary["trust_boundaries"] == ["branch_maneuver_review"]
    assert summary["branch_local_maneuver_review_pressure"]
    assert summary["branch_local_maneuver_feedback_pressure"]
    assert summary["branch_local_maneuver_routing_pressure"]
    assert summary["branch_local_maneuver_action_pressure"]
    assert summary["branch_local_execution_uncertainty_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "maneuver_review_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_maneuver_review_replay_summary(artifact) ==
             summary
  end

  test "maneuver review replay falls back to provenance when branch summary lacks usable family" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "command_window_report" => %{
              "contract" => "command_window_report.v1",
              "count" => 1,
              "row_count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_command_window_report"
              ]
            },
            "maneuver_review_report" => %{}
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "maneuver_review_report" => %{
            "contract" => "maneuver_review_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_maneuver_review_report"],
            "maneuver_success_feedback_count" => 0,
            "execution_uncertainty_declared_count" => 0,
            "execution_uncertainty_missing_count" => 0,
            "input_keys" => ["maneuver_success_rate"],
            "maneuver_id_counts" => %{"burn_provenance" => 1},
            "required_operator_action_counts" => %{"review_maneuver_execution" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.maneuver_review_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.maneuver_review_report"

    assert summary["source_report_paths"] == ["source_maneuver_review_report"]
    assert summary["input_keys"] == ["maneuver_success_rate"]
    assert summary["maneuver_id_counts"] == %{"burn_provenance" => 1}
    assert summary["required_operator_action_counts"] == %{"review_maneuver_execution" => 1}
    assert summary["branch_local_maneuver_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "maneuver_review_source_report_provenance_only"
  end

  test "maneuver review replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "maneuver_review_report" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_maneuver_review_report"
              ],
              "maneuver_id_counts" => %{"burn_branch_review" => 1}
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "maneuver_review_report" => %{
            "contract" => "maneuver_review_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_maneuver_review_report"],
            "maneuver_success_feedback_count" => 9,
            "execution_uncertainty_declared_count" => 9,
            "execution_uncertainty_missing_count" => 9,
            "input_keys" => ["maneuver_success_rate"],
            "maneuver_id_counts" => %{"burn_provenance" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.maneuver_review_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.maneuver_review_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_maneuver_review_report"
           ]

    assert summary["maneuver_success_feedback_count"] == 0
    assert summary["execution_uncertainty_declared_count"] == 0
    assert summary["execution_uncertainty_missing_count"] == 0
    assert summary["input_keys"] == []
    assert summary["maneuver_id_counts"] == %{"burn_branch_review" => 1}
    assert summary["branch_local_maneuver_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "maneuver_review_candidate_source_report_summary_only"
  end
end
