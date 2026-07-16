defmodule OrbitalDynamics.OperatorReview.TimelineActivityPreconditionTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema, Timeline}

  test "timeline activity precondition summaries become operator review rows" do
    activity = %{
      id: :cmd_preflight,
      type: :command,
      payload_available: false,
      degraded: true,
      resource_blocking_dimension: :power,
      dependency_activity_ids: [:health_check_1, :obs_1, :obs_1],
      dependency_timeline_ids: [:"timeline:health_check_1", :"timeline:health_check_1"],
      exclusive_with_activity_ids: [:dl_conflict, :dl_conflict],
      exclusive_with_timeline_ids: [:"timeline:dl_conflict", :"timeline:dl_conflict"],
      allow_overlap: true,
      metadata: %{timeline_id: :"timeline:cmd_preflight"}
    }

    summary = Timeline.activity_precondition_summary(activity)
    package = OperatorReview.from_timeline_activity_precondition_summary(summary)

    atom_key_summary =
      summary |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end) |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_activity_precondition_summary.v1",
             "source_artifact_id" => "timeline:cmd_preflight",
             "review_count" => 1,
             "timeline_activity_precondition_review_count" => 1,
             "required_operator_action_counts" => %{
               "review_blocked_activity_precondition" => 1
             },
             "review_type_counts" => %{"timeline_activity_precondition_review" => 1}
           } = package

    assert [
             %{
               "review_type" => "timeline_activity_precondition_review",
               "source" => "timeline_activity_precondition_summary.summary",
               "subject_id" => "timeline:cmd_preflight",
               "timeline_id" => "timeline:cmd_preflight",
               "activity_id" => "cmd_preflight",
               "activity_type" => "command",
               "precondition_status" => "blocked",
               "blocked_precondition_count" => 2,
               "review_precondition_count" => 1,
               "blocked_precondition_types" => [
                 "payload_unavailable",
                 "resource_block_declared"
               ],
               "review_precondition_types" => ["degraded_mode"],
               "dependency_activity_ids" => ["health_check_1", "obs_1"],
               "dependency_timeline_ids" => ["timeline:health_check_1"],
               "exclusive_with_activity_ids" => ["dl_conflict"],
               "exclusive_with_timeline_ids" => ["timeline:dl_conflict"],
               "duplicate_dependency_activity_ids" => ["obs_1"],
               "duplicate_dependency_timeline_ids" => ["timeline:health_check_1"],
               "duplicate_exclusivity_activity_ids" => ["dl_conflict"],
               "duplicate_exclusivity_timeline_ids" => ["timeline:dl_conflict"],
               "allow_overlap" => true,
               "required_operator_action" => "review_blocked_activity_precondition",
               "approval_status" => "operator_review_required",
               "operator_action_reason" => "blocked_activity_precondition",
               "source_timeline_activity_precondition_summary" => %{
                 "schema_contract" => "timeline_activity_precondition_summary.v1",
                 "precondition_status" => "blocked",
                 "duplicate_dependency_activity_ids" => ["obs_1"],
                 "duplicate_exclusivity_activity_ids" => ["dl_conflict"],
                 "allow_overlap" => true
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

    invalid_source =
      put_in(
        package,
        [
          "rows",
          Access.at(0),
          "source_timeline_activity_precondition_summary",
          "timeline_id"
        ],
        "bad timeline id"
      )

    assert {:error, invalid_source_report} = Schema.validate_artifact(invalid_source)

    assert Enum.any?(
             invalid_source_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_timeline_activity_precondition_summary.timeline_id")
           )
  end

  test "timeline activity precondition source id falls back through timeline and default" do
    assert %{"source_artifact_id" => "precondition:001"} =
             OperatorReview.from_timeline_activity_precondition_summary(%{
               id: :"precondition:001",
               timeline_id: :"timeline:precondition",
               activity_id: :cmd_precondition
             })

    assert %{"source_artifact_id" => "timeline:precondition"} =
             OperatorReview.from_timeline_activity_precondition_summary(%{
               timeline_id: :"timeline:precondition",
               activity_id: :cmd_precondition
             })

    assert %{"source_artifact_id" => "timeline_activity_precondition_summary"} =
             OperatorReview.from_timeline_activity_precondition_summary(%{})
  end

  test "candidate refresh artifacts surface timeline activity precondition summaries" do
    summary =
      Timeline.activity_precondition_summary(%{
        id: :cmd_preflight,
        type: :command,
        payload_available: false,
        dependency_activity_ids: [:health_check_1],
        dependency_timeline_ids: [:"timeline:health_check_1"],
        exclusive_with_activity_ids: [:dl_conflict],
        exclusive_with_timeline_ids: [:"timeline:dl_conflict"],
        allow_overlap: true,
        metadata: %{timeline_id: :"timeline:cmd_preflight"}
      })

    invalid_summary = Timeline.activity_precondition_summary(%{id: :bad_missing_type})

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:precondition_handoff",
      "source_timeline_activity_precondition_summary" => [summary],
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "timeline_activity_precondition_summary" => invalid_summary
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:precondition_handoff",
             "review_count" => 2,
             "timeline_activity_precondition_review_count" => 2,
             "required_operator_action_counts" => %{
               "review_blocked_activity_precondition" => 1,
               "review_invalid_activity_input" => 1
             }
           } = package

    assert [
             %{
               "source" =>
                 "candidate_refresh.source_timeline_activity_precondition_summary[0].summary",
               "required_operator_action" => "review_blocked_activity_precondition",
               "dependency_activity_ids" => ["health_check_1"],
               "exclusive_with_activity_ids" => ["dl_conflict"],
               "allow_overlap" => true
             },
             %{
               "source" =>
                 "candidate_refresh.source_result_artifact[0].timeline_activity_precondition_summary.summary",
               "required_operator_action" => "review_invalid_activity_input",
               "invalid_activity_input" => true,
               "source_timeline_activity_precondition_summary" => %{
                 "invalid_activity_input" => true,
                 "invalid_activity_input_reason" => "missing_activity_type"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "CandidateRefresh lifts accepted planning state precondition summaries" do
    summary =
      Timeline.activity_precondition_summary(%{
        id: :cmd_accepted_preflight,
        type: :command,
        payload_available: false,
        dependency_activity_ids: [:health_check_1],
        dependency_timeline_ids: [:"timeline:health_check_1"],
        exclusive_with_activity_ids: [:dl_conflict],
        exclusive_with_timeline_ids: [:"timeline:dl_conflict"],
        allow_overlap: true,
        metadata: %{timeline_id: :"timeline:cmd_accepted_preflight"}
      })

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:accepted_precondition_handoff",
      "accepted_planning_state" => %{
        "source_timeline_activity_precondition_summary" => summary
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:accepted_precondition_handoff",
             "review_count" => 1,
             "timeline_activity_precondition_review_count" => 1,
             "review_type_counts" => %{"timeline_activity_precondition_review" => 1},
             "required_operator_action_counts" => %{
               "review_blocked_activity_precondition" => 1
             }
           } = review

    assert [
             %{
               "review_type" => "timeline_activity_precondition_review",
               "source" =>
                 "candidate_refresh.accepted_planning_state.source_timeline_activity_precondition_summary.summary",
               "timeline_id" => "timeline:cmd_accepted_preflight",
               "activity_id" => "cmd_accepted_preflight",
               "precondition_status" => "blocked",
               "required_operator_action" => "review_blocked_activity_precondition",
               "dependency_activity_ids" => ["health_check_1"],
               "exclusive_with_activity_ids" => ["dl_conflict"],
               "allow_overlap" => true,
               "source_timeline_activity_precondition_summary" => %{
                 "schema_contract" => "timeline_activity_precondition_summary.v1",
                 "timeline_id" => "timeline:cmd_accepted_preflight",
                 "precondition_status" => "blocked"
               }
             }
           ] = review["rows"]

    assert %{
             "row_count" => 1,
             "import_action_counts" => %{"review_timeline_precondition" => 1},
             "source_review_type_counts" => %{"timeline_activity_precondition_review" => 1}
           } = import

    assert [
             %{
               "import_action" => "review_timeline_precondition",
               "source_review_type" => "timeline_activity_precondition_review",
               "timeline_id" => "timeline:cmd_accepted_preflight",
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.accepted_planning_state.source_timeline_activity_precondition_summary.summary",
                 "source_timeline_activity_precondition_summary" => %{
                   "timeline_id" => "timeline:cmd_accepted_preflight"
                 }
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "CandidateRefresh lifts mission state precondition summaries" do
    summary =
      Timeline.activity_precondition_summary(%{
        id: :cmd_mission_preflight,
        type: :command,
        degraded: true,
        dependency_activity_ids: [:mission_health_check],
        dependency_timeline_ids: [:"timeline:mission_health_check"],
        metadata: %{timeline_id: :"timeline:cmd_mission_preflight"}
      })

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:mission_precondition_handoff",
      "mission_state" => %{
        "timeline_activity_precondition_summary" => summary
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:mission_precondition_handoff",
             "review_count" => 1,
             "timeline_activity_precondition_review_count" => 1
           } = review

    assert [
             %{
               "review_type" => "timeline_activity_precondition_review",
               "source" =>
                 "candidate_refresh.mission_state.timeline_activity_precondition_summary.summary",
               "timeline_id" => "timeline:cmd_mission_preflight",
               "activity_id" => "cmd_mission_preflight",
               "precondition_status" => "review_required",
               "required_operator_action" => "review_activity_precondition",
               "dependency_activity_ids" => ["mission_health_check"],
               "source_timeline_activity_precondition_summary" => %{
                 "schema_contract" => "timeline_activity_precondition_summary.v1",
                 "timeline_id" => "timeline:cmd_mission_preflight",
                 "precondition_status" => "review_required"
               }
             }
           ] = review["rows"]

    assert %{
             "row_count" => 1,
             "import_action_counts" => %{"review_timeline_precondition" => 1},
             "source_review_type_counts" => %{"timeline_activity_precondition_review" => 1}
           } = import

    assert [
             %{
               "import_action" => "review_timeline_precondition",
               "source_review_type" => "timeline_activity_precondition_review",
               "timeline_id" => "timeline:cmd_mission_preflight",
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.mission_state.timeline_activity_precondition_summary.summary",
                 "source_timeline_activity_precondition_summary" => %{
                   "timeline_id" => "timeline:cmd_mission_preflight"
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
