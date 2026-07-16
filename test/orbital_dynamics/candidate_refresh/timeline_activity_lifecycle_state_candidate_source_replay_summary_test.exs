defmodule OrbitalDynamics.CandidateRefresh.TimelineActivityLifecycleStateCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "timeline activity lifecycle state replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_activity_lifecycle_state" => %{
              "contract" => "timeline_activity_lifecycle_state.v1",
              "count" => 1,
              "row_count" => 2,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_activity_lifecycle_state"
              ],
              "source_summary_model_counts" => %{
                "artifact_only_timeline_activity_lifecycle_state" => 1
              },
              "source_summary_schema_contract_counts" => %{
                "timeline_activity_lifecycle_state.v1" => 1
              },
              "review_required_count" => 1,
              "invalid_activity_input_count" => 1,
              "invalid_activity_input_reason_counts" => %{"missing_activity_type" => 1},
              "invalid_activity_input_reasons" => ["missing_activity_type"],
              "transition_decision_counts" => %{"review" => 1},
              "status_transition_decision_counts" => %{"record" => 1},
              "approval_transition_decision_counts" => %{"review" => 1},
              "required_operator_action_counts" => %{"review_activity_approval" => 1},
              "import_action_counts" => %{"review_timeline_diff" => 1},
              "planned_status_category_counts" => %{"planned" => 1},
              "realized_status_category_counts" => %{"executed" => 1},
              "planned_approval_category_counts" => %{"review_required" => 1},
              "realized_approval_category_counts" => %{"protected" => 1},
              "status_transition_category_counts" => %{"execution_recorded" => 1},
              "approval_transition_category_counts" => %{"approval_granted" => 1},
              "transition_application_provenance_count" => 1,
              "transition_application_provenance_helper_counts" => %{
                "apply_lifecycle_event" => 1
              },
              "transition_application_provenance_category_counts" => %{
                "execution_recorded" => 1
              },
              "transition_application_provenance_operator_action_reason_counts" => %{
                "activity_execution_recorded" => 1
              },
              "protection_decision_counts" => %{"preserve" => 1},
              "protection_category_counts" => %{"executed" => 1},
              "activity_id_counts" => %{"cmd_pending" => 1},
              "timeline_id_counts" => %{"timeline:cmd_pending" => 1},
              "review_activity_id_counts" => %{"cmd_pending" => 1},
              "action_routing" => %{
                "review_activity_approval" => %{
                  "activity_ids" => ["cmd_pending"],
                  "approval_transition_categories" => ["approval_granted"],
                  "review_count" => 1,
                  "timeline_ids" => ["timeline:cmd_pending"]
                }
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_activity_lifecycle"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.timeline_activity_lifecycle_state_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_lifecycle_state"

    assert summary["contract"] == "timeline_activity_lifecycle_state.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 2

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_activity_lifecycle_state"
           ]

    assert summary["source_summary_model_counts"] == %{
             "artifact_only_timeline_activity_lifecycle_state" => 1
           }

    assert summary["source_summary_schema_contract_counts"] == %{
             "timeline_activity_lifecycle_state.v1" => 1
           }

    assert summary["review_required_count"] == 1
    assert summary["invalid_activity_input_count"] == 1
    assert summary["invalid_activity_input_reason_counts"] == %{"missing_activity_type" => 1}
    assert summary["invalid_activity_input_reasons"] == ["missing_activity_type"]
    assert summary["transition_decision_counts"] == %{"review" => 1}
    assert summary["status_transition_decision_counts"] == %{"record" => 1}
    assert summary["approval_transition_decision_counts"] == %{"review" => 1}
    assert summary["required_operator_action_counts"] == %{"review_activity_approval" => 1}
    assert summary["import_action_counts"] == %{"review_timeline_diff" => 1}
    assert summary["planned_status_category_counts"] == %{"planned" => 1}
    assert summary["realized_status_category_counts"] == %{"executed" => 1}
    assert summary["planned_approval_category_counts"] == %{"review_required" => 1}
    assert summary["realized_approval_category_counts"] == %{"protected" => 1}
    assert summary["status_transition_category_counts"] == %{"execution_recorded" => 1}
    assert summary["approval_transition_category_counts"] == %{"approval_granted" => 1}
    assert summary["transition_application_provenance_count"] == 1

    assert summary["transition_application_provenance_helper_counts"] == %{
             "apply_lifecycle_event" => 1
           }

    assert summary["transition_application_provenance_category_counts"] == %{
             "execution_recorded" => 1
           }

    assert summary["transition_application_provenance_operator_action_reason_counts"] == %{
             "activity_execution_recorded" => 1
           }

    assert summary["protection_decision_counts"] == %{"preserve" => 1}
    assert summary["protection_category_counts"] == %{"executed" => 1}
    assert summary["activity_id_counts"] == %{"cmd_pending" => 1}
    assert summary["timeline_id_counts"] == %{"timeline:cmd_pending" => 1}
    assert summary["review_activity_id_counts"] == %{"cmd_pending" => 1}

    assert summary["action_routing"] == %{
             "review_activity_approval" => %{
               "activity_ids" => ["cmd_pending"],
               "approval_transition_categories" => ["approval_granted"],
               "review_count" => 1,
               "timeline_ids" => ["timeline:cmd_pending"]
             }
           }

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_activity_lifecycle"]
    assert summary["branch_local_timeline_activity_lifecycle_state_pressure"]
    assert summary["branch_local_activity_lifecycle_review_pressure"]
    assert summary["branch_local_activity_lifecycle_action_pressure"]
    assert summary["branch_local_activity_lifecycle_routing_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_activity_lifecycle_state_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_timeline_activity_lifecycle_state_replay_summary(
             artifact
           ) == summary
  end

  test "timeline activity lifecycle state replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "timeline_activity_lifecycle_state" => %{
            "contract" => "timeline_activity_lifecycle_state.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_timeline_activity_lifecycle_state"
            ],
            "activity_id_counts" => %{"direct_cmd" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_activity_lifecycle_state_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_lifecycle_state"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_activity_lifecycle_state"
           ]

    assert summary["activity_id_counts"] == %{"direct_cmd" => 1}
    assert summary["branch_local_timeline_activity_lifecycle_state_pressure"]
    assert summary["branch_local_activity_lifecycle_routing_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_activity_lifecycle_state_candidate_source_report_summary_only"
  end

  test "timeline activity lifecycle state replay falls back to provenance when branch summary lacks usable family" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_activity_lifecycle_state" => %{},
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
          "timeline_activity_lifecycle_state" => %{
            "contract" => "timeline_activity_lifecycle_state.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_timeline_activity_lifecycle_state"],
            "review_activity_id_counts" => %{"provenance_cmd" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_activity_lifecycle_state_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.timeline_activity_lifecycle_state"

    assert summary["source_report_paths"] == ["source_timeline_activity_lifecycle_state"]
    assert summary["review_activity_id_counts"] == %{"provenance_cmd" => 1}
    assert summary["branch_local_timeline_activity_lifecycle_state_pressure"]
    assert summary["branch_local_activity_lifecycle_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_activity_lifecycle_state_source_report_provenance_only"
  end

  test "timeline activity lifecycle state replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_activity_lifecycle_state" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_activity_lifecycle_state"
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
          "timeline_activity_lifecycle_state" => %{
            "contract" => "timeline_activity_lifecycle_state.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_timeline_activity_lifecycle_state"],
            "review_required_count" => 9,
            "required_operator_action_counts" => %{"review_activity_approval" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_activity_lifecycle_state_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_lifecycle_state"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_activity_lifecycle_state"
           ]

    assert summary["action_routing"] == %{
             "record_timeline_change" => %{"activity_ids" => ["branch_cmd"]}
           }

    assert summary["review_required_count"] == 0
    assert summary["required_operator_action_counts"] == %{}
    assert summary["branch_local_timeline_activity_lifecycle_state_pressure"]
    assert summary["branch_local_activity_lifecycle_action_pressure"]
    assert summary["branch_local_activity_lifecycle_routing_pressure"]
    refute summary["branch_local_activity_lifecycle_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_activity_lifecycle_state_candidate_source_report_summary_only"
  end
end
