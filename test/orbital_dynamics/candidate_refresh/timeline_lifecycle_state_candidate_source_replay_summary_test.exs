defmodule OrbitalDynamics.CandidateRefresh.TimelineLifecycleStateCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "timeline lifecycle state replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_lifecycle_state_summary" => %{
              "contract" => "timeline_lifecycle_state_summary.v1",
              "count" => 1,
              "row_count" => 3,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_lifecycle_state_summary"
              ],
              "source_summary_model_counts" => %{
                "artifact_only_timeline_lifecycle_state_summary" => 1
              },
              "source_summary_schema_contract_counts" => %{
                "timeline_lifecycle_state_summary.v1" => 1
              },
              "planned_activity_count" => 3,
              "realized_activity_count" => 2,
              "recordable_count" => 1,
              "preserved_count" => 1,
              "review_required_count" => 1,
              "duplicate_timeline_identity_count" => 1,
              "invalid_activity_input_count" => 1,
              "invalid_activity_input_ids" => ["timeline_row:5:bad_missing_type"],
              "transition_decision_counts" => %{"record" => 1, "review" => 1},
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
              "recordable_timeline_ids" => ["timeline:cmd_recordable"],
              "preserved_timeline_ids" => ["timeline:obs_done"],
              "review_timeline_ids" => ["timeline:cmd_pending"],
              "review_activity_ids" => ["cmd_pending"],
              "review_timeline_ids_by_required_operator_action" => %{
                "review_activity_approval" => ["timeline:cmd_pending"]
              },
              "review_timeline_ids_by_status_transition_category" => %{
                "execution_recorded" => ["timeline:cmd_recordable"]
              },
              "review_timeline_ids_by_approval_transition_category" => %{
                "approval_granted" => ["timeline:cmd_pending"]
              },
              "review_routing" => %{
                "by_required_operator_action" => %{
                  "review_activity_approval" => ["timeline:cmd_pending"]
                }
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_lifecycle"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.timeline_lifecycle_state_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_lifecycle_state_summary"

    assert summary["contract"] == "timeline_lifecycle_state_summary.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 3

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_lifecycle_state_summary"
           ]

    assert summary["source_summary_model_counts"] == %{
             "artifact_only_timeline_lifecycle_state_summary" => 1
           }

    assert summary["source_summary_schema_contract_counts"] == %{
             "timeline_lifecycle_state_summary.v1" => 1
           }

    assert summary["planned_activity_count"] == 3
    assert summary["realized_activity_count"] == 2
    assert summary["recordable_count"] == 1
    assert summary["preserved_count"] == 1
    assert summary["review_required_count"] == 1
    assert summary["duplicate_timeline_identity_count"] == 1
    assert summary["invalid_activity_input_count"] == 1
    assert summary["invalid_activity_input_ids"] == ["timeline_row:5:bad_missing_type"]
    assert summary["transition_decision_counts"] == %{"record" => 1, "review" => 1}
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

    assert summary["recordable_timeline_ids"] == ["timeline:cmd_recordable"]
    assert summary["preserved_timeline_ids"] == ["timeline:obs_done"]
    assert summary["review_timeline_ids"] == ["timeline:cmd_pending"]
    assert summary["review_activity_ids"] == ["cmd_pending"]

    assert summary["review_timeline_ids_by_required_operator_action"] == %{
             "review_activity_approval" => ["timeline:cmd_pending"]
           }

    assert summary["review_timeline_ids_by_status_transition_category"] == %{
             "execution_recorded" => ["timeline:cmd_recordable"]
           }

    assert summary["review_timeline_ids_by_approval_transition_category"] == %{
             "approval_granted" => ["timeline:cmd_pending"]
           }

    assert summary["review_routing"] == %{
             "by_required_operator_action" => %{
               "review_activity_approval" => ["timeline:cmd_pending"]
             }
           }

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_lifecycle"]
    assert summary["branch_local_timeline_lifecycle_state_pressure"]
    assert summary["branch_local_lifecycle_review_pressure"]
    assert summary["branch_local_lifecycle_recordable_pressure"]
    assert summary["branch_local_lifecycle_preservation_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_lifecycle_state_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_timeline_lifecycle_state_replay_summary(artifact) ==
             summary
  end

  test "timeline lifecycle state replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "timeline_lifecycle_state_summary" => %{
            "contract" => "timeline_lifecycle_state_summary.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_timeline_lifecycle_state_summary"
            ],
            "recordable_timeline_ids" => ["timeline:direct_recordable"]
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_lifecycle_state_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_lifecycle_state_summary"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_lifecycle_state_summary"
           ]

    assert summary["recordable_timeline_ids"] == ["timeline:direct_recordable"]
    assert summary["branch_local_timeline_lifecycle_state_pressure"]
    assert summary["branch_local_lifecycle_recordable_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_lifecycle_state_candidate_source_report_summary_only"
  end

  test "timeline lifecycle state replay falls back to provenance when branch summary lacks usable family" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_lifecycle_state_summary" => %{},
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
          "timeline_lifecycle_state_summary" => %{
            "contract" => "timeline_lifecycle_state_summary.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_timeline_lifecycle_state_summary"],
            "review_timeline_ids" => ["timeline:provenance_review"]
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_lifecycle_state_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.timeline_lifecycle_state_summary"

    assert summary["source_report_paths"] == ["source_timeline_lifecycle_state_summary"]
    assert summary["review_timeline_ids"] == ["timeline:provenance_review"]
    assert summary["branch_local_timeline_lifecycle_state_pressure"]
    assert summary["branch_local_lifecycle_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_lifecycle_state_source_report_provenance_only"
  end

  test "timeline lifecycle state replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_lifecycle_state_summary" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_lifecycle_state_summary"
              ],
              "preserved_timeline_ids" => ["timeline:branch_preserved"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_lifecycle_state_summary" => %{
            "contract" => "timeline_lifecycle_state_summary.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_timeline_lifecycle_state_summary"],
            "review_required_count" => 9,
            "required_operator_action_counts" => %{"review_activity_approval" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_lifecycle_state_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_lifecycle_state_summary"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_lifecycle_state_summary"
           ]

    assert summary["preserved_timeline_ids"] == ["timeline:branch_preserved"]
    assert summary["review_required_count"] == 0
    assert summary["required_operator_action_counts"] == %{}
    assert summary["branch_local_timeline_lifecycle_state_pressure"]
    assert summary["branch_local_lifecycle_preservation_pressure"]
    refute summary["branch_local_lifecycle_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_lifecycle_state_candidate_source_report_summary_only"
  end
end
