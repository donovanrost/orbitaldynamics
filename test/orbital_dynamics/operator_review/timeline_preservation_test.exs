defmodule OrbitalDynamics.OperatorReview.TimelinePreservationTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema, Timeline}

  test "timeline preservation artifacts become operator review rows" do
    activities = [
      %{id: :cmd_mutable, type: :command, status: :planned, approval_status: :pending},
      %{id: :contact_locked, type: :planned_contact, locked: true, approval_status: :pending},
      %{id: :obs_done, type: :observe, status: :completed},
      %{id: :bad_missing_type, status: :planned}
    ]

    report = Timeline.preservation_report(activities, source: "selected_activities")
    package = OperatorReview.from_timeline_preservation_report(report)

    atom_key_report =
      report
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()

    status = Timeline.preservation_status(%{id: :bad_missing_type, status: :planned})

    atom_key_status =
      status
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_preservation_report.v1",
             "source_artifact_id" => "selected_activities",
             "review_count" => 3,
             "timeline_preservation_review_count" => 3,
             "required_operator_action_counts" => %{
               "record_timeline_preservation" => 2,
               "review_timeline_preservation" => 1
             },
             "review_type_counts" => %{"timeline_preservation_review" => 3}
           } = package

    assert [
             %{
               "review_type" => "timeline_preservation_review",
               "source" => "timeline_preservation_report.rows",
               "subject_id" => "timeline:planned_contact",
               "timeline_id" => "timeline:planned_contact",
               "activity_id" => "contact_locked",
               "timeline_preservation_status" => "preservation_required",
               "requires_preservation" => true,
               "requires_operator_review" => false,
               "required_operator_action" => "record_timeline_preservation",
               "approval_status" => "not_required",
               "timeline_preservation_protection_decision" => "preserve",
               "timeline_preservation_protection_category" => "locked_or_approved",
               "timeline_preservation_protection_reason" => "activity_locked_or_approved",
               "preserve_activity_count" => 2,
               "review_change_activity_count" => 1,
               "preservation_sensitive_activity_count" => 3,
               "source_preservation_protection_category_counts" => %{
                 "executed" => 1,
                 "invalid_activity_input" => 1,
                 "locked_or_approved" => 1,
                 "none" => 1
               },
               "source_preservation_activity_id_sets_by_protection_category" => %{
                 "executed" => ["obs_done"],
                 "invalid_activity_input" => ["bad_missing_type"],
                 "locked_or_approved" => ["contact_locked"],
                 "none" => ["cmd_mutable"]
               },
               "source_preservation_timeline_id_sets_by_protection_category" => %{
                 "executed" => ["timeline:observe"],
                 "invalid_activity_input" => ["timeline:invalid_activity_input:bad_missing_type"],
                 "locked_or_approved" => ["timeline:planned_contact"],
                 "none" => ["timeline:command"]
               },
               "source_timeline_preservation" => %{
                 "activity_id" => "contact_locked",
                 "protection_decision" => "preserve"
               }
             },
             %{
               "activity_id" => "obs_done",
               "timeline_id" => "timeline:observe",
               "timeline_preservation_status" => "preservation_required",
               "required_operator_action" => "record_timeline_preservation",
               "approval_status" => "not_required",
               "timeline_preservation_protection_category" => "executed"
             },
             %{
               "activity_id" => "bad_missing_type",
               "timeline_id" => "timeline:invalid_activity_input:bad_missing_type",
               "timeline_preservation_status" => "review_required",
               "requires_operator_review" => true,
               "required_operator_action" => "review_timeline_preservation",
               "approval_status" => "operator_review_required",
               "timeline_preservation_protection_decision" => "review_change",
               "invalid_activity_input" => true
             }
           ] = package["rows"]

    assert OrbitalDynamics.operator_review_package(report) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(report, "schema_contract")) ==
             package

    assert OrbitalDynamics.operator_review_package(atom_key_report) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(atom_key_report, :schema_contract)) ==
             package

    status_package = OrbitalDynamics.operator_review_package(atom_key_status)

    assert OrbitalDynamics.operator_review_package(status) == status_package

    assert OrbitalDynamics.operator_review_package(Map.delete(status, "schema_contract")) ==
             status_package

    assert %{
             "source_artifact_type" => "timeline_preservation_status.v1",
             "source_artifact_id" => "timeline:invalid_activity_input:bad_missing_type",
             "review_count" => 1,
             "timeline_preservation_review_count" => 1
           } = status_package

    assert [
             %{
               "timeline_preservation_status" => "review_required",
               "required_operator_action" => "review_timeline_preservation",
               "source_timeline_preservation" => %{
                 "schema_contract" => "timeline_preservation_status.v1"
               }
             }
           ] = status_package["rows"]

    assert OrbitalDynamics.operator_review_package(Map.delete(atom_key_status, :schema_contract)) ==
             status_package

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_preservation =
      put_in(
        package,
        ["rows", Access.at(0), "source_timeline_preservation", "activity_id"],
        "bad activity id"
      )

    assert {:error, invalid_source_preservation_report} =
             Schema.validate_artifact(invalid_source_preservation)

    assert Enum.any?(
             invalid_source_preservation_report["errors"],
             &(&1["path"] == "$.rows[0].source_timeline_preservation.activity_id" and
                 &1["message"] =~ "stable ID")
           )
  end

  test "timeline preservation report and status source ids fall back through defaults" do
    assert %{"source_artifact_id" => "preservation:report"} =
             OperatorReview.from_timeline_preservation_report(%{
               id: :"preservation:report",
               rows: []
             })

    assert %{"source_artifact_id" => "timeline_preservation_report"} =
             OperatorReview.from_timeline_preservation_report(%{rows: []})

    assert %{"source_artifact_id" => "preservation:status"} =
             OperatorReview.from_timeline_preservation_status(%{id: :"preservation:status"})

    assert %{"source_artifact_id" => "timeline_preservation_status"} =
             OperatorReview.from_timeline_preservation_status(%{})
  end

  test "CandidateRefresh lifts accepted planning state preservation reports" do
    report =
      Timeline.preservation_report(
        [
          %{
            id: :cmd_accepted_preserve,
            type: :command,
            status: :planned,
            approval_status: :approved,
            metadata: %{timeline_id: :"timeline:cmd_accepted_preserve"}
          }
        ],
        source: "accepted_state.timeline_preservation_report"
      )

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:accepted_preservation_handoff",
      "accepted_planning_state" => %{
        "source_timeline_preservation_report" => report
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:accepted_preservation_handoff",
             "review_count" => 1,
             "timeline_preservation_review_count" => 1,
             "review_type_counts" => %{"timeline_preservation_review" => 1},
             "required_operator_action_counts" => %{"record_timeline_preservation" => 1}
           } = review

    assert [
             %{
               "review_type" => "timeline_preservation_review",
               "source" =>
                 "candidate_refresh.accepted_planning_state.source_timeline_preservation_report.rows",
               "timeline_id" => "timeline:cmd_accepted_preserve",
               "activity_id" => "cmd_accepted_preserve",
               "timeline_preservation_status" => "preservation_required",
               "required_operator_action" => "record_timeline_preservation",
               "approval_status" => "not_required",
               "source_timeline_preservation" => %{
                 "activity_id" => "cmd_accepted_preserve",
                 "protection_decision" => "preserve"
               }
             }
           ] = review["rows"]

    assert %{
             "row_count" => 1,
             "import_action_counts" => %{"review_timeline_preservation" => 1},
             "source_review_type_counts" => %{"timeline_preservation_review" => 1}
           } = import

    assert [
             %{
               "import_action" => "review_timeline_preservation",
               "source_review_type" => "timeline_preservation_review",
               "timeline_id" => "timeline:cmd_accepted_preserve",
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.accepted_planning_state.source_timeline_preservation_report.rows",
                 "source_timeline_preservation" => %{
                   "activity_id" => "cmd_accepted_preserve",
                   "protection_decision" => "preserve"
                 }
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "CandidateRefresh lifts mission state preservation statuses" do
    status =
      Timeline.preservation_status(%{
        id: :cmd_mission_preservation_review,
        status: :planned
      })

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:mission_preservation_status_handoff",
      "mission_state" => %{
        "timeline_preservation_status" => status
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:mission_preservation_status_handoff",
             "review_count" => 1,
             "timeline_preservation_review_count" => 1,
             "review_type_counts" => %{"timeline_preservation_review" => 1},
             "required_operator_action_counts" => %{"review_timeline_preservation" => 1}
           } = review

    assert [
             %{
               "review_type" => "timeline_preservation_review",
               "source" => "candidate_refresh.mission_state.timeline_preservation_status.status",
               "timeline_id" => "timeline:invalid_activity_input:cmd_mission_preservation_review",
               "activity_id" => "cmd_mission_preservation_review",
               "timeline_preservation_status" => "review_required",
               "required_operator_action" => "review_timeline_preservation",
               "approval_status" => "operator_review_required",
               "invalid_activity_input" => true,
               "source_timeline_preservation" => %{
                 "schema_contract" => "timeline_preservation_status.v1",
                 "invalid_activity_input" => true
               }
             }
           ] = review["rows"]

    assert %{
             "row_count" => 1,
             "import_action_counts" => %{"review_timeline_preservation" => 1},
             "source_review_type_counts" => %{"timeline_preservation_review" => 1}
           } = import

    assert [
             %{
               "import_action" => "review_timeline_preservation",
               "source_review_type" => "timeline_preservation_review",
               "timeline_id" => "timeline:invalid_activity_input:cmd_mission_preservation_review",
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.mission_state.timeline_preservation_status.status",
                 "source_timeline_preservation" => %{
                   "schema_contract" => "timeline_preservation_status.v1",
                   "invalid_activity_input" => true
                 }
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "CandidateRefresh lifts all nested preservation source paths" do
    report =
      Timeline.preservation_report(
        [
          %{
            id: :cmd_nested_preserve,
            type: :command,
            status: :planned,
            approval_status: :approved,
            metadata: %{timeline_id: :"timeline:cmd_nested_preserve"}
          }
        ],
        source: "nested.timeline_preservation_report"
      )

    status =
      Timeline.preservation_status(%{
        id: :cmd_nested_preservation_review,
        status: :planned
      })

    cases = [
      {"accepted_planning_state", "source_timeline_preservation_report", report, ".rows",
       %{
         "activity_id" => "cmd_nested_preserve",
         "timeline_id" => "timeline:cmd_nested_preserve",
         "operator_action" => "record_timeline_preservation",
         "evidence" => %{"activity_id" => "cmd_nested_preserve"}
       }},
      {"accepted_planning_state", "timeline_preservation_report", report, ".rows",
       %{
         "activity_id" => "cmd_nested_preserve",
         "timeline_id" => "timeline:cmd_nested_preserve",
         "operator_action" => "record_timeline_preservation",
         "evidence" => %{"activity_id" => "cmd_nested_preserve"}
       }},
      {"accepted_planning_state", "source_timeline_preservation_status", status, ".status",
       %{
         "activity_id" => "cmd_nested_preservation_review",
         "timeline_id" => "timeline:invalid_activity_input:cmd_nested_preservation_review",
         "operator_action" => "review_timeline_preservation",
         "evidence" => %{
           "schema_contract" => "timeline_preservation_status.v1",
           "invalid_activity_input" => true
         }
       }},
      {"accepted_planning_state", "timeline_preservation_status", status, ".status",
       %{
         "activity_id" => "cmd_nested_preservation_review",
         "timeline_id" => "timeline:invalid_activity_input:cmd_nested_preservation_review",
         "operator_action" => "review_timeline_preservation",
         "evidence" => %{
           "schema_contract" => "timeline_preservation_status.v1",
           "invalid_activity_input" => true
         }
       }},
      {"mission_state", "source_timeline_preservation_report", report, ".rows",
       %{
         "activity_id" => "cmd_nested_preserve",
         "timeline_id" => "timeline:cmd_nested_preserve",
         "operator_action" => "record_timeline_preservation",
         "evidence" => %{"activity_id" => "cmd_nested_preserve"}
       }},
      {"mission_state", "timeline_preservation_report", report, ".rows",
       %{
         "activity_id" => "cmd_nested_preserve",
         "timeline_id" => "timeline:cmd_nested_preserve",
         "operator_action" => "record_timeline_preservation",
         "evidence" => %{"activity_id" => "cmd_nested_preserve"}
       }},
      {"mission_state", "source_timeline_preservation_status", status, ".status",
       %{
         "activity_id" => "cmd_nested_preservation_review",
         "timeline_id" => "timeline:invalid_activity_input:cmd_nested_preservation_review",
         "operator_action" => "review_timeline_preservation",
         "evidence" => %{
           "schema_contract" => "timeline_preservation_status.v1",
           "invalid_activity_input" => true
         }
       }},
      {"mission_state", "timeline_preservation_status", status, ".status",
       %{
         "activity_id" => "cmd_nested_preservation_review",
         "timeline_id" => "timeline:invalid_activity_input:cmd_nested_preservation_review",
         "operator_action" => "review_timeline_preservation",
         "evidence" => %{
           "schema_contract" => "timeline_preservation_status.v1",
           "invalid_activity_input" => true
         }
       }}
    ]

    Enum.each(cases, fn {state_key, field, payload, source_suffix, expected} ->
      source = "candidate_refresh.#{state_key}.#{field}#{source_suffix}"

      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "refresh_id" => "refresh:#{state_key}:#{field}",
        state_key => %{field => payload}
      }

      review = OperatorReview.from_candidate_refresh_artifact(artifact)
      import = CadenceImport.from_candidate_refresh_artifact(artifact)

      assert %{
               "review_count" => 1,
               "timeline_preservation_review_count" => 1,
               "review_type_counts" => %{"timeline_preservation_review" => 1}
             } = review

      assert [
               %{
                 "review_type" => "timeline_preservation_review",
                 "source" => ^source,
                 "timeline_id" => expected_timeline_id,
                 "activity_id" => expected_activity_id,
                 "required_operator_action" => expected_operator_action,
                 "source_timeline_preservation" => source_evidence
               }
             ] = review["rows"]

      assert expected_timeline_id == expected["timeline_id"]
      assert expected_activity_id == expected["activity_id"]
      assert expected_operator_action == expected["operator_action"]
      assert Map.take(source_evidence, Map.keys(expected["evidence"])) == expected["evidence"]

      assert %{
               "row_count" => 1,
               "import_action_counts" => %{"review_timeline_preservation" => 1},
               "source_review_type_counts" => %{"timeline_preservation_review" => 1}
             } = import

      assert [
               %{
                 "import_action" => "review_timeline_preservation",
                 "source_review_type" => "timeline_preservation_review",
                 "timeline_id" => ^expected_timeline_id,
                 "source_review_row" => %{
                   "source" => ^source,
                   "source_timeline_preservation" => import_source_evidence
                 }
               }
             ] = import["rows"]

      assert Map.take(import_source_evidence, Map.keys(expected["evidence"])) ==
               expected["evidence"]
    end)
  end
end
