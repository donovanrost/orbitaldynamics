defmodule OrbitalDynamics.OperatorReview.TimelineLifecycleStateTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema, Timeline}

  test "timeline lifecycle-state summaries become operator review rows" do
    planned = [
      %{
        id: :cmd_provider,
        type: :command,
        status: :planned,
        approval_status: :pending,
        metadata: %{timeline_id: :"timeline:cmd_provider"}
      },
      %{
        id: :done_keep,
        type: :command,
        status: :completed,
        approval_status: :approved,
        metadata: %{timeline_id: :"timeline:done_keep"}
      }
    ]

    realized = [
      %{
        id: :cmd_provider,
        type: :command,
        status: :executed,
        approval_status: :approved,
        metadata: %{timeline_id: :"timeline:cmd_provider"}
      },
      %{
        id: :done_keep,
        type: :command,
        status: :completed,
        approval_status: :approved,
        metadata: %{timeline_id: :"timeline:done_keep"}
      }
    ]

    summary = Timeline.lifecycle_state_summary(planned, realized)
    package = OperatorReview.from_timeline_lifecycle_state_summary(summary)

    atom_key_summary =
      summary
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_lifecycle_state_summary.v1",
             "source_artifact_id" => "timeline.lifecycle_state",
             "review_count" => 1,
             "timeline_lifecycle_state_review_count" => 1,
             "required_operator_action_counts" => %{"review_activity_approval" => 1},
             "review_type_counts" => %{"timeline_lifecycle_state_review" => 1}
           } = package

    assert [
             %{
               "review_type" => "timeline_lifecycle_state_review",
               "source" => "timeline_lifecycle_state_summary.review_rows",
               "subject_id" => "timeline:cmd_provider",
               "timeline_id" => "timeline:cmd_provider",
               "activity_id" => "cmd_provider",
               "planned_activity_id" => "cmd_provider",
               "realized_activity_id" => "cmd_provider",
               "timeline_lifecycle_state_status" => "review_required",
               "transition_decision" => "review",
               "required_operator_action" => "review_activity_approval",
               "approval_status" => "operator_review_required",
               "operator_action_reason" => "activity_execution_recorded",
               "operator_action_reasons" => [
                 "activity_execution_recorded",
                 "approval_grant_requires_operator_authority"
               ],
               "import_action" => "review_timeline_diff",
               "status_transition" => %{
                 "transition_category" => "execution_recorded"
               },
               "approval_transition" => %{
                 "transition_category" => "approval_granted"
               },
               "source_planned_activity_count" => 2,
               "source_realized_activity_count" => 2,
               "source_lifecycle_state_review_required_count" => 1,
               "source_lifecycle_state_operator_action_reason_counts" => %{
                 "activity_execution_recorded" => 1,
                 "approval_grant_requires_operator_authority" => 1
               },
               "source_lifecycle_state_review_timeline_ids_by_operator_action_reason" => %{
                 "activity_execution_recorded" => ["timeline:cmd_provider"],
                 "approval_grant_requires_operator_authority" => ["timeline:cmd_provider"]
               },
               "source_timeline_lifecycle_state" => %{
                 "timeline_id" => "timeline:cmd_provider",
                 "transition_decision" => "review"
               }
             }
           ] = package["rows"]

    assert OrbitalDynamics.operator_review_package(summary) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(summary, "schema_contract")) ==
             package

    assert OrbitalDynamics.operator_review_package(atom_key_summary) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(atom_key_summary, :schema_contract)) ==
             package

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_lifecycle_state =
      put_in(
        package,
        ["rows", Access.at(0), "source_timeline_lifecycle_state", "timeline_id"],
        "bad timeline id"
      )

    assert {:error, invalid_source_lifecycle_state_report} =
             Schema.validate_artifact(invalid_source_lifecycle_state)

    assert Enum.any?(
             invalid_source_lifecycle_state_report["errors"],
             &(&1["path"] == "$.rows[0].source_timeline_lifecycle_state.timeline_id" and
                 &1["message"] =~ "stable ID")
           )
  end

  test "timeline lifecycle-state summary source id uses id before source and default" do
    assert %{"source_artifact_id" => "lifecycle:001"} =
             OperatorReview.from_timeline_lifecycle_state_summary(%{
               id: :"lifecycle:001",
               source: :lifecycle_source,
               review_rows: []
             })

    assert %{"source_artifact_id" => "timeline_lifecycle_state_summary"} =
             OperatorReview.from_timeline_lifecycle_state_summary(%{review_rows: []})
  end

  test "CandidateRefresh lifts accepted planning state lifecycle summaries" do
    planned = [
      %{
        id: :cmd_provider,
        type: :command,
        status: :planned,
        approval_status: :pending,
        metadata: %{timeline_id: :"timeline:cmd_provider"}
      }
    ]

    realized = [
      %{
        id: :cmd_provider,
        type: :command,
        status: :executed,
        approval_status: :approved,
        metadata: %{timeline_id: :"timeline:cmd_provider"}
      }
    ]

    summary =
      planned
      |> Timeline.lifecycle_state_summary(realized)
      |> Map.put("source", "accepted_state.timeline_lifecycle_state_summary")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:accepted_lifecycle_state_handoff",
      "accepted_planning_state" => %{
        "timeline_lifecycle_state_summary" => summary
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:accepted_lifecycle_state_handoff",
             "review_count" => 1,
             "timeline_lifecycle_state_review_count" => 1,
             "review_type_counts" => %{"timeline_lifecycle_state_review" => 1},
             "required_operator_action_counts" => %{"review_activity_approval" => 1}
           } = review

    assert [
             %{
               "review_type" => "timeline_lifecycle_state_review",
               "source" =>
                 "candidate_refresh.accepted_planning_state.timeline_lifecycle_state_summary.review_rows",
               "timeline_id" => "timeline:cmd_provider",
               "activity_id" => "cmd_provider",
               "transition_decision" => "review",
               "required_operator_action" => "review_activity_approval",
               "status_transition" => %{"transition_category" => "execution_recorded"},
               "approval_transition" => %{"transition_category" => "approval_granted"},
               "source_lifecycle_state_review_required_count" => 1,
               "source_timeline_lifecycle_state" => %{
                 "timeline_id" => "timeline:cmd_provider",
                 "transition_decision" => "review"
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
               "timeline_id" => "timeline:cmd_provider",
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.accepted_planning_state.timeline_lifecycle_state_summary.review_rows",
                 "source_timeline_lifecycle_state" => %{
                   "timeline_id" => "timeline:cmd_provider"
                 }
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "CandidateRefresh lifts mission state lifecycle summaries" do
    planned = [
      %{
        id: :cmd_mission,
        type: :command,
        status: :planned,
        approval_status: :pending,
        metadata: %{timeline_id: :"timeline:cmd_mission"}
      }
    ]

    realized = [
      %{
        id: :cmd_mission,
        type: :command,
        status: :executed,
        approval_status: :approved,
        metadata: %{timeline_id: :"timeline:cmd_mission"}
      }
    ]

    summary =
      planned
      |> Timeline.lifecycle_state_summary(realized)
      |> Map.put("source", "mission_state.timeline_lifecycle_state_summary")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:mission_lifecycle_state_handoff",
      "mission_state" => %{
        "source_timeline_lifecycle_state_summary" => summary
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:mission_lifecycle_state_handoff",
             "review_count" => 1,
             "timeline_lifecycle_state_review_count" => 1
           } = review

    assert [
             %{
               "review_type" => "timeline_lifecycle_state_review",
               "source" =>
                 "candidate_refresh.mission_state.source_timeline_lifecycle_state_summary.review_rows",
               "timeline_id" => "timeline:cmd_mission",
               "activity_id" => "cmd_mission",
               "transition_decision" => "review",
               "required_operator_action" => "review_activity_approval",
               "source_lifecycle_state_review_required_count" => 1,
               "source_timeline_lifecycle_state" => %{
                 "timeline_id" => "timeline:cmd_mission",
                 "transition_decision" => "review"
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
               "timeline_id" => "timeline:cmd_mission",
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.mission_state.source_timeline_lifecycle_state_summary.review_rows",
                 "source_timeline_lifecycle_state" => %{
                   "timeline_id" => "timeline:cmd_mission"
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
