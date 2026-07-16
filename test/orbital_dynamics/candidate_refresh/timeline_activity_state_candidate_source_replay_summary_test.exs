defmodule OrbitalDynamics.CandidateRefresh.TimelineActivityStateCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "timeline activity state replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_activity_state" => %{
              "contract" => "timeline_activity_state.v1",
              "count" => 1,
              "row_count" => 3,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_activity_state"
              ],
              "source_summary_model_counts" => %{
                "artifact_only_timeline_activity_state" => 1
              },
              "source_summary_schema_contract_counts" => %{
                "timeline_activity_state.v1" => 1
              },
              "review_required_count" => 1,
              "state_status_counts" => %{"changed" => 1},
              "transition_decision_counts" => %{"review" => 1},
              "required_operator_action_counts" => %{"review_activity_approval" => 1},
              "import_action_counts" => %{"review_timeline_diff" => 1},
              "activity_id_counts" => %{"cmd_pending" => 1},
              "timeline_id_counts" => %{"timeline:cmd_pending" => 1},
              "review_activity_id_counts" => %{"cmd_pending" => 1},
              "action_routing" => %{
                "review_activity_approval" => %{
                  "activity_ids" => ["cmd_pending"],
                  "review_count" => 1,
                  "timeline_ids" => ["timeline:cmd_pending"]
                }
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_activity_state"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.timeline_activity_state_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_state"

    assert summary["contract"] == "timeline_activity_state.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 3

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_activity_state"
           ]

    assert summary["source_summary_model_counts"] == %{
             "artifact_only_timeline_activity_state" => 1
           }

    assert summary["source_summary_schema_contract_counts"] == %{
             "timeline_activity_state.v1" => 1
           }

    assert summary["review_required_count"] == 1
    assert summary["state_status_counts"] == %{"changed" => 1}
    assert summary["transition_decision_counts"] == %{"review" => 1}
    assert summary["required_operator_action_counts"] == %{"review_activity_approval" => 1}
    assert summary["import_action_counts"] == %{"review_timeline_diff" => 1}
    assert summary["activity_id_counts"] == %{"cmd_pending" => 1}
    assert summary["timeline_id_counts"] == %{"timeline:cmd_pending" => 1}
    assert summary["review_activity_id_counts"] == %{"cmd_pending" => 1}

    assert summary["action_routing"] == %{
             "review_activity_approval" => %{
               "activity_ids" => ["cmd_pending"],
               "review_count" => 1,
               "timeline_ids" => ["timeline:cmd_pending"]
             }
           }

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_activity_state"]
    assert summary["branch_local_timeline_activity_state_pressure"]
    assert summary["branch_local_activity_state_review_pressure"]
    assert summary["branch_local_activity_state_action_pressure"]
    assert summary["branch_local_activity_state_routing_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_activity_state_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_timeline_activity_state_replay_summary(artifact) ==
             summary
  end

  test "timeline activity state replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "timeline_activity_state" => %{
            "contract" => "timeline_activity_state.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_timeline_activity_state"
            ],
            "activity_id_counts" => %{"direct_cmd" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_activity_state_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_state"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_activity_state"
           ]

    assert summary["activity_id_counts"] == %{"direct_cmd" => 1}
    assert summary["branch_local_timeline_activity_state_pressure"]
    assert summary["branch_local_activity_state_routing_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_activity_state_candidate_source_report_summary_only"
  end

  test "timeline activity state replay falls back to provenance when branch summary lacks usable family" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_activity_state" => %{},
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
          "timeline_activity_state" => %{
            "contract" => "timeline_activity_state.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_timeline_activity_state"],
            "review_activity_id_counts" => %{"provenance_cmd" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_activity_state_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.timeline_activity_state"

    assert summary["source_report_paths"] == ["source_timeline_activity_state"]
    assert summary["review_activity_id_counts"] == %{"provenance_cmd" => 1}
    assert summary["branch_local_timeline_activity_state_pressure"]
    assert summary["branch_local_activity_state_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_activity_state_source_report_provenance_only"
  end

  test "timeline activity state replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_activity_state" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_activity_state"
              ],
              "action_routing" => %{
                "record_timeline_change" => %{"activity_ids" => ["branch_cmd"]}
              }
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_activity_state" => %{
            "contract" => "timeline_activity_state.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_timeline_activity_state"],
            "review_required_count" => 9,
            "required_operator_action_counts" => %{"review_activity_approval" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_activity_state_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_state"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_activity_state"
           ]

    assert summary["action_routing"] == %{
             "record_timeline_change" => %{"activity_ids" => ["branch_cmd"]}
           }

    assert summary["review_required_count"] == 0
    assert summary["required_operator_action_counts"] == %{}
    assert summary["branch_local_timeline_activity_state_pressure"]
    assert summary["branch_local_activity_state_action_pressure"]
    assert summary["branch_local_activity_state_routing_pressure"]
    refute summary["branch_local_activity_state_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_activity_state_candidate_source_report_summary_only"
  end
end
