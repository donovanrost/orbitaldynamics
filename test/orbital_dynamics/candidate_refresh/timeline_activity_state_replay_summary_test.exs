defmodule OrbitalDynamics.CandidateRefresh.TimelineActivityStateReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, CandidateRefresh, OperatorReview, Schema, Timeline}

  test "operator review and import lift timeline activity state artifacts from candidate refresh artifacts" do
    state_pair = fn prefix ->
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

      {planned, realized}
    end

    activity_state = fn prefix ->
      {planned, realized} = state_pair.(prefix)
      OrbitalDynamics.timeline_activity_state(planned, realized)
    end

    status_state = fn prefix ->
      {planned, realized} = state_pair.(prefix)
      Timeline.activity_status_state(planned, realized)
    end

    approval_state = fn prefix ->
      {planned, realized} = state_pair.(prefix)
      Timeline.activity_approval_state(planned, realized)
    end

    direct_activity_state = activity_state.("direct_activity_state")
    canonical_activity_state = activity_state.("canonical_activity_state")
    wrapped_activity_state = activity_state.("wrapped_activity_state")
    direct_status_state = status_state.("direct_status_state")
    canonical_status_state = status_state.("canonical_status_state")
    wrapped_status_state = status_state.("wrapped_status_state")
    direct_approval_state = approval_state.("direct_approval_state")
    canonical_approval_state = approval_state.("canonical_approval_state")
    wrapped_approval_state = approval_state.("wrapped_approval_state")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:timeline_activity_state_handoff",
      "source_timeline_activity_state" => [direct_activity_state],
      "timeline_activity_state" => canonical_activity_state,
      "source_timeline_activity_status_state" => [direct_status_state],
      "timeline_activity_status_state" => canonical_status_state,
      "source_timeline_activity_approval_state" => [direct_approval_state],
      "timeline_activity_approval_state" => canonical_approval_state,
      "source_result_artifact" => [
        wrapped_activity_state,
        %{
          "schema_contract" => "result_artifact.v1",
          "timeline_activity_status_state" => wrapped_status_state
        },
        %{
          "schema_contract" => "result_artifact.v1",
          "source_timeline_activity_approval_state" => wrapped_approval_state
        }
      ]
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)
    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.timeline_activity_state_replay_summary(artifact)

    status_replay_summary =
      CandidateRefresh.timeline_activity_status_state_replay_summary(artifact)

    approval_replay_summary =
      CandidateRefresh.timeline_activity_approval_state_replay_summary(artifact)

    expected_source_paths = [
      "source_timeline_activity_state[0]",
      "timeline_activity_state",
      "source_timeline_activity_status_state[0]",
      "timeline_activity_status_state",
      "source_timeline_activity_approval_state[0]",
      "timeline_activity_approval_state",
      "source_result_artifact[0]",
      "source_result_artifact[1].timeline_activity_status_state",
      "source_result_artifact[2].source_timeline_activity_approval_state"
    ]

    expected_status_state_paths = [
      "source_timeline_activity_status_state[0]",
      "timeline_activity_status_state",
      "source_result_artifact[1].timeline_activity_status_state"
    ]

    expected_approval_state_paths = [
      "source_timeline_activity_approval_state[0]",
      "timeline_activity_approval_state",
      "source_result_artifact[2].source_timeline_activity_approval_state"
    ]

    assert %{
             "count" => 9,
             "row_count" => 9,
             "review_required_count" => 3,
             "paths" => ^expected_source_paths,
             "source_summary_schema_contract_counts" => %{
               "timeline_activity_approval_state.v1" => 3,
               "timeline_activity_state.v1" => 3,
               "timeline_activity_status_state.v1" => 3
             },
             "source_summary_model_counts" => %{
               "artifact_only_timeline_activity_approval_state" => 3,
               "artifact_only_timeline_activity_state" => 3,
               "artifact_only_timeline_activity_status_state" => 3
             },
             "transition_decision_counts" => %{"record" => 3, "review" => 3},
             "required_operator_action_counts" => %{
               "record_timeline_change" => 3,
               "review_activity_approval" => 3
             },
             "import_action_counts" => %{
               "import_replacement_activity" => 3,
               "review_timeline_diff" => 3
             },
             "review_activity_id_counts" => %{
               "canonical_approval_state_cmd_pending" => 3,
               "direct_approval_state_cmd_pending" => 3,
               "wrapped_approval_state_cmd_pending" => 3
             },
             "action_routing" => %{
               "record_timeline_change" => %{
                 "activity_ids" => [
                   "canonical_status_state_cmd_pending",
                   "direct_status_state_cmd_pending",
                   "wrapped_status_state_cmd_pending"
                 ],
                 "review_count" => 3,
                 "status_transition_categories" => ["execution_recorded"],
                 "timeline_ids" => [
                   "timeline:canonical_status_state:cmd_pending",
                   "timeline:direct_status_state:cmd_pending",
                   "timeline:wrapped_status_state:cmd_pending"
                 ]
               },
               "review_activity_approval" => %{
                 "activity_ids" => [
                   "canonical_approval_state_cmd_pending",
                   "direct_approval_state_cmd_pending",
                   "wrapped_approval_state_cmd_pending"
                 ],
                 "approval_transition_categories" => ["approval_granted"],
                 "review_count" => 3,
                 "timeline_ids" => [
                   "timeline:canonical_approval_state:cmd_pending",
                   "timeline:direct_approval_state:cmd_pending",
                   "timeline:wrapped_approval_state:cmd_pending"
                 ]
               }
             },
             "trust_boundary_status" => "missing",
             "trust_boundaries" => []
           } = source_summary["source_reports"]["timeline_activity_state"]

    assert %{
             "source_report_timeline_activity_state_count" => 9,
             "source_report_timeline_activity_state_row_count" => 9,
             "source_report_timeline_activity_state_paths" => ^expected_source_paths,
             "source_report_timeline_activity_status_state_contract" =>
               "timeline_activity_status_state.v1",
             "source_report_timeline_activity_status_state_count" => 3,
             "source_report_timeline_activity_status_state_row_count" => 3,
             "source_report_timeline_activity_status_state_paths" => ^expected_status_state_paths,
             "source_report_timeline_activity_status_state_source_summary_schema_contract_counts" =>
               %{"timeline_activity_status_state.v1" => 3},
             "source_report_timeline_activity_status_state_source_summary_model_counts" => %{
               "artifact_only_timeline_activity_status_state" => 3
             },
             "source_report_timeline_activity_status_state_review_required_count" => 0,
             "source_report_timeline_activity_status_state_transition_decision_counts" => %{
               "record" => 3
             },
             "source_report_timeline_activity_status_state_required_operator_action_counts" => %{
               "record_timeline_change" => 3
             },
             "source_report_timeline_activity_status_state_import_action_counts" => %{
               "import_replacement_activity" => 3
             },
             "source_report_timeline_activity_status_state_status_transition_category_counts" =>
               %{"execution_recorded" => 3},
             "source_report_timeline_activity_status_state_branch_local_timeline_activity_status_state_pressure" =>
               true,
             "source_report_timeline_activity_status_state_branch_local_review_pressure" => false,
             "source_report_timeline_activity_status_state_branch_local_action_pressure" => true,
             "source_report_timeline_activity_status_state_branch_local_routing_pressure" => true
           } = source_summary

    assert source_summary["source_report_timeline_activity_status_state_action_routing"] ==
             status_replay_summary["action_routing"]

    assert %{
             "source_report_timeline_activity_approval_state_contract" =>
               "timeline_activity_approval_state.v1",
             "source_report_timeline_activity_approval_state_count" => 3,
             "source_report_timeline_activity_approval_state_row_count" => 3,
             "source_report_timeline_activity_approval_state_paths" =>
               ^expected_approval_state_paths,
             "source_report_timeline_activity_approval_state_source_summary_schema_contract_counts" =>
               %{"timeline_activity_approval_state.v1" => 3},
             "source_report_timeline_activity_approval_state_source_summary_model_counts" => %{
               "artifact_only_timeline_activity_approval_state" => 3
             },
             "source_report_timeline_activity_approval_state_review_required_count" => 3,
             "source_report_timeline_activity_approval_state_transition_decision_counts" => %{
               "review" => 3
             },
             "source_report_timeline_activity_approval_state_required_operator_action_counts" =>
               %{
                 "review_activity_approval" => 3
               },
             "source_report_timeline_activity_approval_state_import_action_counts" => %{
               "review_timeline_diff" => 3
             },
             "source_report_timeline_activity_approval_state_approval_transition_category_counts" =>
               %{"approval_granted" => 3},
             "source_report_timeline_activity_approval_state_branch_local_timeline_activity_approval_state_pressure" =>
               true,
             "source_report_timeline_activity_approval_state_branch_local_review_pressure" =>
               true,
             "source_report_timeline_activity_approval_state_branch_local_action_pressure" =>
               true,
             "source_report_timeline_activity_approval_state_branch_local_routing_pressure" =>
               true
           } = source_summary

    assert source_summary["source_report_timeline_activity_approval_state_action_routing"] ==
             approval_replay_summary["action_routing"]

    assert %{
             "source_report_timeline_activity_state_branch_local_timeline_activity_state_pressure" =>
               true,
             "source_report_timeline_activity_state_branch_local_review_pressure" => true,
             "source_report_timeline_activity_state_branch_local_action_pressure" => true,
             "source_report_timeline_activity_state_branch_local_routing_pressure" => true
           } = source_summary

    assert %{
             "model" => "artifact_only_candidate_refresh_timeline_activity_state_replay_summary",
             "source" => "candidate_refresh.source_report_provenance.timeline_activity_state",
             "source_report_count" => 9,
             "source_report_row_count" => 9,
             "source_report_paths" => ^expected_source_paths,
             "branch_local_timeline_activity_state_pressure" => true,
             "branch_local_activity_state_review_pressure" => true,
             "branch_local_activity_state_action_pressure" => true,
             "branch_local_activity_state_routing_pressure" => true,
             "assumptions" => %{
               "activity_state_application" => "not_performed_by_summary",
               "import_approval" => "not_granted_by_timeline_activity_state_replay_summary",
               "timeline_mutation" => "not_performed_by_summary"
             }
           } = replay_summary

    assert replay_summary ==
             OrbitalDynamics.candidate_refresh_timeline_activity_state_replay_summary(artifact)

    provenance_artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert %{
             "source_report_timeline_activity_state_branch_local_timeline_activity_state_pressure" =>
               true,
             "source_report_timeline_activity_state_branch_local_review_pressure" => true,
             "source_report_timeline_activity_state_branch_local_action_pressure" => true,
             "source_report_timeline_activity_state_branch_local_routing_pressure" => true
           } = CandidateRefresh.source_report_summary(provenance_artifact)

    assert CandidateRefresh.timeline_activity_state_replay_summary(provenance_artifact) ==
             replay_summary

    assert %{
             "model" =>
               "artifact_only_candidate_refresh_timeline_activity_status_state_replay_summary",
             "source" =>
               "candidate_refresh.source_report_provenance.timeline_activity_status_state",
             "contract" => "timeline_activity_status_state.v1",
             "source_report_count" => 3,
             "source_report_row_count" => 3,
             "source_report_paths" => ^expected_status_state_paths,
             "source_summary_schema_contract_counts" => %{
               "timeline_activity_status_state.v1" => 3
             },
             "source_summary_model_counts" => %{
               "artifact_only_timeline_activity_status_state" => 3
             },
             "review_required_count" => 0,
             "transition_decision_counts" => %{"record" => 3},
             "required_operator_action_counts" => %{"record_timeline_change" => 3},
             "import_action_counts" => %{"import_replacement_activity" => 3},
             "planned_status_category_counts" => %{"planned" => 3},
             "realized_status_category_counts" => %{"executed" => 3},
             "status_transition_category_counts" => %{"execution_recorded" => 3},
             "activity_id_counts" => %{
               "canonical_status_state_cmd_pending" => 3,
               "direct_status_state_cmd_pending" => 3,
               "wrapped_status_state_cmd_pending" => 3
             },
             "timeline_id_counts" => %{
               "timeline:canonical_status_state:cmd_pending" => 3,
               "timeline:direct_status_state:cmd_pending" => 3,
               "timeline:wrapped_status_state:cmd_pending" => 3
             },
             "review_activity_id_counts" => %{},
             "action_routing" => %{
               "record_timeline_change" => %{
                 "activity_ids" => [
                   "canonical_status_state_cmd_pending",
                   "direct_status_state_cmd_pending",
                   "wrapped_status_state_cmd_pending"
                 ],
                 "review_count" => 3,
                 "status_transition_categories" => ["execution_recorded"],
                 "timeline_ids" => [
                   "timeline:canonical_status_state:cmd_pending",
                   "timeline:direct_status_state:cmd_pending",
                   "timeline:wrapped_status_state:cmd_pending"
                 ]
               }
             },
             "branch_local_timeline_activity_status_state_pressure" => true,
             "branch_local_timeline_activity_status_state_review_pressure" => false,
             "branch_local_timeline_activity_status_state_action_pressure" => true,
             "branch_local_timeline_activity_status_state_routing_pressure" => true,
             "assumptions" => %{
               "activity_status_state_application" => "not_performed_by_summary",
               "operator_authority" =>
                 "not_granted_by_timeline_activity_status_state_replay_summary",
               "import_approval" =>
                 "not_granted_by_timeline_activity_status_state_replay_summary",
               "timeline_mutation" => "not_performed_by_summary"
             }
           } = status_replay_summary

    assert status_replay_summary ==
             OrbitalDynamics.candidate_refresh_timeline_activity_status_state_replay_summary(
               artifact
             )

    assert %{
             "model" =>
               "artifact_only_candidate_refresh_timeline_activity_approval_state_replay_summary",
             "source" =>
               "candidate_refresh.source_report_provenance.timeline_activity_approval_state",
             "contract" => "timeline_activity_approval_state.v1",
             "source_report_count" => 3,
             "source_report_row_count" => 3,
             "source_report_paths" => ^expected_approval_state_paths,
             "source_summary_schema_contract_counts" => %{
               "timeline_activity_approval_state.v1" => 3
             },
             "source_summary_model_counts" => %{
               "artifact_only_timeline_activity_approval_state" => 3
             },
             "review_required_count" => 3,
             "transition_decision_counts" => %{"review" => 3},
             "required_operator_action_counts" => %{"review_activity_approval" => 3},
             "import_action_counts" => %{"review_timeline_diff" => 3},
             "planned_approval_category_counts" => %{"review_required" => 3},
             "realized_approval_category_counts" => %{"protected" => 3},
             "approval_transition_category_counts" => %{"approval_granted" => 3},
             "review_activity_id_counts" => %{
               "canonical_approval_state_cmd_pending" => 3,
               "direct_approval_state_cmd_pending" => 3,
               "wrapped_approval_state_cmd_pending" => 3
             },
             "action_routing" => %{
               "review_activity_approval" => %{
                 "activity_ids" => [
                   "canonical_approval_state_cmd_pending",
                   "direct_approval_state_cmd_pending",
                   "wrapped_approval_state_cmd_pending"
                 ],
                 "approval_transition_categories" => ["approval_granted"],
                 "review_count" => 3,
                 "timeline_ids" => [
                   "timeline:canonical_approval_state:cmd_pending",
                   "timeline:direct_approval_state:cmd_pending",
                   "timeline:wrapped_approval_state:cmd_pending"
                 ]
               }
             },
             "branch_local_timeline_activity_approval_state_pressure" => true,
             "branch_local_timeline_activity_approval_state_review_pressure" => true,
             "branch_local_timeline_activity_approval_state_action_pressure" => true,
             "branch_local_timeline_activity_approval_state_routing_pressure" => true,
             "assumptions" => %{
               "activity_approval_state_application" => "not_performed_by_summary",
               "operator_authority" =>
                 "not_granted_by_timeline_activity_approval_state_replay_summary",
               "import_approval" =>
                 "not_granted_by_timeline_activity_approval_state_replay_summary",
               "timeline_mutation" => "not_performed_by_summary"
             }
           } = approval_replay_summary

    assert approval_replay_summary ==
             OrbitalDynamics.candidate_refresh_timeline_activity_approval_state_replay_summary(
               artifact
             )

    lifecycle_rows =
      Enum.filter(review["rows"], &(&1["review_type"] == "timeline_lifecycle_state_review"))

    assert length(lifecycle_rows) == 9

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "timeline_lifecycle_state_review_count" => 9,
             "review_type_counts" => %{"timeline_lifecycle_state_review" => 9}
           } = review

    assert Enum.sort(Enum.map(lifecycle_rows, & &1["source"]) |> Enum.uniq()) == [
             "candidate_refresh.source_result_artifact[0].state",
             "candidate_refresh.source_result_artifact[1].timeline_activity_status_state.state",
             "candidate_refresh.source_result_artifact[2].source_timeline_activity_approval_state.state",
             "candidate_refresh.source_timeline_activity_approval_state[0].state",
             "candidate_refresh.source_timeline_activity_state[0].state",
             "candidate_refresh.source_timeline_activity_status_state[0].state",
             "candidate_refresh.timeline_activity_approval_state.state",
             "candidate_refresh.timeline_activity_state.state",
             "candidate_refresh.timeline_activity_status_state.state"
           ]

    assert lifecycle_rows
           |> Enum.map(&get_in(&1, ["source_timeline_lifecycle_state", "schema_contract"]))
           |> Enum.frequencies() == %{
             "timeline_activity_approval_state.v1" => 3,
             "timeline_activity_state.v1" => 3,
             "timeline_activity_status_state.v1" => 3
           }

    assert Enum.any?(
             lifecycle_rows,
             &match?(
               %{
                 "source" => "candidate_refresh.timeline_activity_status_state.state",
                 "timeline_id" => "timeline:canonical_status_state:cmd_pending",
                 "transition_decision" => "record",
                 "required_operator_action" => "record_timeline_change",
                 "status_transition" => %{"transition_category" => "execution_recorded"}
               },
               &1
             )
           )

    assert Enum.any?(
             lifecycle_rows,
             &match?(
               %{
                 "source" => "candidate_refresh.timeline_activity_approval_state.state",
                 "timeline_id" => "timeline:canonical_approval_state:cmd_pending",
                 "transition_decision" => "review",
                 "required_operator_action" => "review_activity_approval",
                 "approval_transition" => %{"transition_category" => "approval_granted"}
               },
               &1
             )
           )

    import_rows =
      Enum.filter(
        import["rows"],
        &(&1["source_review_type"] == "timeline_lifecycle_state_review")
      )

    assert length(import_rows) == 9

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "import_action_counts" => %{"review_timeline_lifecycle_state" => 9},
             "source_review_type_counts" => %{"timeline_lifecycle_state_review" => 9}
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

  test "timeline activity state replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.timeline_activity_state_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_timeline_activity_state_contract")
    refute Map.has_key?(source_summary, "source_report_timeline_activity_state_count")
    refute Map.has_key?(source_summary, "source_report_timeline_activity_state_row_count")
    refute Map.has_key?(source_summary, "source_report_timeline_activity_state_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_timeline_activity_state_pressure"]
  end

  test "timeline activity state source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "timeline_activity_state.v1"},
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.timeline_activity_state"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.timeline_activity_state"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "timeline_activity_state" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_timeline_activity_state_contract"] ==
                 "timeline_activity_state.v1"
      else
        refute Map.has_key?(source_summary, "source_report_timeline_activity_state_contract")
      end

      refute Map.has_key?(source_summary, "source_report_timeline_activity_state_count")
      refute Map.has_key?(source_summary, "source_report_timeline_activity_state_row_count")
      refute Map.has_key?(source_summary, "source_report_timeline_activity_state_paths")
    end
  end

  test "timeline activity state source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_activity_state" => %{
            "contract" => "timeline_activity_state.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.timeline_activity_state"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_activity_state_contract"] ==
             "timeline_activity_state.v1"

    assert source_summary["source_report_timeline_activity_state_count"] == 0
    assert source_summary["source_report_timeline_activity_state_row_count"] == 0

    assert source_summary["source_report_timeline_activity_state_paths"] == [
             "provenance.source_reports.timeline_activity_state"
           ]
  end

  test "timeline activity state source summary omits missing identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_activity_state" => %{
            "contract" => "timeline_activity_state.v1",
            "count" => 1,
            "row_count" => 2
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_activity_state_contract"] ==
             "timeline_activity_state.v1"

    assert source_summary["source_report_timeline_activity_state_count"] == 1
    assert source_summary["source_report_timeline_activity_state_row_count"] == 2
    refute Map.has_key?(source_summary, "source_report_timeline_activity_state_paths")
  end

  test "timeline activity state source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_activity_state" => %{
            "contract" => "timeline_activity_state.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_activity_state_contract"] ==
             "timeline_activity_state.v1"

    assert source_summary["source_report_timeline_activity_state_count"] == 1
    assert source_summary["source_report_timeline_activity_state_row_count"] == 2
    assert source_summary["source_report_timeline_activity_state_paths"] == []
  end

  test "timeline activity state replay summaries preserve invalid input evidence" do
    invalid_status_state = fn prefix ->
      Timeline.activity_status_state(
        %{id: :"#{prefix}_missing_type", status: :planned},
        %{id: :"#{prefix}_missing_type", type: :observe, status: :completed}
      )
    end

    invalid_approval_state = fn prefix ->
      Timeline.activity_approval_state(
        %{id: :"#{prefix}_missing_type", type: :command, approval_status: :pending},
        %{id: :"#{prefix}_missing_type", approval_status: :approved}
      )
    end

    invalid_lifecycle_state = fn prefix ->
      Timeline.activity_lifecycle_state(
        %{id: :"#{prefix}_missing_type", status: :planned, approval_status: :pending},
        nil
      )
    end

    direct_status_state = invalid_status_state.("direct_status_state")
    canonical_status_state = invalid_status_state.("canonical_status_state")
    wrapped_status_state = invalid_status_state.("wrapped_status_state")
    direct_approval_state = invalid_approval_state.("direct_approval_state")
    canonical_approval_state = invalid_approval_state.("canonical_approval_state")
    wrapped_approval_state = invalid_approval_state.("wrapped_approval_state")
    direct_lifecycle_state = invalid_lifecycle_state.("direct_lifecycle_state")
    canonical_lifecycle_state = invalid_lifecycle_state.("canonical_lifecycle_state")
    wrapped_lifecycle_state = invalid_lifecycle_state.("wrapped_lifecycle_state")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:timeline_activity_invalid_inputs",
      "source_timeline_activity_status_state" => [direct_status_state],
      "timeline_activity_status_state" => canonical_status_state,
      "source_timeline_activity_approval_state" => [direct_approval_state],
      "timeline_activity_approval_state" => canonical_approval_state,
      "source_timeline_activity_lifecycle_state" => [direct_lifecycle_state],
      "timeline_activity_lifecycle_state" => canonical_lifecycle_state,
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "timeline_activity_status_state" => wrapped_status_state
        },
        %{
          "schema_contract" => "result_artifact.v1",
          "source_timeline_activity_approval_state" => wrapped_approval_state
        },
        %{
          "schema_contract" => "result_artifact.v1",
          "timeline_activity_lifecycle_state" => wrapped_lifecycle_state
        }
      ]
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    status_replay_summary =
      CandidateRefresh.timeline_activity_status_state_replay_summary(artifact)

    approval_replay_summary =
      CandidateRefresh.timeline_activity_approval_state_replay_summary(artifact)

    lifecycle_replay_summary =
      CandidateRefresh.timeline_activity_lifecycle_state_replay_summary(artifact)

    assert %{
             "invalid_activity_input_count" => 6,
             "invalid_activity_input_reason_counts" => %{"missing_activity_type" => 6},
             "invalid_activity_input_reasons" => ["missing_activity_type"],
             "transition_decision_counts" => %{"review" => 6},
             "required_operator_action_counts" => %{
               "review_activity_approval" => 3,
               "review_activity_transition" => 3
             },
             "status_transition_category_counts" => %{"invalid_activity_input" => 3},
             "approval_transition_category_counts" => %{"invalid_activity_input" => 3}
           } = source_summary["source_reports"]["timeline_activity_state"]

    assert %{
             "invalid_activity_input_count" => 3,
             "invalid_activity_input_reason_counts" => %{"missing_activity_type" => 3},
             "invalid_activity_input_reasons" => ["missing_activity_type"],
             "transition_decision_counts" => %{"review" => 3},
             "required_operator_action_counts" => %{
               "review_activity_approval" => 3,
               "review_activity_transition" => 3,
               "review_timeline_change" => 3
             },
             "status_transition_category_counts" => %{"invalid_activity_input" => 3},
             "approval_transition_category_counts" => %{"invalid_activity_input" => 3},
             "protection_category_counts" => %{"invalid_activity_input" => 3}
           } = source_summary["source_reports"]["timeline_activity_lifecycle_state"]

    assert %{
             "source_report_timeline_activity_state_invalid_activity_input_count" => 6,
             "source_report_timeline_activity_state_invalid_activity_input_reason_counts" => %{
               "missing_activity_type" => 6
             },
             "source_report_timeline_activity_lifecycle_state_invalid_activity_input_count" => 3,
             "source_report_timeline_activity_lifecycle_state_invalid_activity_input_reason_counts" =>
               %{
                 "missing_activity_type" => 3
               }
           } = source_summary

    assert %{
             "contract" => "timeline_activity_status_state.v1",
             "source_report_count" => 3,
             "invalid_activity_input_count" => 3,
             "invalid_activity_input_reason_counts" => %{"missing_activity_type" => 3},
             "invalid_activity_input_reasons" => ["missing_activity_type"],
             "branch_local_timeline_activity_status_state_pressure" => true,
             "branch_local_timeline_activity_status_state_review_pressure" => true
           } = status_replay_summary

    assert %{
             "contract" => "timeline_activity_approval_state.v1",
             "source_report_count" => 3,
             "invalid_activity_input_count" => 3,
             "invalid_activity_input_reason_counts" => %{"missing_activity_type" => 3},
             "invalid_activity_input_reasons" => ["missing_activity_type"],
             "branch_local_timeline_activity_approval_state_pressure" => true,
             "branch_local_timeline_activity_approval_state_review_pressure" => true
           } = approval_replay_summary

    assert %{
             "contract" => "timeline_activity_lifecycle_state.v1",
             "source_report_count" => 3,
             "invalid_activity_input_count" => 3,
             "invalid_activity_input_reason_counts" => %{"missing_activity_type" => 3},
             "invalid_activity_input_reasons" => ["missing_activity_type"],
             "branch_local_timeline_activity_lifecycle_state_pressure" => true,
             "branch_local_activity_lifecycle_review_pressure" => true
           } = lifecycle_replay_summary

    assert status_replay_summary ==
             OrbitalDynamics.candidate_refresh_timeline_activity_status_state_replay_summary(
               artifact
             )

    assert approval_replay_summary ==
             OrbitalDynamics.candidate_refresh_timeline_activity_approval_state_replay_summary(
               artifact
             )

    assert lifecycle_replay_summary ==
             OrbitalDynamics.candidate_refresh_timeline_activity_lifecycle_state_replay_summary(
               artifact
             )
  end
end
