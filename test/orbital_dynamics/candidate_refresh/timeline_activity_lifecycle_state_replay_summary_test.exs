defmodule OrbitalDynamics.CandidateRefresh.TimelineActivityLifecycleStateReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, CandidateRefresh, OperatorReview, Schema, Timeline}

  test "operator review and import lift timeline activity lifecycle states from candidate refresh artifacts" do
    lifecycle_state = fn prefix ->
      planned = %{
        id: "#{prefix}_cmd_pending",
        type: :command,
        status: :planned,
        approval_status: :pending,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: "timeline:#{prefix}:cmd_pending"}
      }

      realized = %{
        id: "#{prefix}_cmd_pending",
        type: :command,
        status: :executed,
        approval_status: :approved,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: "timeline:#{prefix}:cmd_pending"}
      }

      Timeline.activity_lifecycle_state(planned, realized)
    end

    direct_transition_application_provenance = %{
      "field" => "status",
      "from" => "planned",
      "helper" => "apply_lifecycle_event",
      "operator_action_reason" => "activity_execution_recorded",
      "requires_operator_review" => false,
      "to" => "completed",
      "transition_category" => "execution_recorded",
      "transition_type" => "changed"
    }

    direct_state =
      lifecycle_state.("direct_activity_lifecycle")
      |> Map.put("transition_application_provenance", direct_transition_application_provenance)
      |> Map.put("activity_context", %{
        "transition_application_provenance" => direct_transition_application_provenance
      })
      |> put_in(
        ["realized_activity_context", "transition_application_provenance"],
        direct_transition_application_provenance
      )

    canonical_state = lifecycle_state.("canonical_activity_lifecycle")
    wrapped_state = lifecycle_state.("wrapped_activity_lifecycle")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:timeline_activity_lifecycle_handoff",
      "source_timeline_activity_lifecycle_state" => [direct_state],
      "timeline_activity_lifecycle_state" => canonical_state,
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "timeline_activity_lifecycle_state" => wrapped_state
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)
    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.timeline_activity_lifecycle_state_replay_summary(artifact)

    expected_source_paths = [
      "source_timeline_activity_lifecycle_state[0]",
      "timeline_activity_lifecycle_state",
      "source_result_artifact.timeline_activity_lifecycle_state"
    ]

    expected_action_routing = %{
      "record_timeline_change" => %{
        "activity_ids" => [
          "canonical_activity_lifecycle_cmd_pending",
          "direct_activity_lifecycle_cmd_pending",
          "wrapped_activity_lifecycle_cmd_pending"
        ],
        "approval_transition_categories" => ["approval_granted"],
        "protection_categories" => ["executed", "none"],
        "review_count" => 3,
        "status_transition_categories" => ["execution_recorded"],
        "timeline_ids" => [
          "timeline:canonical_activity_lifecycle:cmd_pending",
          "timeline:direct_activity_lifecycle:cmd_pending",
          "timeline:wrapped_activity_lifecycle:cmd_pending"
        ]
      },
      "review_activity_approval" => %{
        "activity_ids" => [
          "canonical_activity_lifecycle_cmd_pending",
          "direct_activity_lifecycle_cmd_pending",
          "wrapped_activity_lifecycle_cmd_pending"
        ],
        "approval_transition_categories" => ["approval_granted"],
        "protection_categories" => ["executed", "none"],
        "review_count" => 3,
        "status_transition_categories" => ["execution_recorded"],
        "timeline_ids" => [
          "timeline:canonical_activity_lifecycle:cmd_pending",
          "timeline:direct_activity_lifecycle:cmd_pending",
          "timeline:wrapped_activity_lifecycle:cmd_pending"
        ]
      }
    }

    assert %{
             "contract" => "timeline_activity_lifecycle_state.v1",
             "count" => 3,
             "row_count" => 3,
             "review_required_count" => 3,
             "paths" => ^expected_source_paths,
             "source_summary_schema_contract_counts" => %{
               "timeline_activity_lifecycle_state.v1" => 3
             },
             "source_summary_model_counts" => %{
               "artifact_only_timeline_activity_lifecycle_state" => 3
             },
             "transition_decision_counts" => %{"review" => 3},
             "status_transition_decision_counts" => %{"record" => 3},
             "approval_transition_decision_counts" => %{"review" => 3},
             "required_operator_action_counts" => %{
               "record_timeline_change" => 3,
               "review_activity_approval" => 3
             },
             "import_action_counts" => %{"review_timeline_diff" => 3},
             "planned_status_category_counts" => %{"planned" => 3},
             "realized_status_category_counts" => %{"executed" => 3},
             "planned_approval_category_counts" => %{"review_required" => 3},
             "realized_approval_category_counts" => %{"protected" => 3},
             "status_transition_category_counts" => %{"execution_recorded" => 3},
             "approval_transition_category_counts" => %{"approval_granted" => 3},
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
             "protection_decision_counts" => %{"mutable" => 3, "preserve" => 3},
             "protection_category_counts" => %{"executed" => 3, "none" => 3},
             "activity_id_counts" => %{
               "canonical_activity_lifecycle_cmd_pending" => 3,
               "direct_activity_lifecycle_cmd_pending" => 3,
               "wrapped_activity_lifecycle_cmd_pending" => 3
             },
             "timeline_id_counts" => %{
               "timeline:canonical_activity_lifecycle:cmd_pending" => 3,
               "timeline:direct_activity_lifecycle:cmd_pending" => 3,
               "timeline:wrapped_activity_lifecycle:cmd_pending" => 3
             },
             "review_activity_id_counts" => %{
               "canonical_activity_lifecycle_cmd_pending" => 3,
               "direct_activity_lifecycle_cmd_pending" => 3,
               "wrapped_activity_lifecycle_cmd_pending" => 3
             },
             "action_routing" => ^expected_action_routing,
             "trust_boundary_status" => "missing",
             "trust_boundaries" => []
           } = source_summary["source_reports"]["timeline_activity_lifecycle_state"]

    assert %{
             "model" =>
               "artifact_only_candidate_refresh_timeline_activity_lifecycle_state_replay_summary",
             "source" =>
               "candidate_refresh.source_report_provenance.timeline_activity_lifecycle_state",
             "contract" => "timeline_activity_lifecycle_state.v1",
             "source_report_count" => 3,
             "source_report_row_count" => 3,
             "source_report_paths" => ^expected_source_paths,
             "action_routing" => ^expected_action_routing,
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
             "branch_local_timeline_activity_lifecycle_state_pressure" => true,
             "branch_local_activity_lifecycle_review_pressure" => true,
             "branch_local_activity_lifecycle_action_pressure" => true,
             "branch_local_activity_lifecycle_routing_pressure" => true,
             "assumptions" => %{
               "activity_lifecycle_application" => "not_performed_by_summary",
               "import_approval" =>
                 "not_granted_by_timeline_activity_lifecycle_state_replay_summary",
               "timeline_mutation" => "not_performed_by_summary"
             }
           } = replay_summary

    assert replay_summary ==
             OrbitalDynamics.candidate_refresh_timeline_activity_lifecycle_state_replay_summary(
               artifact
             )

    assert %{
             "source_report_timeline_activity_lifecycle_state_contract" =>
               "timeline_activity_lifecycle_state.v1",
             "source_report_timeline_activity_lifecycle_state_count" => 3,
             "source_report_timeline_activity_lifecycle_state_row_count" => 3,
             "source_report_timeline_activity_lifecycle_state_paths" => ^expected_source_paths,
             "source_report_timeline_activity_lifecycle_state_review_required_count" => 3,
             "source_report_timeline_activity_lifecycle_state_transition_application_provenance_count" =>
               1,
             "source_report_timeline_activity_lifecycle_state_transition_application_provenance_helper_counts" =>
               %{"apply_lifecycle_event" => 1},
             "source_report_timeline_activity_lifecycle_state_transition_application_provenance_category_counts" =>
               %{"execution_recorded" => 1},
             "source_report_timeline_activity_lifecycle_state_transition_application_provenance_operator_action_reason_counts" =>
               %{"activity_execution_recorded" => 1},
             "source_report_timeline_activity_lifecycle_state_action_routing" =>
               ^expected_action_routing,
             "source_report_timeline_activity_lifecycle_state_branch_local_timeline_activity_lifecycle_state_pressure" =>
               true,
             "source_report_timeline_activity_lifecycle_state_branch_local_review_pressure" =>
               true,
             "source_report_timeline_activity_lifecycle_state_branch_local_action_pressure" =>
               true,
             "source_report_timeline_activity_lifecycle_state_branch_local_routing_pressure" =>
               true
           } = source_summary

    provenance_artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert %{
             "source_report_timeline_activity_lifecycle_state_branch_local_timeline_activity_lifecycle_state_pressure" =>
               true,
             "source_report_timeline_activity_lifecycle_state_branch_local_review_pressure" =>
               true,
             "source_report_timeline_activity_lifecycle_state_branch_local_action_pressure" =>
               true,
             "source_report_timeline_activity_lifecycle_state_branch_local_routing_pressure" =>
               true
           } = CandidateRefresh.source_report_summary(provenance_artifact)

    assert CandidateRefresh.timeline_activity_lifecycle_state_replay_summary(provenance_artifact) ==
             replay_summary

    lifecycle_rows =
      Enum.filter(review["rows"], &(&1["review_type"] == "timeline_lifecycle_state_review"))

    assert length(lifecycle_rows) == 3

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "timeline_lifecycle_state_review_count" => 3,
             "review_type_counts" => %{"timeline_lifecycle_state_review" => 3}
           } = review

    assert Enum.sort(Enum.map(lifecycle_rows, & &1["source"]) |> Enum.uniq()) == [
             "candidate_refresh.source_result_artifact.timeline_activity_lifecycle_state.state",
             "candidate_refresh.source_timeline_activity_lifecycle_state[0].state",
             "candidate_refresh.timeline_activity_lifecycle_state.state"
           ]

    assert Enum.any?(
             lifecycle_rows,
             &match?(
               %{
                 "timeline_id" => "timeline:direct_activity_lifecycle:cmd_pending",
                 "required_operator_action" => "review_activity_approval",
                 "status_transition" => %{"transition_category" => "execution_recorded"},
                 "approval_transition" => %{"transition_category" => "approval_granted"},
                 "source_timeline_lifecycle_state" => %{
                   "schema_contract" => "timeline_activity_lifecycle_state.v1"
                 }
               },
               &1
             )
           )

    import_rows =
      Enum.filter(
        import["rows"],
        &(&1["source_review_type"] == "timeline_lifecycle_state_review")
      )

    assert length(import_rows) == 3

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "import_action_counts" => %{"review_timeline_lifecycle_state" => 3},
             "source_review_type_counts" => %{"timeline_lifecycle_state_review" => 3}
           } = import

    assert Enum.all?(
             import_rows,
             &(&1["import_action"] == "review_timeline_lifecycle_state" and
                 &1["source_review_row"]["source_timeline_lifecycle_state"])
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "timeline activity lifecycle state replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.timeline_activity_lifecycle_state_replay_summary(artifact)

    refute Map.has_key?(
             source_summary,
             "source_report_timeline_activity_lifecycle_state_contract"
           )

    refute Map.has_key?(source_summary, "source_report_timeline_activity_lifecycle_state_count")

    refute Map.has_key?(
             source_summary,
             "source_report_timeline_activity_lifecycle_state_row_count"
           )

    refute Map.has_key?(source_summary, "source_report_timeline_activity_lifecycle_state_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    assert summary["transition_application_provenance_count"] == 0
    assert summary["transition_application_provenance_helper_counts"] == %{}
    assert summary["transition_application_provenance_category_counts"] == %{}

    assert summary["transition_application_provenance_operator_action_reason_counts"] == %{}
    refute summary["branch_local_timeline_activity_lifecycle_state_pressure"]
  end

  test "timeline activity lifecycle state source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "timeline_activity_lifecycle_state.v1"},
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.timeline_activity_lifecycle_state"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.timeline_activity_lifecycle_state"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "timeline_activity_lifecycle_state" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_timeline_activity_lifecycle_state_contract"] ==
                 "timeline_activity_lifecycle_state.v1"
      else
        refute Map.has_key?(
                 source_summary,
                 "source_report_timeline_activity_lifecycle_state_contract"
               )
      end

      refute Map.has_key?(
               source_summary,
               "source_report_timeline_activity_lifecycle_state_count"
             )

      refute Map.has_key?(
               source_summary,
               "source_report_timeline_activity_lifecycle_state_row_count"
             )

      refute Map.has_key?(
               source_summary,
               "source_report_timeline_activity_lifecycle_state_paths"
             )
    end
  end

  test "timeline activity lifecycle state source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_activity_lifecycle_state" => %{
            "contract" => "timeline_activity_lifecycle_state.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.timeline_activity_lifecycle_state"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_activity_lifecycle_state_contract"] ==
             "timeline_activity_lifecycle_state.v1"

    assert source_summary["source_report_timeline_activity_lifecycle_state_count"] == 0
    assert source_summary["source_report_timeline_activity_lifecycle_state_row_count"] == 0

    assert source_summary["source_report_timeline_activity_lifecycle_state_paths"] == [
             "provenance.source_reports.timeline_activity_lifecycle_state"
           ]
  end

  test "timeline activity lifecycle state source summary omits missing identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_activity_lifecycle_state" => %{
            "contract" => "timeline_activity_lifecycle_state.v1",
            "count" => 1,
            "row_count" => 2
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_activity_lifecycle_state_contract"] ==
             "timeline_activity_lifecycle_state.v1"

    assert source_summary["source_report_timeline_activity_lifecycle_state_count"] == 1
    assert source_summary["source_report_timeline_activity_lifecycle_state_row_count"] == 2

    refute Map.has_key?(
             source_summary,
             "source_report_timeline_activity_lifecycle_state_paths"
           )
  end

  test "timeline activity lifecycle state source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_activity_lifecycle_state" => %{
            "contract" => "timeline_activity_lifecycle_state.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_activity_lifecycle_state_contract"] ==
             "timeline_activity_lifecycle_state.v1"

    assert source_summary["source_report_timeline_activity_lifecycle_state_count"] == 1
    assert source_summary["source_report_timeline_activity_lifecycle_state_row_count"] == 2
    assert source_summary["source_report_timeline_activity_lifecycle_state_paths"] == []
  end

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
