defmodule OrbitalDynamics.TimelineLifecycleStateTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Timeline}

  test "builds reusable status and approval transition helpers" do
    source = %{
      id: :obs_1,
      type: :observe,
      status: :planned,
      approval_status: :pending,
      metadata: %{timeline_id: :"timeline:obs_1"}
    }

    replacement = %{
      id: :obs_1b,
      type: :observe,
      status: :completed,
      approval_status: :approved,
      metadata: %{timeline_id: :"timeline:obs_1"}
    }

    assert %{
             "status_transition" => %{
               "field" => "status",
               "transition_type" => "changed",
               "from" => "planned",
               "to" => "completed",
               "from_category" => "planned",
               "to_category" => "executed",
               "transition_category" => "execution_recorded",
               "requires_operator_review" => false,
               "operator_action_reason" => "activity_execution_recorded"
             },
             "approval_transition" => %{
               "field" => "approval_status",
               "transition_type" => "changed",
               "from" => "pending",
               "to" => "approved",
               "from_category" => "review_required",
               "to_category" => "protected",
               "transition_category" => "approval_granted",
               "requires_operator_review" => true,
               "operator_action_reason" => "approval_grant_requires_operator_authority"
             }
           } = Timeline.activity_transition(source, replacement)

    assert %{
             "field" => "status",
             "transition_type" => "added",
             "to" => "planned",
             "to_category" => "planned",
             "transition_category" => "status_added",
             "requires_operator_review" => false
           } = Timeline.status_transition(nil, %{id: :new_cmd, type: :command})

    assert %{
             "field" => "approval_status",
             "transition_type" => "removed",
             "from" => "approved",
             "from_category" => "protected",
             "transition_category" => "protected_approval_removed",
             "requires_operator_review" => true,
             "operator_action_reason" => "protected_approval_removed"
           } = Timeline.approval_transition(%{id: :old_cmd, approval_status: :approved}, nil)

    assert %{
             "transition_category" => "executed_activity_changed",
             "requires_operator_review" => true,
             "operator_action_reason" => "executed_status_changed"
           } =
             Timeline.status_transition(%{id: :done, status: :completed}, %{
               id: :done,
               status: :planned
             })

    assert %{
             "transition_category" => "status_blocked",
             "from_category" => "planned",
             "to_category" => "blocked",
             "requires_operator_review" => true,
             "operator_action_reason" => "activity_status_blocked_by_policy"
           } =
             Timeline.status_transition(%{id: :cmd_policy, status: :planned}, %{
               id: :cmd_policy,
               status: :blocked_by_policy
             })

    assert %{
             "transition_category" => "status_block_cleared",
             "from_category" => "blocked",
             "to_category" => "planned",
             "requires_operator_review" => true,
             "operator_action_reason" => "blocked_status_cleared"
           } =
             Timeline.status_transition(%{id: :cmd_policy, status: :blocked_by_policy}, %{
               id: :cmd_policy,
               status: :planned
             })

    assert %{
             "transition_category" => "approval_regressed",
             "requires_operator_review" => true,
             "operator_action_reason" => "protected_approval_regressed"
           } =
             Timeline.approval_transition(
               %{id: :approved, approval_status: :approved},
               %{id: :approved, approval_status: :pending}
             )

    assert %{
             "transition_category" => "approval_blocked",
             "requires_operator_review" => true,
             "operator_action_reason" => "approval_blocked_by_policy"
           } =
             Timeline.approval_transition(
               %{id: :pending_cmd, approval_status: :pending},
               %{id: :pending_cmd, approval_status: :blocked_by_policy}
             )

    assert is_nil(
             Timeline.status_transition(
               %{id: :done, status: " Completed "},
               %{id: :done, status: :completed}
             )
           )

    assert %{
             "field" => "status",
             "transition_type" => "changed",
             "from" => "provider_magic",
             "from_category" => "other",
             "to" => "planned",
             "to_category" => "planned",
             "transition_category" => "unsupported_status",
             "requires_operator_review" => true,
             "operator_action_reason" => "unsupported_source_status"
           } =
             Timeline.status_transition(
               %{id: :provider_cmd, status: "provider magic"},
               %{id: :provider_cmd, status: :planned}
             )

    assert %{
             "transition_category" => "unsupported_status",
             "requires_operator_review" => true,
             "operator_action_reason" => "unsupported_replacement_status"
           } =
             Timeline.status_transition(
               %{id: :provider_cmd, status: :planned},
               %{id: :provider_cmd, status: "provider magic"}
             )

    assert is_nil(
             Timeline.approval_transition(
               %{id: :approved, approval_status: " APPROVED "},
               %{id: :approved, approval_status: :approved}
             )
           )

    assert is_nil(
             Timeline.approval_transition(
               %{id: :review, approval_status: "operator review required"},
               %{id: :review, approval_status: :operator_review_required}
             )
           )

    assert %{
             "field" => "approval_status",
             "transition_type" => "changed",
             "from" => "provider_magic",
             "from_category" => "other",
             "to" => "approved",
             "to_category" => "protected",
             "transition_category" => "unsupported_approval_status",
             "requires_operator_review" => true,
             "operator_action_reason" => "unsupported_source_approval_status"
           } =
             Timeline.approval_transition(
               %{id: :provider_cmd, approval_status: "provider magic"},
               %{id: :provider_cmd, approval_status: :approved}
             )

    assert %{
             "transition_category" => "unsupported_approval_status",
             "requires_operator_review" => true,
             "operator_action_reason" => "unsupported_replacement_approval_status"
           } =
             Timeline.approval_transition(
               %{id: :provider_cmd, approval_status: :pending},
               %{id: :provider_cmd, approval_status: "provider magic"}
             )

    assert OrbitalDynamics.timeline_activity_transition(source, replacement) ==
             Timeline.activity_transition(source, replacement)

    assert OrbitalDynamics.timeline_status_transition(source, replacement) ==
             Timeline.status_transition(source, replacement)

    assert OrbitalDynamics.timeline_approval_transition(source, replacement) ==
             Timeline.approval_transition(source, replacement)
  end

  test "applies safe timeline activity status and approval transitions" do
    activity = %{
      id: :cmd_transition,
      type: :command,
      scenario_id: :leo_1,
      status: "In Progress",
      approval_status: :pending,
      metadata: %{
        timeline_id: :"timeline:cmd_transition",
        source_window_id: :"window:cmd_transition"
      }
    }

    assert {:ok,
            %{
              "activity_id" => "cmd_transition",
              "activity_type" => "command",
              "status" => "completed",
              "approval_status" => "pending",
              "timeline_id" => "timeline:cmd_transition",
              "source_window_id" => "window:cmd_transition",
              "activity_context" => %{
                "status" => "completed",
                "approval_status" => "pending",
                "timeline_identity" => %{
                  "activity_id" => "cmd_transition",
                  "timeline_id" => "timeline:cmd_transition",
                  "source_window_id" => "window:cmd_transition"
                }
              }
            } = completed} = Timeline.transition_activity_status(activity, "succeeded")

    assert completed == Timeline.transition_activity_status!(activity, "succeeded")

    assert %{
             "helper" => "transition_activity_status",
             "field" => "status",
             "transition_type" => "changed",
             "from" => "executing",
             "to" => "completed",
             "requires_operator_review" => false
           } = completed["transition_application_provenance"]

    assert completed["activity_context"]["transition_application_provenance"] ==
             completed["transition_application_provenance"]

    assert OrbitalDynamics.timeline_transition_activity_status(activity, "succeeded") ==
             {:ok, completed}

    assert OrbitalDynamics.timeline_transition_activity_status!(activity, "succeeded") ==
             completed

    assert {:ok,
            %{
              "activity_id" => "cmd_transition",
              "status" => "executing",
              "approval_status" => "not_required",
              "timeline_id" => "timeline:cmd_transition",
              "activity_context" => %{
                "approval_status" => "not_required",
                "timeline_identity" => %{"timeline_id" => "timeline:cmd_transition"}
              }
            } = no_review_required} =
             Timeline.transition_activity_approval_status(activity, "No Review Required")

    assert no_review_required ==
             Timeline.transition_activity_approval_status!(activity, "No Review Required")

    assert %{
             "helper" => "transition_activity_approval_status",
             "field" => "approval_status",
             "transition_type" => "changed",
             "from" => "pending",
             "to" => "not_required",
             "requires_operator_review" => false
           } = no_review_required["transition_application_provenance"]

    assert OrbitalDynamics.timeline_transition_activity_approval_status(
             activity,
             "No Review Required"
           ) == {:ok, no_review_required}

    assert OrbitalDynamics.timeline_transition_activity_approval_status!(
             activity,
             "No Review Required"
           ) == no_review_required

    assert {:ok,
            %{
              "activity_id" => "cmd_transition",
              "status" => "completed",
              "approval_status" => "pending",
              "timeline_id" => "timeline:cmd_transition",
              "activity_context" => %{
                "status" => "completed",
                "timeline_identity" => %{"timeline_id" => "timeline:cmd_transition"}
              }
            } = lifecycle_completed} =
             Timeline.apply_lifecycle_event(activity, "record completion")

    assert lifecycle_completed == Timeline.apply_lifecycle_event!(activity, "record completion")

    assert %{
             "helper" => "apply_lifecycle_event",
             "field" => "status",
             "transition_type" => "changed",
             "from" => "executing",
             "to" => "completed",
             "requires_operator_review" => false
           } = lifecycle_provenance = lifecycle_completed["transition_application_provenance"]

    assert lifecycle_completed["activity_context"]["transition_application_provenance"] ==
             lifecycle_provenance

    assert OrbitalDynamics.timeline_apply_lifecycle_event(activity, "record completion") ==
             {:ok, lifecycle_completed}

    assert OrbitalDynamics.timeline_apply_lifecycle_event!(activity, "record completion") ==
             lifecycle_completed

    assert %{
             "transition_decision" => "record",
             "application_status" => "replacement_recorded",
             "transition_application_provenance" => ^lifecycle_provenance,
             "selected_activity" => %{
               "activity_id" => "cmd_transition",
               "status" => "completed",
               "transition_application_provenance" => ^lifecycle_provenance
             }
           } = Timeline.transition_application(activity, lifecycle_completed)

    forged_lifecycle_completed = Map.put(lifecycle_completed, "locked", true)
    forged_application = Timeline.transition_application(activity, forged_lifecycle_completed)

    refute forged_application["application_status"] == "replacement_recorded"
    refute Map.has_key?(forged_application, "transition_application_provenance")

    forged_approval_completed = Map.put(lifecycle_completed, "approval_status", "not_required")

    forged_approval_application =
      Timeline.transition_application(activity, forged_approval_completed)

    refute forged_approval_application["application_status"] == "replacement_recorded"
    refute Map.has_key?(forged_approval_application, "transition_application_provenance")

    completed_activity = Map.put(activity, :status, :completed)

    assert {:error,
            %{
              "transition_category" => "executed_activity_changed",
              "requires_operator_review" => true,
              "operator_action_reason" => "executed_status_changed"
            }} = Timeline.transition_activity_status(completed_activity, :planned)

    assert_raise ArgumentError,
                 ~r/unsafe timeline activity status transition completed -> planned/,
                 fn ->
                   Timeline.transition_activity_status!(completed_activity, :planned)
                 end

    assert {:error,
            %{
              "field" => "status",
              "transition_category" => "executed_activity_changed",
              "requires_operator_review" => true,
              "operator_action_reason" => "executed_status_changed"
            }} = Timeline.apply_lifecycle_event(completed_activity, "record partial")

    assert_raise ArgumentError,
                 ~r/unsafe timeline activity lifecycle event status transition completed -> partial/,
                 fn ->
                   Timeline.apply_lifecycle_event!(completed_activity, "record partial")
                 end

    assert {:error,
            %{
              "field" => "approval_status",
              "transition_category" => "approval_granted",
              "requires_operator_review" => true,
              "operator_action_reason" => "approval_grant_requires_operator_authority"
            }} = Timeline.apply_lifecycle_event(activity, "lock")

    assert_raise ArgumentError,
                 ~r/unsafe timeline activity lifecycle event approval_status transition pending -> locked/,
                 fn ->
                   Timeline.apply_lifecycle_event!(activity, "lock")
                 end

    assert {:error,
            %{
              "field" => "status",
              "transition_category" => "invalid_activity_input",
              "requires_operator_review" => true,
              "operator_action_reason" => "invalid_activity_input"
            }} = Timeline.apply_lifecycle_event(%{id: :missing_type}, "record completion")

    assert {:error,
            %{
              "transition_category" => "approval_granted",
              "requires_operator_review" => true,
              "operator_action_reason" => "approval_grant_requires_operator_authority"
            }} = Timeline.transition_activity_approval_status(activity, :approved)

    assert_raise ArgumentError,
                 ~r/unsafe timeline activity approval transition pending -> approved/,
                 fn ->
                   Timeline.transition_activity_approval_status!(activity, :approved)
                 end

    assert {:error,
            %{
              "transition_category" => "invalid_activity_input",
              "operator_action_reason" => "invalid_activity_input"
            }} = Timeline.transition_activity_status(activity, "provider magic")
  end

  test "direct lifecycle helpers can gate selected activity integrity" do
    activity = %{
      id: :cmd_waiting_on_gate,
      type: :command,
      scenario_id: :leo_1,
      status: :executing,
      approval_status: :pending,
      starts_at_s: 10.0,
      ends_at_s: 20.0,
      depends_on: [:missing_gate],
      metadata: %{timeline_id: :"timeline:cmd_waiting_on_gate"}
    }

    assert {:ok, completed} = Timeline.transition_activity_status(activity, "succeeded")
    refute Map.has_key?(completed, "timeline_integrity_status")

    assert {:ok, completed_without_dependency_check} =
             Timeline.transition_activity_status(activity, "succeeded",
               validate_selected_integrity?: true,
               validate_selected_dependencies?: false
             )

    refute Map.has_key?(completed_without_dependency_check, "timeline_integrity_status")

    assert {:error,
            %{
              "field" => "timeline_integrity",
              "transition_category" => "selected_timeline_integrity_review_required",
              "requires_operator_review" => true,
              "required_operator_action" => "review_timeline_integrity",
              "operator_action_reason" =>
                "selected_timeline_integrity_issue_requires_review:missing_dependency_activity",
              "selected_timeline_integrity_status" => "review_required",
              "selected_timeline_integrity_issue_count" => 1,
              "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"],
              "selected_missing_dependency_activity_ids" => ["missing_gate"]
            }} =
             Timeline.transition_activity_status(activity, "succeeded",
               validate_selected_integrity?: true
             )

    assert_raise ArgumentError,
                 ~r/unsafe timeline activity selected integrity: selected_timeline_integrity_issue_requires_review:missing_dependency_activity/,
                 fn ->
                   Timeline.transition_activity_status!(activity, "succeeded",
                     validate_selected_integrity?: true
                   )
                 end

    assert {:error,
            %{
              "field" => "timeline_integrity",
              "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"]
            }} =
             Timeline.transition_activity_approval_status(activity, "No Review Required",
               validate_selected_integrity?: true
             )

    lifecycle_error =
      Timeline.apply_lifecycle_event(activity, "record completion",
        validate_selected_integrity?: true
      )

    assert {:error,
            %{
              "field" => "timeline_integrity",
              "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"]
            }} = lifecycle_error

    assert OrbitalDynamics.timeline_apply_lifecycle_event(activity, "record completion",
             validate_selected_integrity?: true
           ) == lifecycle_error

    duplicate_exclusivity_activity =
      activity
      |> Map.delete(:depends_on)
      |> Map.put(:id, :cmd_duplicate_exclusivity)
      |> Map.put(:exclusive_with_activity_ids, [:dl_clear, :dl_clear])
      |> put_in([:metadata, :timeline_id], :"timeline:cmd_duplicate_exclusivity")

    assert {:error,
            %{
              "field" => "timeline_integrity",
              "required_operator_action" => "review_timeline_integrity",
              "selected_timeline_integrity_issue_count" => 1,
              "selected_timeline_integrity_issue_types" => [
                "duplicate_exclusivity_activity"
              ],
              "selected_timeline_integrity_issues" => [
                %{
                  "type" => "duplicate_exclusivity_activity",
                  "duplicate_exclusivity_activity_id" => "dl_clear"
                }
              ],
              "selected_duplicate_exclusivity_activity_ids" => ["dl_clear"]
            }} =
             Timeline.transition_activity_status(duplicate_exclusivity_activity, "succeeded",
               validate_selected_integrity?: true,
               validate_selected_dependencies?: false
             )
  end

  test "normalizes planned and realized activity status state for review and import handoff" do
    planned = %{
      id: :obs_provider,
      type: :observe,
      scenario_id: :leo_1,
      status: "In Progress",
      metadata: %{
        timeline_id: :"timeline:obs_provider",
        source_window_id: :"visibility:obs_provider"
      }
    }

    realized = %{
      id: :obs_provider,
      type: :observe,
      scenario_id: :leo_1,
      status: "succeeded",
      metadata: %{timeline_id: :"timeline:obs_provider"}
    }

    assert %{
             "schema_contract" => "timeline_activity_status_state.v1",
             "model" => "artifact_only_timeline_activity_status_state",
             "model_limits" => model_limits,
             "validation_level" => "artifact_contract",
             "activity_id" => "obs_provider",
             "planned_activity_id" => "obs_provider",
             "realized_activity_id" => "obs_provider",
             "timeline_id" => "timeline:obs_provider",
             "planned_timeline_id" => "timeline:obs_provider",
             "realized_timeline_id" => "timeline:obs_provider",
             "planned_status" => "executing",
             "realized_status" => "completed",
             "planned_status_category" => "planned",
             "realized_status_category" => "executed",
             "transition_decision" => "record",
             "review_required" => false,
             "required_operator_action" => "record_timeline_change",
             "operator_action_reason" => "activity_execution_recorded",
             "import_action" => "import_replacement_activity",
             "status_transition" => %{
               "field" => "status",
               "transition_type" => "changed",
               "from" => "executing",
               "to" => "completed",
               "transition_category" => "execution_recorded",
               "requires_operator_review" => false
             },
             "planned_activity_context" => %{
               "status" => "executing",
               "source_window_id" => "visibility:obs_provider",
               "timeline_identity" => %{"activity_id" => "obs_provider"}
             },
             "realized_activity_context" => %{
               "status" => "completed",
               "timeline_identity" => %{"activity_id" => "obs_provider"}
             },
             "assumptions" => %{
               "artifact_only" => true,
               "no_schedule_mutation" => true,
               "no_operator_authority_grant" => true,
               "no_command_execution" => true
             }
           } = state = Timeline.activity_status_state(planned, realized)

    assert model_limits == Timeline.model_limits()
    assert OrbitalDynamics.timeline_activity_status_state(planned, realized) == state

    assert {:ok, %{"schema_contract" => "timeline_activity_status_state.v1"}} =
             Schema.validate_artifact(state)

    stale_model_limits = Map.put(state, "model_limits", ["timeline_model_is_read_only"])

    assert {:error, stale_model_limits_validation} =
             Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             stale_model_limits_validation["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match timeline report model limits")
           )

    stale_transition_decision = Map.put(state, "transition_decision", "none")

    assert {:error, stale_transition_decision_validation} =
             Schema.validate_artifact(stale_transition_decision)

    assert Enum.any?(
             stale_transition_decision_validation["errors"],
             &(&1["path"] == "$.transition_decision" and
                 &1["message"] == "must equal transition-derived transition_decision")
           )

    assert %{
             "realized_status" => "blocked_by_policy",
             "realized_status_category" => "blocked",
             "transition_decision" => "review",
             "review_required" => true,
             "required_operator_action" => "review_activity_transition",
             "operator_action_reason" => "activity_status_blocked_by_policy",
             "import_action" => "review_timeline_diff"
           } =
             Timeline.activity_status_state(
               %{id: :obs_policy, type: :observe, status: :planned},
               %{id: :obs_policy, type: :observe, status: "blocked by policy"}
             )

    assert %{
             "transition_decision" => "none",
             "review_required" => false,
             "required_operator_action" => "none",
             "operator_action_reason" => "no_status_change",
             "import_action" => "record_preserved_activity"
           } =
             Timeline.activity_status_state(
               %{id: :obs_same, type: :observe, status: "done"},
               %{id: :obs_same, type: :observe, status: :completed}
             )

    assert %{
             "activity_id" => "obs_missing_type",
             "planned_activity_id" => "obs_missing_type",
             "realized_activity_id" => "obs_missing_type",
             "planned_status" => "invalid",
             "realized_status" => "completed",
             "transition_decision" => "review",
             "review_required" => true,
             "required_operator_action" => "review_activity_transition",
             "operator_action_reason" => "invalid_activity_input",
             "invalid_activity_input" => true,
             "invalid_activity_input_count" => 1,
             "invalid_activity_input_reasons" => ["missing_activity_type"],
             "status_transition" => %{
               "field" => "status",
               "transition_type" => "changed",
               "from" => "invalid",
               "to" => "completed",
               "transition_category" => "invalid_activity_input",
               "requires_operator_review" => true
             }
           } =
             invalid_state =
             Timeline.activity_status_state(
               %{id: :obs_missing_type, status: :planned},
               %{id: :obs_missing_type, type: :observe, status: :completed}
             )

    assert {:ok, %{"schema_contract" => "timeline_activity_status_state.v1"}} =
             Schema.validate_artifact(invalid_state)

    assert_raise ArgumentError, ~r/planned or realized activity is required/, fn ->
      Timeline.activity_status_state(nil, nil)
    end
  end

  test "normalizes planned and realized activity approval state for review and import handoff" do
    planned = %{
      id: :cmd_provider,
      type: :command,
      scenario_id: :leo_1,
      approval_status: "Review Required",
      metadata: %{
        timeline_id: :"timeline:cmd_provider",
        source_window_id: :"command:cmd_provider"
      }
    }

    realized = %{
      id: :cmd_provider,
      type: :command,
      scenario_id: :leo_1,
      approval_status: :approved,
      metadata: %{timeline_id: :"timeline:cmd_provider"}
    }

    assert %{
             "schema_contract" => "timeline_activity_approval_state.v1",
             "model" => "artifact_only_timeline_activity_approval_state",
             "model_limits" => model_limits,
             "validation_level" => "artifact_contract",
             "activity_id" => "cmd_provider",
             "planned_activity_id" => "cmd_provider",
             "realized_activity_id" => "cmd_provider",
             "timeline_id" => "timeline:cmd_provider",
             "planned_timeline_id" => "timeline:cmd_provider",
             "realized_timeline_id" => "timeline:cmd_provider",
             "planned_approval_status" => "operator_review_required",
             "realized_approval_status" => "approved",
             "planned_approval_category" => "review_required",
             "realized_approval_category" => "protected",
             "transition_decision" => "review",
             "review_required" => true,
             "required_operator_action" => "review_activity_approval",
             "operator_action_reason" => "approval_grant_requires_operator_authority",
             "import_action" => "review_timeline_diff",
             "approval_transition" => %{
               "field" => "approval_status",
               "transition_type" => "changed",
               "from" => "operator_review_required",
               "to" => "approved",
               "transition_category" => "approval_granted",
               "requires_operator_review" => true
             },
             "planned_activity_context" => %{
               "approval_status" => "operator_review_required",
               "source_window_id" => "command:cmd_provider",
               "timeline_identity" => %{"activity_id" => "cmd_provider"}
             },
             "realized_activity_context" => %{
               "approval_status" => "approved",
               "timeline_identity" => %{"activity_id" => "cmd_provider"}
             },
             "assumptions" => %{
               "artifact_only" => true,
               "no_schedule_mutation" => true,
               "no_operator_authority_grant" => true,
               "no_command_execution" => true
             }
           } = state = Timeline.activity_approval_state(planned, realized)

    assert model_limits == Timeline.model_limits()
    assert OrbitalDynamics.timeline_activity_approval_state(planned, realized) == state

    assert {:ok, %{"schema_contract" => "timeline_activity_approval_state.v1"}} =
             Schema.validate_artifact(state)

    stale_model_limits = Map.put(state, "model_limits", ["timeline_model_is_read_only"])

    assert {:error, stale_model_limits_validation} =
             Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             stale_model_limits_validation["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match timeline report model limits")
           )

    stale_required_operator_action = Map.put(state, "required_operator_action", "none")

    assert {:error, stale_required_operator_action_validation} =
             Schema.validate_artifact(stale_required_operator_action)

    assert Enum.any?(
             stale_required_operator_action_validation["errors"],
             &(&1["path"] == "$.required_operator_action" and
                 &1["message"] == "must equal transition-derived required_operator_action")
           )

    assert %{
             "realized_approval_status" => "blocked_by_policy",
             "realized_approval_category" => "blocked",
             "transition_decision" => "review",
             "review_required" => true,
             "required_operator_action" => "review_activity_approval",
             "operator_action_reason" => "approval_blocked_by_policy",
             "import_action" => "review_timeline_diff"
           } =
             Timeline.activity_approval_state(
               %{id: :cmd_policy, type: :command, approval_status: :pending},
               %{id: :cmd_policy, type: :command, approval_status: "policy blocked"}
             )

    assert %{
             "transition_decision" => "none",
             "review_required" => false,
             "required_operator_action" => "none",
             "operator_action_reason" => "no_approval_status_change",
             "import_action" => "record_preserved_activity"
           } =
             Timeline.activity_approval_state(
               %{id: :cmd_same, type: :command, approval_status: "No Review Required"},
               %{id: :cmd_same, type: :command, approval_status: :not_required}
             )

    assert %{
             "activity_id" => "cmd_missing_type",
             "planned_activity_id" => "cmd_missing_type",
             "realized_activity_id" => "cmd_missing_type",
             "planned_approval_status" => "pending",
             "realized_approval_status" => "operator_review_required",
             "transition_decision" => "review",
             "review_required" => true,
             "required_operator_action" => "review_activity_approval",
             "operator_action_reason" => "invalid_activity_input",
             "invalid_activity_input" => true,
             "invalid_activity_input_count" => 1,
             "invalid_activity_input_reasons" => ["missing_activity_type"],
             "approval_transition" => %{
               "field" => "approval_status",
               "transition_type" => "changed",
               "from" => "pending",
               "to" => "operator_review_required",
               "transition_category" => "invalid_activity_input",
               "requires_operator_review" => true
             }
           } =
             invalid_state =
             Timeline.activity_approval_state(
               %{id: :cmd_missing_type, type: :command, approval_status: :pending},
               %{id: :cmd_missing_type, approval_status: :approved}
             )

    assert {:ok, %{"schema_contract" => "timeline_activity_approval_state.v1"}} =
             Schema.validate_artifact(invalid_state)

    assert_raise ArgumentError, ~r/planned or realized activity is required/, fn ->
      Timeline.activity_approval_state(nil, nil)
    end
  end

  test "combines planned and realized lifecycle state for review and import handoff" do
    planned = %{
      id: :cmd_provider,
      type: :command,
      scenario_id: :leo_1,
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
      scenario_id: :leo_1,
      status: "succeeded",
      approval_status: :approved,
      metadata: %{timeline_id: :"timeline:cmd_provider"}
    }

    assert %{
             "schema_contract" => "timeline_activity_lifecycle_state.v1",
             "model" => "artifact_only_timeline_activity_lifecycle_state",
             "model_limits" => model_limits,
             "validation_level" => "artifact_contract",
             "activity_id" => "cmd_provider",
             "planned_activity_id" => "cmd_provider",
             "realized_activity_id" => "cmd_provider",
             "timeline_id" => "timeline:cmd_provider",
             "planned_status" => "executing",
             "realized_status" => "completed",
             "planned_status_category" => "planned",
             "realized_status_category" => "executed",
             "planned_approval_status" => "operator_review_required",
             "realized_approval_status" => "approved",
             "planned_approval_category" => "review_required",
             "realized_approval_category" => "protected",
             "planned_locked" => false,
             "realized_locked" => false,
             "planned_executed" => false,
             "realized_executed" => true,
             "transition_decision" => "review",
             "review_required" => true,
             "required_operator_action" => "review_activity_approval",
             "required_operator_actions" => [
               "record_timeline_change",
               "review_activity_approval"
             ],
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
             "planned_protection_decision" => %{
               "protection_decision" => "mutable",
               "protection_category" => "none"
             },
             "realized_protection_decision" => %{
               "protection_decision" => "preserve",
               "protection_category" => "executed"
             },
             "planned_activity_context" => %{
               "status" => "executing",
               "approval_status" => "operator_review_required",
               "source_window_id" => "command:cmd_provider"
             },
             "realized_activity_context" => %{
               "status" => "completed",
               "approval_status" => "approved"
             },
             "assumptions" => %{
               "artifact_only" => true,
               "no_schedule_mutation" => true,
               "no_operator_authority_grant" => true,
               "no_cadence_import" => true,
               "no_command_execution" => true
             }
           } = state = Timeline.activity_lifecycle_state(planned, realized)

    assert model_limits == Timeline.model_limits()
    assert OrbitalDynamics.timeline_activity_lifecycle_state(planned, realized) == state

    assert {:ok, %{"schema_contract" => "timeline_activity_lifecycle_state.v1"}} =
             Schema.validate_artifact(state)

    stale_model_limits = Map.put(state, "model_limits", ["timeline_model_is_read_only"])

    assert {:error, stale_model_limits_validation} =
             Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             stale_model_limits_validation["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match timeline report model limits")
           )

    stale_required_operator_actions = Map.put(state, "required_operator_actions", ["none"])

    assert {:error, stale_required_operator_actions_validation} =
             Schema.validate_artifact(stale_required_operator_actions)

    assert Enum.any?(
             stale_required_operator_actions_validation["errors"],
             &(&1["path"] == "$.required_operator_actions" and
                 &1["message"] == "must equal lifecycle-derived required_operator_actions")
           )

    stale_realized_protection_decision =
      put_in(state, ["realized_protection_decision", "protection_decision"], "mutable")

    assert {:error, stale_realized_protection_decision_validation} =
             Schema.validate_artifact(stale_realized_protection_decision)

    assert Enum.any?(
             stale_realized_protection_decision_validation["errors"],
             &(&1["path"] == "$.realized_protection_decision.protection_decision" and
                 &1["message"] == "must preserve executed lifecycle-state protection")
           )

    stale_realized_protection_category =
      put_in(state, ["realized_protection_decision", "protection_category"], "none")

    assert {:error, stale_realized_protection_category_validation} =
             Schema.validate_artifact(stale_realized_protection_category)

    assert Enum.any?(
             stale_realized_protection_category_validation["errors"],
             &(&1["path"] == "$.realized_protection_decision.protection_category" and
                 &1["message"] == "must classify executed lifecycle-state protection")
           )

    stale_realized_protection_approval =
      put_in(state, ["realized_protection_decision", "approved"], false)

    assert {:error, stale_realized_protection_approval_validation} =
             Schema.validate_artifact(stale_realized_protection_approval)

    assert Enum.any?(
             stale_realized_protection_approval_validation["errors"],
             &(&1["path"] == "$.realized_protection_decision.approved" and
                 &1["message"] == "must equal lifecycle-state realized_approval_category")
           )

    assert %{
             "realized_status" => "blocked_by_policy",
             "realized_approval_status" => "blocked_by_policy",
             "realized_status_category" => "blocked",
             "realized_approval_category" => "blocked",
             "transition_decision" => "review",
             "review_required" => true,
             "required_operator_action" => "review_activity_transition",
             "required_operator_actions" => [
               "review_activity_approval",
               "review_activity_transition"
             ],
             "operator_action_reasons" => [
               "activity_status_blocked_by_policy",
               "approval_blocked_by_policy"
             ],
             "import_action" => "review_timeline_diff"
           } =
             Timeline.activity_lifecycle_state(
               %{id: :cmd_policy, type: :command, status: :planned, approval_status: :pending},
               %{
                 id: :cmd_policy,
                 type: :command,
                 status: "blocked by policy",
                 approval_status: "policy blocked"
               }
             )

    assert %{
             "planned_locked" => true,
             "planned_executed" => true,
             "realized_executed" => true,
             "status_transition_decision" => "none",
             "approval_transition_decision" => "review",
             "transition_decision" => "review",
             "required_operator_action" => "review_activity_approval",
             "required_operator_actions" => ["review_activity_approval"],
             "operator_action_reasons" => ["protected_approval_regressed"],
             "planned_protection_decision" => %{
               "protection_decision" => "preserve",
               "protection_category" => "executed"
             }
           } =
             done_state =
             Timeline.activity_lifecycle_state(
               %{
                 id: :done_cmd,
                 type: :command,
                 status: :completed,
                 approval_status: :approved,
                 locked: "true"
               },
               %{
                 id: :done_cmd,
                 type: :command,
                 status: :completed,
                 approval_status: :rejected
               }
             )

    assert {:ok, %{"schema_contract" => "timeline_activity_lifecycle_state.v1"}} =
             Schema.validate_artifact(done_state)

    stale_planned_protection_decision =
      put_in(done_state, ["planned_protection_decision", "protection_decision"], "mutable")

    assert {:error, stale_planned_protection_decision_validation} =
             Schema.validate_artifact(stale_planned_protection_decision)

    assert Enum.any?(
             stale_planned_protection_decision_validation["errors"],
             &(&1["path"] == "$.planned_protection_decision.protection_decision" and
                 &1["message"] == "must preserve executed lifecycle-state protection")
           )

    assert %{
             "realized_executed" => false,
             "realized_approval_category" => "protected",
             "realized_protection_decision" => %{
               "protection_decision" => "review_change",
               "protection_category" => "locked_or_approved"
             }
           } =
             locked_review_state =
             Timeline.activity_lifecycle_state(
               %{
                 id: :locked_cmd,
                 type: :command,
                 status: :planned,
                 approval_status: :approved
               },
               %{
                 id: :locked_cmd,
                 type: :command,
                 status: :failed,
                 approval_status: :approved
               }
             )

    assert {:ok, %{"schema_contract" => "timeline_activity_lifecycle_state.v1"}} =
             Schema.validate_artifact(locked_review_state)

    assert %{
             "activity_id" => "cmd_missing_type",
             "planned_activity_id" => "cmd_missing_type",
             "planned_status" => "invalid",
             "planned_approval_status" => "operator_review_required",
             "transition_decision" => "review",
             "review_required" => true,
             "required_operator_action" => "review_activity_transition",
             "required_operator_actions" => [
               "review_activity_approval",
               "review_activity_transition",
               "review_timeline_change"
             ],
             "operator_action_reasons" => [
               "invalid_activity_input",
               "missing_activity_type"
             ],
             "invalid_activity_input" => true,
             "invalid_activity_input_count" => 1,
             "invalid_activity_input_reasons" => ["missing_activity_type"],
             "planned_protection_decision" => %{
               "protection_decision" => "review_change",
               "protection_category" => "invalid_activity_input",
               "reason" => "missing_activity_type"
             }
           } =
             invalid_state =
             Timeline.activity_lifecycle_state(
               %{id: :cmd_missing_type, status: :planned, approval_status: :pending},
               nil
             )

    assert {:ok, %{"schema_contract" => "timeline_activity_lifecycle_state.v1"}} =
             Schema.validate_artifact(invalid_state)

    assert_raise ArgumentError, ~r/planned or realized activity is required/, fn ->
      Timeline.activity_lifecycle_state(nil, nil)
    end
  end

  test "summarizes planned and realized lifecycle state across activity sets" do
    planned = [
      %{
        id: :cmd_provider,
        type: :command,
        status: "In Progress",
        approval_status: "Review Required",
        metadata: %{timeline_id: :"timeline:cmd_provider"}
      },
      %{
        id: :obs_record,
        type: :observe,
        status: :executing,
        approval_status: :not_required,
        metadata: %{timeline_id: :"timeline:obs_record"}
      },
      %{
        id: :done_keep,
        type: :command,
        status: :completed,
        approval_status: :approved,
        metadata: %{timeline_id: :"timeline:done_keep"}
      },
      %{
        id: :dup_a,
        type: :observe,
        status: :planned,
        metadata: %{timeline_id: :"timeline:dup"}
      },
      %{
        id: :dup_b,
        type: :observe,
        status: :planned,
        metadata: %{timeline_id: :"timeline:dup"}
      }
    ]

    realized = [
      %{
        id: :cmd_provider,
        type: :command,
        status: "succeeded",
        approval_status: :approved,
        metadata: %{timeline_id: :"timeline:cmd_provider"}
      },
      %{
        id: :obs_record,
        type: :observe,
        status: :completed,
        approval_status: :not_required,
        metadata: %{timeline_id: :"timeline:obs_record"}
      },
      %{
        id: :done_keep,
        type: :command,
        status: :completed,
        approval_status: :approved,
        metadata: %{timeline_id: :"timeline:done_keep"}
      }
    ]

    assert %{
             "schema_contract" => "timeline_lifecycle_state_summary.v1",
             "model" => "artifact_only_timeline_lifecycle_state_summary",
             "validation_level" => "artifact_contract",
             "model_limits" => model_limits,
             "planned_activity_count" => 5,
             "realized_activity_count" => 3,
             "row_count" => 4,
             "recordable_count" => 1,
             "preserved_count" => 1,
             "review_required_count" => 2,
             "duplicate_timeline_identity_count" => 1,
             "invalid_activity_input_count" => 0,
             "transition_decision_counts" => %{
               "none" => 1,
               "record" => 1,
               "review" => 2
             },
             "required_operator_action_counts" => %{
               "none" => 1,
               "record_timeline_change" => 1,
               "review_activity_approval" => 1,
               "review_duplicate_timeline_identity" => 1
             },
             "operator_action_reason_counts" => %{
               "activity_execution_recorded" => 2,
               "approval_grant_requires_operator_authority" => 1,
               "duplicate_timeline_identity" => 1
             },
             "import_action_counts" => %{
               "import_replacement_activity" => 1,
               "record_preserved_activity" => 1,
               "review_timeline_diff" => 2
             },
             "planned_status_category_counts" => %{"executed" => 1, "planned" => 2},
             "realized_status_category_counts" => %{"executed" => 3},
             "status_transition_category_counts" => %{"execution_recorded" => 2},
             "approval_transition_category_counts" => %{"approval_granted" => 1},
             "recordable_timeline_ids" => ["timeline:obs_record"],
             "preserved_timeline_ids" => ["timeline:done_keep"],
             "review_timeline_ids" => ["timeline:cmd_provider", "timeline:dup"],
             "review_activity_ids" => ["cmd_provider", "dup_a", "dup_b"],
             "invalid_activity_input_ids" => [],
             "review_timeline_ids_by_required_operator_action" => %{
               "review_activity_approval" => ["timeline:cmd_provider"],
               "review_duplicate_timeline_identity" => ["timeline:dup"]
             },
             "review_timeline_ids_by_operator_action_reason" => %{
               "activity_execution_recorded" => ["timeline:cmd_provider"],
               "approval_grant_requires_operator_authority" => ["timeline:cmd_provider"],
               "duplicate_timeline_identity" => ["timeline:dup"]
             },
             "review_timeline_ids_by_approval_transition_category" => %{
               "approval_granted" => ["timeline:cmd_provider"]
             },
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "operator_authority" => "not_granted_by_summary",
               "cadence_import" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary"
             }
           } = summary = Timeline.lifecycle_state_summary(planned, realized)

    assert model_limits == Timeline.model_limits()

    assert [%{"timeline_id" => "timeline:cmd_provider"}, %{"timeline_id" => "timeline:dup"}] =
             summary["review_rows"]

    assert %{
             "timeline_identity_collision" => true,
             "planned_activity_ids" => ["dup_a", "dup_b"],
             "transition_decision" => "review",
             "required_operator_actions" => ["review_duplicate_timeline_identity"]
           } = Enum.find(summary["rows"], &(&1["timeline_id"] == "timeline:dup"))

    assert OrbitalDynamics.timeline_lifecycle_state_summary(planned, realized) == summary

    assert {:ok, %{"schema_contract" => "timeline_lifecycle_state_summary.v1"}} =
             Schema.validate_artifact(summary)

    stale_review_count = Map.put(summary, "review_required_count", 99)
    assert {:error, stale_review_count_report} = Schema.validate_artifact(stale_review_count)

    assert Enum.any?(
             stale_review_count_report["errors"],
             &(&1["path"] == "$.review_required_count" and
                 &1["message"] == "must equal 2")
           )

    stale_reason_counts =
      Map.put(summary, "operator_action_reason_counts", %{
        "activity_execution_recorded" => 1
      })

    assert {:error, stale_reason_counts_report} = Schema.validate_artifact(stale_reason_counts)

    assert Enum.any?(
             stale_reason_counts_report["errors"],
             &(&1["path"] == "$.operator_action_reason_counts" and
                 &1["message"] == "must equal row-derived operator_action_reason_counts")
           )

    stale_reason_ids =
      put_in(
        summary,
        ["review_timeline_ids_by_operator_action_reason", "activity_execution_recorded"],
        []
      )

    assert {:error, stale_reason_ids_report} = Schema.validate_artifact(stale_reason_ids)

    assert Enum.any?(
             stale_reason_ids_report["errors"],
             &(&1["path"] == "$.review_timeline_ids_by_operator_action_reason" and
                 &1["message"] ==
                   "must equal row-derived review_timeline_ids_by_operator_action_reason")
           )

    stale_review_rows = Map.put(summary, "review_rows", [])
    assert {:error, stale_review_rows_report} = Schema.validate_artifact(stale_review_rows)

    assert Enum.any?(
             stale_review_rows_report["errors"],
             &(&1["path"] == "$.review_rows" and
                 &1["message"] == "must equal row-derived review rows")
           )

    stale_invalid_activity_ids = Map.put(summary, "invalid_activity_input_ids", ["stale"])

    assert {:error, stale_invalid_activity_ids_report} =
             Schema.validate_artifact(stale_invalid_activity_ids)

    assert Enum.any?(
             stale_invalid_activity_ids_report["errors"],
             &(&1["path"] == "$.invalid_activity_input_ids" and
                 &1["message"] == "must equal row-derived invalid_activity_input_ids")
           )

    invalid_summary =
      Timeline.lifecycle_state_summary([%{id: :bad_missing_type}], [])

    assert %{
             "invalid_activity_input_count" => 1,
             "invalid_activity_input_ids" => ["timeline_row:1:bad_missing_type"],
             "review_required_count" => 1,
             "review_timeline_ids_by_required_operator_action" => %{
               "review_invalid_activity_input" => [
                 "timeline:invalid_activity_input:bad_missing_type"
               ]
             }
           } = invalid_summary

    assert_raise ArgumentError, ~r/planned and realized activities must be lists/, fn ->
      Timeline.lifecycle_state_summary(%{}, [])
    end
  end
end
