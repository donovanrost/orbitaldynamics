defmodule OrbitalDynamics.CandidateRefresh.TimelineActivityStatusApprovalStateReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "timeline activity status and approval state replay read branch candidate-source summary metadata" do
    status_artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_activity_state" => %{
              "contract" => "timeline_activity_status_state.v1",
              "count" => 1,
              "row_count" => 2,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_activity_status_state"
              ],
              "source_summary_model_counts" => %{
                "artifact_only_timeline_activity_status_state" => 1
              },
              "source_summary_schema_contract_counts" => %{
                "timeline_activity_status_state.v1" => 1
              },
              "transition_decision_counts" => %{"record" => 1},
              "required_operator_action_counts" => %{"record_timeline_change" => 1},
              "import_action_counts" => %{"import_replacement_activity" => 1},
              "planned_status_category_counts" => %{"planned" => 1},
              "realized_status_category_counts" => %{"executed" => 1},
              "status_transition_category_counts" => %{"execution_recorded" => 1},
              "activity_id_counts" => %{"branch_status_cmd" => 1},
              "timeline_id_counts" => %{"timeline:branch_status_cmd" => 1},
              "action_routing" => %{
                "record_timeline_change" => %{
                  "activity_ids" => ["branch_status_cmd"],
                  "timeline_ids" => ["timeline:branch_status_cmd"]
                }
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_status_state"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    approval_artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_activity_state" => %{
              "contract" => "timeline_activity_approval_state.v1",
              "count" => 1,
              "row_count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_activity_approval_state"
              ],
              "source_summary_model_counts" => %{
                "artifact_only_timeline_activity_approval_state" => 1
              },
              "source_summary_schema_contract_counts" => %{
                "timeline_activity_approval_state.v1" => 1
              },
              "review_required_count" => 1,
              "transition_decision_counts" => %{"review" => 1},
              "required_operator_action_counts" => %{"review_activity_approval" => 1},
              "import_action_counts" => %{"review_timeline_diff" => 1},
              "planned_approval_category_counts" => %{"review_required" => 1},
              "realized_approval_category_counts" => %{"protected" => 1},
              "approval_transition_category_counts" => %{"approval_granted" => 1},
              "activity_id_counts" => %{"branch_approval_cmd" => 1},
              "timeline_id_counts" => %{"timeline:branch_approval_cmd" => 1},
              "review_activity_id_counts" => %{"branch_approval_cmd" => 1},
              "action_routing" => %{
                "review_activity_approval" => %{
                  "activity_ids" => ["branch_approval_cmd"],
                  "timeline_ids" => ["timeline:branch_approval_cmd"]
                }
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_approval_state"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    status_summary =
      CandidateRefresh.timeline_activity_status_state_replay_summary(status_artifact)

    assert status_summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_status_state"

    assert status_summary["contract"] == "timeline_activity_status_state.v1"
    assert status_summary["source_report_count"] == 1
    assert status_summary["source_report_row_count"] == 2

    assert status_summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_activity_status_state"
           ]

    assert status_summary["source_summary_model_counts"] == %{
             "artifact_only_timeline_activity_status_state" => 1
           }

    assert status_summary["source_summary_schema_contract_counts"] == %{
             "timeline_activity_status_state.v1" => 1
           }

    assert status_summary["transition_decision_counts"] == %{"record" => 1}
    assert status_summary["required_operator_action_counts"] == %{"record_timeline_change" => 1}
    assert status_summary["import_action_counts"] == %{"import_replacement_activity" => 1}
    assert status_summary["planned_status_category_counts"] == %{"planned" => 1}
    assert status_summary["realized_status_category_counts"] == %{"executed" => 1}
    assert status_summary["status_transition_category_counts"] == %{"execution_recorded" => 1}
    assert status_summary["activity_id_counts"] == %{"branch_status_cmd" => 1}
    assert status_summary["timeline_id_counts"] == %{"timeline:branch_status_cmd" => 1}

    assert status_summary["action_routing"] == %{
             "record_timeline_change" => %{
               "activity_ids" => ["branch_status_cmd"],
               "timeline_ids" => ["timeline:branch_status_cmd"]
             }
           }

    assert status_summary["trust_boundary_status"] == "declared"
    assert status_summary["trust_boundaries"] == ["branch_status_state"]
    assert status_summary["branch_local_timeline_activity_status_state_pressure"]
    assert status_summary["branch_local_timeline_activity_status_state_action_pressure"]
    assert status_summary["branch_local_timeline_activity_status_state_routing_pressure"]

    assert status_summary["assumptions"]["replay_scope"] ==
             "timeline_activity_status_state_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_timeline_activity_status_state_replay_summary(
             status_artifact
           ) == status_summary

    approval_summary =
      CandidateRefresh.timeline_activity_approval_state_replay_summary(approval_artifact)

    assert approval_summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_approval_state"

    assert approval_summary["contract"] == "timeline_activity_approval_state.v1"
    assert approval_summary["source_report_count"] == 1
    assert approval_summary["source_report_row_count"] == 1

    assert approval_summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_activity_approval_state"
           ]

    assert approval_summary["source_summary_model_counts"] == %{
             "artifact_only_timeline_activity_approval_state" => 1
           }

    assert approval_summary["source_summary_schema_contract_counts"] == %{
             "timeline_activity_approval_state.v1" => 1
           }

    assert approval_summary["review_required_count"] == 1
    assert approval_summary["transition_decision_counts"] == %{"review" => 1}

    assert approval_summary["required_operator_action_counts"] == %{
             "review_activity_approval" => 1
           }

    assert approval_summary["import_action_counts"] == %{"review_timeline_diff" => 1}
    assert approval_summary["planned_approval_category_counts"] == %{"review_required" => 1}
    assert approval_summary["realized_approval_category_counts"] == %{"protected" => 1}
    assert approval_summary["approval_transition_category_counts"] == %{"approval_granted" => 1}
    assert approval_summary["activity_id_counts"] == %{"branch_approval_cmd" => 1}
    assert approval_summary["timeline_id_counts"] == %{"timeline:branch_approval_cmd" => 1}
    assert approval_summary["review_activity_id_counts"] == %{"branch_approval_cmd" => 1}

    assert approval_summary["action_routing"] == %{
             "review_activity_approval" => %{
               "activity_ids" => ["branch_approval_cmd"],
               "timeline_ids" => ["timeline:branch_approval_cmd"]
             }
           }

    assert approval_summary["trust_boundary_status"] == "declared"
    assert approval_summary["trust_boundaries"] == ["branch_approval_state"]
    assert approval_summary["branch_local_timeline_activity_approval_state_pressure"]
    assert approval_summary["branch_local_timeline_activity_approval_state_review_pressure"]
    assert approval_summary["branch_local_timeline_activity_approval_state_action_pressure"]
    assert approval_summary["branch_local_timeline_activity_approval_state_routing_pressure"]

    assert approval_summary["assumptions"]["replay_scope"] ==
             "timeline_activity_approval_state_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_timeline_activity_approval_state_replay_summary(
             approval_artifact
           ) == approval_summary
  end

  test "timeline activity status and approval state replay label direct candidate-source summary metadata" do
    status_candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "timeline_activity_state" => %{
            "contract" => "timeline_activity_status_state.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_timeline_activity_status_state"
            ],
            "source_summary_schema_contract_counts" => %{
              "timeline_activity_status_state.v1" => 1
            },
            "activity_id_counts" => %{"direct_status_cmd" => 1}
          }
        }
      }
    }

    approval_candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "timeline_activity_state" => %{
            "contract" => "timeline_activity_approval_state.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_timeline_activity_approval_state"
            ],
            "source_summary_schema_contract_counts" => %{
              "timeline_activity_approval_state.v1" => 1
            },
            "review_activity_id_counts" => %{"direct_approval_cmd" => 1}
          }
        }
      }
    }

    status_summary =
      CandidateRefresh.timeline_activity_status_state_replay_summary(status_candidate_source)

    assert status_summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_status_state"

    assert status_summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_activity_status_state"
           ]

    assert status_summary["activity_id_counts"] == %{"direct_status_cmd" => 1}
    assert status_summary["branch_local_timeline_activity_status_state_pressure"]
    assert status_summary["branch_local_timeline_activity_status_state_routing_pressure"]

    assert status_summary["assumptions"]["replay_scope"] ==
             "timeline_activity_status_state_candidate_source_report_summary_only"

    approval_summary =
      CandidateRefresh.timeline_activity_approval_state_replay_summary(approval_candidate_source)

    assert approval_summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_approval_state"

    assert approval_summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_activity_approval_state"
           ]

    assert approval_summary["review_activity_id_counts"] == %{"direct_approval_cmd" => 1}
    assert approval_summary["branch_local_timeline_activity_approval_state_pressure"]
    assert approval_summary["branch_local_timeline_activity_approval_state_review_pressure"]
    assert approval_summary["branch_local_timeline_activity_approval_state_routing_pressure"]

    assert approval_summary["assumptions"]["replay_scope"] ==
             "timeline_activity_approval_state_candidate_source_report_summary_only"
  end

  test "timeline activity status state replay falls back when branch summary lacks matching contract" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_activity_state" => %{
              "contract" => "timeline_activity_approval_state.v1",
              "count" => 1,
              "source_summary_schema_contract_counts" => %{
                "timeline_activity_approval_state.v1" => 1
              },
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_activity_approval_state"
              ]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_activity_state" => %{
            "contract" => "timeline_activity_status_state.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_timeline_activity_status_state"],
            "source_summary_schema_contract_counts" => %{
              "timeline_activity_status_state.v1" => 1
            },
            "activity_id_counts" => %{"provenance_status_cmd" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_activity_status_state_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.timeline_activity_status_state"

    assert summary["source_report_paths"] == ["source_timeline_activity_status_state"]
    assert summary["activity_id_counts"] == %{"provenance_status_cmd" => 1}
    assert summary["branch_local_timeline_activity_status_state_pressure"]
    assert summary["branch_local_timeline_activity_status_state_routing_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_activity_status_state_source_report_provenance_only"
  end

  test "timeline activity approval state replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_activity_state" => %{
              "contract" => "timeline_activity_approval_state.v1",
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_activity_approval_state"
              ],
              "source_summary_schema_contract_counts" => %{
                "timeline_activity_approval_state.v1" => 1
              },
              "action_routing" => %{
                "review_activity_approval" => %{"activity_ids" => ["branch_approval_cmd"]}
              }
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_activity_state" => %{
            "contract" => "timeline_activity_approval_state.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_timeline_activity_approval_state"],
            "source_summary_schema_contract_counts" => %{
              "timeline_activity_approval_state.v1" => 9
            },
            "review_required_count" => 9,
            "required_operator_action_counts" => %{"review_activity_approval" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_activity_approval_state_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_approval_state"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_activity_approval_state"
           ]

    assert summary["action_routing"] == %{
             "review_activity_approval" => %{"activity_ids" => ["branch_approval_cmd"]}
           }

    assert summary["review_required_count"] == 0
    assert summary["required_operator_action_counts"] == %{}
    assert summary["branch_local_timeline_activity_approval_state_pressure"]
    assert summary["branch_local_timeline_activity_approval_state_action_pressure"]
    assert summary["branch_local_timeline_activity_approval_state_routing_pressure"]
    refute summary["branch_local_timeline_activity_approval_state_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_activity_approval_state_candidate_source_report_summary_only"
  end
end
