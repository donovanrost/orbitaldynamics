defmodule OrbitalDynamics.OperatorReview.TimelineActivityStateTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema, Timeline}

  test "single activity timeline states become operator review rows" do
    planned = %{
      id: :cmd_provider,
      type: :command,
      status: "In Progress",
      approval_status: "Review Required",
      metadata: %{
        timeline_id: :"timeline:cmd_provider",
        source_window_id: :"command:cmd_provider"
      }
    }

    realized = %{
      id: :cmd_provider,
      type: :command,
      status: "succeeded",
      approval_status: :approved,
      metadata: %{timeline_id: :"timeline:cmd_provider"}
    }

    status_state = Timeline.activity_status_state(planned, realized)
    approval_state = Timeline.activity_approval_state(planned, realized)
    lifecycle_state = Timeline.activity_lifecycle_state(planned, realized)
    activity_state = OrbitalDynamics.timeline_activity_state(planned, realized)

    atom_key_lifecycle_state =
      lifecycle_state
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()

    status_package = OperatorReview.from_timeline_activity_status_state(status_state)

    assert %{
             "source_artifact_type" => "timeline_activity_status_state.v1",
             "source_artifact_id" => "timeline:cmd_provider",
             "review_count" => 1,
             "timeline_lifecycle_state_review_count" => 1
           } = status_package

    assert [
             %{
               "review_type" => "timeline_lifecycle_state_review",
               "source" => "timeline_activity_status_state.state",
               "subject_id" => "timeline:cmd_provider",
               "timeline_id" => "timeline:cmd_provider",
               "activity_id" => "cmd_provider",
               "timeline_lifecycle_state_status" => "review_required",
               "transition_decision" => "record",
               "required_operator_action" => "record_timeline_change",
               "approval_status" => "not_required",
               "operator_action_reason" => "activity_execution_recorded",
               "import_action" => "import_replacement_activity",
               "source_lifecycle_state_review_required_count" => 0,
               "source_timeline_lifecycle_state" => %{
                 "schema_contract" => "timeline_activity_status_state.v1",
                 "timeline_id" => "timeline:cmd_provider"
               }
             }
           ] = status_package["rows"]

    activity_state_package = OperatorReview.from_timeline_activity_state(activity_state)

    assert %{
             "source_artifact_type" => "timeline_activity_state.v1",
             "source_artifact_id" => "timeline:cmd_provider",
             "review_count" => 1,
             "timeline_lifecycle_state_review_count" => 1
           } = activity_state_package

    assert [
             %{
               "review_type" => "timeline_lifecycle_state_review",
               "source" => "timeline_activity_state.state",
               "subject_id" => "timeline:cmd_provider",
               "timeline_id" => "timeline:cmd_provider",
               "activity_id" => "cmd_provider",
               "timeline_lifecycle_state_status" => "review_required",
               "approval_status" => "not_required",
               "source_lifecycle_state_review_required_count" => 0,
               "source_timeline_activity_state" => %{
                 "schema_contract" => "timeline_activity_state.v1",
                 "timeline_id" => "timeline:cmd_provider",
                 "state_status" => "matched",
                 "row_count" => 1
               }
             }
           ] = activity_state_package["rows"]

    refute Map.has_key?(
             hd(activity_state_package["rows"]),
             "source_timeline_lifecycle_state"
           )

    approval_package = OperatorReview.from_timeline_activity_approval_state(approval_state)

    assert %{
             "source_artifact_type" => "timeline_activity_approval_state.v1",
             "source_artifact_id" => "timeline:cmd_provider",
             "review_count" => 1,
             "required_operator_action_counts" => %{"review_activity_approval" => 1}
           } = approval_package

    assert [
             %{
               "source" => "timeline_activity_approval_state.state",
               "transition_decision" => "review",
               "required_operator_action" => "review_activity_approval",
               "approval_status" => "operator_review_required",
               "approval_transition" => %{"transition_category" => "approval_granted"}
             }
           ] = approval_package["rows"]

    lifecycle_package = OperatorReview.from_timeline_activity_lifecycle_state(lifecycle_state)

    assert %{
             "source_artifact_type" => "timeline_activity_lifecycle_state.v1",
             "source_artifact_id" => "timeline:cmd_provider",
             "review_count" => 1,
             "required_operator_action_counts" => %{"review_activity_approval" => 1}
           } = lifecycle_package

    assert [
             %{
               "source" => "timeline_activity_lifecycle_state.state",
               "transition_decision" => "review",
               "required_operator_actions" => [
                 "record_timeline_change",
                 "review_activity_approval"
               ],
               "operator_action_reasons" => [
                 "activity_execution_recorded",
                 "approval_grant_requires_operator_authority"
               ],
               "source_timeline_lifecycle_state" => %{
                 "schema_contract" => "timeline_activity_lifecycle_state.v1"
               }
             }
           ] = lifecycle_package["rows"]

    assert OrbitalDynamics.operator_review_package(status_state) == status_package

    assert OrbitalDynamics.operator_review_package(Map.delete(status_state, "schema_contract")) ==
             status_package

    assert OrbitalDynamics.operator_review_package(activity_state) == activity_state_package

    assert OrbitalDynamics.operator_review_package(Map.delete(activity_state, "schema_contract")) ==
             activity_state_package

    assert OrbitalDynamics.operator_review_package(approval_state) == approval_package
    assert OrbitalDynamics.operator_review_package(lifecycle_state) == lifecycle_package
    assert OrbitalDynamics.operator_review_package(atom_key_lifecycle_state) == lifecycle_package

    assert OrbitalDynamics.operator_review_package(
             Map.delete(atom_key_lifecycle_state, :schema_contract)
           ) == lifecycle_package

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(lifecycle_package)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(activity_state_package)

    invalid_activity_state_source =
      put_in(
        activity_state_package,
        ["rows", Access.at(0), "source_timeline_activity_state", "timeline_id"],
        "bad timeline id"
      )

    assert {:error, invalid_activity_state_source_report} =
             Schema.validate_artifact(invalid_activity_state_source)

    assert Enum.any?(
             invalid_activity_state_source_report["errors"],
             &(&1["path"] == "$.rows[0].source_timeline_activity_state.timeline_id" and
                 &1["message"] =~ "stable ID")
           )

    invalid_status_state =
      Timeline.activity_status_state(
        %{id: :obs_missing_type, status: :planned},
        %{id: :obs_missing_type, type: :observe, status: :completed}
      )

    invalid_status_package =
      OperatorReview.from_timeline_activity_status_state(invalid_status_state)

    assert %{
             "source_artifact_type" => "timeline_activity_status_state.v1",
             "source_artifact_id" => "timeline:invalid_activity_input:obs_missing_type",
             "review_count" => 1,
             "required_operator_action_counts" => %{"review_activity_transition" => 1}
           } = invalid_status_package

    assert [
             %{
               "review_type" => "timeline_lifecycle_state_review",
               "activity_id" => "obs_missing_type",
               "timeline_id" => "timeline:invalid_activity_input:obs_missing_type",
               "transition_decision" => "review",
               "required_operator_action" => "review_activity_transition",
               "operator_action_reason" => "invalid_activity_input",
               "invalid_activity_input" => true,
               "invalid_activity_input_count" => 1,
               "invalid_activity_input_reasons" => ["missing_activity_type"],
               "status_transition" => %{"transition_category" => "invalid_activity_input"},
               "source_timeline_lifecycle_state" => %{
                 "schema_contract" => "timeline_activity_status_state.v1",
                 "invalid_activity_input" => true,
                 "invalid_activity_input_count" => 1,
                 "invalid_activity_input_reasons" => ["missing_activity_type"]
               }
             }
           ] = invalid_status_package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(invalid_status_package)

    invalid_approval_state =
      Timeline.activity_approval_state(
        %{id: :cmd_missing_type, type: :command, approval_status: :pending},
        %{id: :cmd_missing_type, approval_status: :approved}
      )

    invalid_approval_package =
      OperatorReview.from_timeline_activity_approval_state(invalid_approval_state)

    assert [
             %{
               "required_operator_action" => "review_activity_approval",
               "invalid_activity_input" => true,
               "invalid_activity_input_count" => 1,
               "invalid_activity_input_reasons" => ["missing_activity_type"],
               "approval_transition" => %{"transition_category" => "invalid_activity_input"},
               "source_timeline_lifecycle_state" => %{
                 "schema_contract" => "timeline_activity_approval_state.v1",
                 "invalid_activity_input" => true
               }
             }
           ] = invalid_approval_package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(invalid_approval_package)

    invalid_lifecycle_state =
      Timeline.activity_lifecycle_state(
        %{id: :cmd_lifecycle_missing_type, status: :planned, approval_status: :pending},
        nil
      )

    invalid_lifecycle_package =
      OperatorReview.from_timeline_activity_lifecycle_state(invalid_lifecycle_state)

    assert [
             %{
               "required_operator_action" => "review_activity_transition",
               "required_operator_actions" => [
                 "review_activity_approval",
                 "review_activity_transition",
                 "review_timeline_change"
               ],
               "invalid_activity_input" => true,
               "invalid_activity_input_count" => 1,
               "invalid_activity_input_reasons" => ["missing_activity_type"],
               "source_timeline_lifecycle_state" => %{
                 "schema_contract" => "timeline_activity_lifecycle_state.v1",
                 "invalid_activity_input" => true,
                 "invalid_activity_input_count" => 1
               }
             }
           ] = invalid_lifecycle_package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(invalid_lifecycle_package)
  end

  test "single activity timeline state source ids fall back to adapter defaults" do
    assert %{"source_artifact_id" => "timeline_activity_state"} =
             OperatorReview.from_timeline_activity_state(%{})

    assert %{"source_artifact_id" => "timeline_activity_status_state"} =
             OperatorReview.from_timeline_activity_status_state(%{})

    assert %{"source_artifact_id" => "timeline_activity_approval_state"} =
             OperatorReview.from_timeline_activity_approval_state(%{})

    assert %{"source_artifact_id" => "timeline_activity_lifecycle_state"} =
             OperatorReview.from_timeline_activity_lifecycle_state(%{})
  end

  test "CandidateRefresh lifts accepted planning state activity status states" do
    planned = %{
      id: :cmd_accepted_state,
      type: :command,
      status: "In Progress",
      approval_status: "Approved",
      metadata: %{timeline_id: :"timeline:cmd_accepted_state"}
    }

    realized = %{
      id: :cmd_accepted_state,
      type: :command,
      status: "succeeded",
      approval_status: "Approved",
      metadata: %{timeline_id: :"timeline:cmd_accepted_state"}
    }

    state = Timeline.activity_status_state(planned, realized)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:accepted_activity_status_state_handoff",
      "accepted_planning_state" => %{
        "source_timeline_activity_status_state" => state
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:accepted_activity_status_state_handoff",
             "review_count" => 1,
             "timeline_lifecycle_state_review_count" => 1,
             "review_type_counts" => %{"timeline_lifecycle_state_review" => 1}
           } = review

    assert [
             %{
               "review_type" => "timeline_lifecycle_state_review",
               "source" =>
                 "candidate_refresh.accepted_planning_state.source_timeline_activity_status_state.state",
               "timeline_id" => "timeline:cmd_accepted_state",
               "activity_id" => "cmd_accepted_state",
               "transition_decision" => "record",
               "required_operator_action" => "record_timeline_change",
               "approval_status" => "not_required",
               "import_action" => "import_replacement_activity",
               "source_timeline_lifecycle_state" => %{
                 "schema_contract" => "timeline_activity_status_state.v1",
                 "timeline_id" => "timeline:cmd_accepted_state"
               }
             }
           ] = review["rows"]

    assert %{
             "row_count" => 1,
             "import_action_counts" => %{"review_timeline_lifecycle_state" => 1},
             "source_review_type_counts" => %{"timeline_lifecycle_state_review" => 1}
           } = import

    assert [
             %{
               "import_action" => "review_timeline_lifecycle_state",
               "source_review_type" => "timeline_lifecycle_state_review",
               "timeline_id" => "timeline:cmd_accepted_state",
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.accepted_planning_state.source_timeline_activity_status_state.state",
                 "source_timeline_lifecycle_state" => %{
                   "schema_contract" => "timeline_activity_status_state.v1"
                 }
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "CandidateRefresh lifts accepted planning state aggregate activity states" do
    planned = %{
      id: :cmd_accepted_activity_state,
      type: :command,
      status: "In Progress",
      approval_status: "Approved",
      metadata: %{timeline_id: :"timeline:cmd_accepted_activity_state"}
    }

    realized = %{
      id: :cmd_accepted_activity_state,
      type: :command,
      status: "succeeded",
      approval_status: "Approved",
      metadata: %{timeline_id: :"timeline:cmd_accepted_activity_state"}
    }

    state = OrbitalDynamics.timeline_activity_state(planned, realized)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:accepted_activity_state_handoff",
      "accepted_planning_state" => %{
        "timeline_activity_state" => state
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:accepted_activity_state_handoff",
             "review_count" => 1,
             "timeline_lifecycle_state_review_count" => 1,
             "review_type_counts" => %{"timeline_lifecycle_state_review" => 1}
           } = review

    assert [
             %{
               "review_type" => "timeline_lifecycle_state_review",
               "source" =>
                 "candidate_refresh.accepted_planning_state.timeline_activity_state.state",
               "timeline_id" => "timeline:cmd_accepted_activity_state",
               "activity_id" => "cmd_accepted_activity_state",
               "required_operator_action" => "record_timeline_change",
               "approval_status" => "not_required",
               "source_timeline_lifecycle_state" => %{
                 "schema_contract" => "timeline_activity_state.v1",
                 "timeline_id" => "timeline:cmd_accepted_activity_state"
               }
             }
           ] = review["rows"]

    assert %{
             "row_count" => 1,
             "import_action_counts" => %{"review_timeline_lifecycle_state" => 1},
             "source_review_type_counts" => %{"timeline_lifecycle_state_review" => 1}
           } = import

    assert [
             %{
               "import_action" => "review_timeline_lifecycle_state",
               "source_review_type" => "timeline_lifecycle_state_review",
               "timeline_id" => "timeline:cmd_accepted_activity_state",
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.accepted_planning_state.timeline_activity_state.state",
                 "source_timeline_lifecycle_state" => %{
                   "schema_contract" => "timeline_activity_state.v1"
                 }
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "CandidateRefresh lifts mission state activity approval states" do
    planned = %{
      id: :cmd_mission_approval,
      type: :command,
      status: "planned",
      approval_status: "pending",
      metadata: %{timeline_id: :"timeline:cmd_mission_approval"}
    }

    realized = %{
      id: :cmd_mission_approval,
      type: :command,
      status: "planned",
      approval_status: "approved",
      metadata: %{timeline_id: :"timeline:cmd_mission_approval"}
    }

    state = Timeline.activity_approval_state(planned, realized)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:mission_activity_approval_state_handoff",
      "mission_state" => %{
        "timeline_activity_approval_state" => state
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:mission_activity_approval_state_handoff",
             "review_count" => 1,
             "timeline_lifecycle_state_review_count" => 1,
             "required_operator_action_counts" => %{"review_activity_approval" => 1}
           } = review

    assert [
             %{
               "review_type" => "timeline_lifecycle_state_review",
               "source" =>
                 "candidate_refresh.mission_state.timeline_activity_approval_state.state",
               "timeline_id" => "timeline:cmd_mission_approval",
               "activity_id" => "cmd_mission_approval",
               "transition_decision" => "review",
               "required_operator_action" => "review_activity_approval",
               "approval_status" => "operator_review_required",
               "approval_transition" => %{"transition_category" => "approval_granted"},
               "source_timeline_lifecycle_state" => %{
                 "schema_contract" => "timeline_activity_approval_state.v1",
                 "timeline_id" => "timeline:cmd_mission_approval"
               }
             }
           ] = review["rows"]

    assert %{
             "row_count" => 1,
             "import_action_counts" => %{"review_timeline_lifecycle_state" => 1},
             "source_review_type_counts" => %{"timeline_lifecycle_state_review" => 1}
           } = import

    assert [
             %{
               "import_action" => "review_timeline_lifecycle_state",
               "source_review_type" => "timeline_lifecycle_state_review",
               "timeline_id" => "timeline:cmd_mission_approval",
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.mission_state.timeline_activity_approval_state.state",
                 "source_timeline_lifecycle_state" => %{
                   "schema_contract" => "timeline_activity_approval_state.v1"
                 }
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "CandidateRefresh lifts mission state activity lifecycle states" do
    planned = %{
      id: :cmd_mission_lifecycle,
      type: :command,
      status: "planned",
      approval_status: "pending",
      locked: true,
      metadata: %{timeline_id: :"timeline:cmd_mission_lifecycle"}
    }

    realized = %{
      id: :cmd_mission_lifecycle,
      type: :command,
      status: "executed",
      approval_status: "approved",
      metadata: %{timeline_id: :"timeline:cmd_mission_lifecycle"}
    }

    state = Timeline.activity_lifecycle_state(planned, realized)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:mission_activity_lifecycle_state_handoff",
      "mission_state" => %{
        "source_timeline_activity_lifecycle_state" => state
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:mission_activity_lifecycle_state_handoff",
             "review_count" => 1,
             "timeline_lifecycle_state_review_count" => 1,
             "required_operator_action_counts" => %{"review_activity_approval" => 1}
           } = review

    assert [
             %{
               "review_type" => "timeline_lifecycle_state_review",
               "source" =>
                 "candidate_refresh.mission_state.source_timeline_activity_lifecycle_state.state",
               "timeline_id" => "timeline:cmd_mission_lifecycle",
               "activity_id" => "cmd_mission_lifecycle",
               "transition_decision" => "review",
               "required_operator_action" => "review_activity_approval",
               "approval_status" => "operator_review_required",
               "source_timeline_lifecycle_state" => %{
                 "schema_contract" => "timeline_activity_lifecycle_state.v1",
                 "timeline_id" => "timeline:cmd_mission_lifecycle",
                 "planned_locked" => true
               }
             }
           ] = review["rows"]

    assert %{
             "row_count" => 1,
             "import_action_counts" => %{"review_timeline_lifecycle_state" => 1},
             "source_review_type_counts" => %{"timeline_lifecycle_state_review" => 1}
           } = import

    assert [
             %{
               "import_action" => "review_timeline_lifecycle_state",
               "source_review_type" => "timeline_lifecycle_state_review",
               "timeline_id" => "timeline:cmd_mission_lifecycle",
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.mission_state.source_timeline_activity_lifecycle_state.state",
                 "source_timeline_lifecycle_state" => %{
                   "schema_contract" => "timeline_activity_lifecycle_state.v1",
                   "planned_locked" => true
                 }
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end
end
