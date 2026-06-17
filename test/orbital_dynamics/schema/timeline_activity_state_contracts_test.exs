defmodule OrbitalDynamics.Schema.TimelineActivityStateContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "exports timeline activity-state adapter source enums" do
    assert {:ok, cadence_schema} = Schema.json_schema("cadence_import_manifest.v1")
    assert {:ok, operator_review_schema} = Schema.json_schema("operator_review_package.v1")

    assert "timeline_activity_state.v1" in get_in(cadence_schema, [
             "properties",
             "source_artifact_type",
             "enum"
           ])

    assert "timeline_activity_state.v1" in get_in(operator_review_schema, [
             "properties",
             "source_artifact_type",
             "enum"
           ])
  end

  test "exports timeline activity-state handoff schema fields" do
    assert {:ok, schema} = Schema.json_schema("timeline_activity_state.v1")

    assert schema["required"] == [
             "schema_contract",
             "model",
             "validation_level",
             "state_status",
             "row_count",
             "status_counts",
             "feedback_kind_counts",
             "match_strategy_counts",
             "cadence_import_status_counts",
             "planned_protection_decision_counts",
             "review_required",
             "review_activity_ids",
             "rows",
             "assumptions",
             "model_limits"
           ]

    assert get_in(schema, ["properties", "schema_contract", "const"]) ==
             "timeline_activity_state.v1"

    assert get_in(schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_activity_state"

    assert get_in(schema, ["properties", "validation_level", "const"]) == "artifact_contract"

    assert get_in(schema, ["properties", "model_limits", "const"]) ==
             Enum.map(
               OrbitalDynamics.TimelineFeedback.capabilities().known_limits,
               &Atom.to_string/1
             )

    assert_timeline_activity_state_assumptions_schema(
      schema,
      timeline_activity_state_assumption_fields()
    )

    assert get_in(schema, ["x-orbital-dynamics", "nested_contracts"]) == [
             "timeline_feedback_report.v1"
           ]

    capabilities = OrbitalDynamics.TimelineFeedback.capabilities()

    assert get_in(schema, ["properties", "state_status", "enum"]) ==
             ["empty", "review_required" | capabilities.report_statuses]

    assert get_in(schema, ["properties", "status_counts", "propertyNames", "enum"]) ==
             capabilities.report_statuses

    assert get_in(schema, ["properties", "feedback_kind_counts", "propertyNames", "enum"]) ==
             capabilities.feedback_kinds

    assert get_in(schema, ["properties", "match_strategy_counts", "propertyNames", "enum"]) ==
             capabilities.match_strategies

    assert get_in(schema, [
             "properties",
             "planned_protection_decision_counts",
             "propertyNames",
             "enum"
           ]) == capabilities.planned_protection_decisions

    assert get_in(schema, [
             "properties",
             "realized_provider_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, [
             "properties",
             "realized_source_quality_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, ["properties", "realized_trust_boundary_status", "type"]) == "string"

    assert get_in(schema, ["properties", "realized_trust_boundaries", "items", "type"]) ==
             "string"

    assert get_in(schema, ["properties", "planned_approval_status", "type"]) == "string"
    assert get_in(schema, ["properties", "realized_approval_status", "type"]) == "string"
    assert get_in(schema, ["properties", "planned_status_category", "type"]) == "string"
    assert get_in(schema, ["properties", "realized_status_category", "type"]) == "string"
    assert get_in(schema, ["properties", "planned_approval_category", "type"]) == "string"
    assert get_in(schema, ["properties", "realized_approval_category", "type"]) == "string"
    assert get_in(schema, ["properties", "planned_locked", "type"]) == "boolean"
    assert get_in(schema, ["properties", "realized_locked", "type"]) == "boolean"
    assert get_in(schema, ["properties", "planned_executed", "type"]) == "boolean"
    assert get_in(schema, ["properties", "realized_executed", "type"]) == "boolean"

    assert get_in(schema, [
             "properties",
             "approval_transition",
             "properties",
             "transition_type",
             "enum"
           ]) == ["added", "removed", "changed"]

    assert get_in(schema, [
             "properties",
             "source_protection_decision",
             "properties",
             "protection_decision",
             "type"
           ]) == "string"

    assert get_in(schema, [
             "properties",
             "realized_protection_decision",
             "properties",
             "protection_decision",
             "type"
           ]) == "string"

    row_properties = get_in(schema, ["properties", "rows", "items", "properties"])

    assert get_in(schema, ["properties", "rows", "items", "required"]) == [
             "activity_id",
             "status"
           ]

    assert row_properties["activity_id"] == %{
             "type" => "string",
             "pattern" => "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
           }

    assert row_properties["timeline_identity"] ==
             get_in(schema, [
               "properties",
               "timeline_identity"
             ])
  end

  test "validates checked-in timeline activity-state fixture regenerates through public facade" do
    state = read_json!("study_results/timeline_activity_state_v1.json")

    planned = %{
      id: :cmd_lock,
      type: :command,
      status: :approved,
      approved: true,
      locked: true,
      starts_at_s: 100,
      ends_at_s: 120,
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    realized = %{
      id: :cmd_new,
      type: :command,
      status: :executed,
      starts_at_s: 130,
      ends_at_s: 140,
      metadata: %{timeline_id: :"timeline:cmd_new"}
    }

    generated_state = OrbitalDynamics.timeline_activity_state(planned, realized)

    assert generated_state == state

    assert {:ok, %{"schema_contract" => "timeline_activity_state.v1"}} =
             Schema.validate_artifact(state)

    assert state["schema_contract"] == "timeline_activity_state.v1"
    assert state["model"] == "artifact_only_timeline_activity_state"
    assert state["validation_level"] == "artifact_contract"
    assert state["state_status"] == "review_required"
    assert state["row_count"] == 2
    assert state["activity_ids"] == ["cmd_lock", "cmd_new"]
    assert state["review_activity_ids"] == ["cmd_lock", "cmd_new"]
    assert state["status_counts"] == %{"planned_only" => 1, "realized_only" => 1}

    assert state["match_strategy_counts"] == %{
             "unmatched_planned" => 1,
             "unmatched_realized" => 1
           }

    assert state["planned_status_category"] == "planned"
    assert state["planned_locked"] == true
    assert state["planned_executed"] == false
    assert state["realized_status_category"] == "executed"
    assert state["realized_locked"] == false
    assert state["realized_executed"] == true
    assert state["review_required"] == true

    assert state["planned_protection_decision"] == "preserve"
    assert state["planned_protection_category"] == "locked_or_approved"
    assert state["realized_trust_boundary_status"] == "missing"

    assert state["model_limits"] == [
             "artifact_level_only",
             "no_schedule_mutation",
             "no_command_execution",
             "no_operator_authority_decision",
             "timing_deltas_require_declared_actual_times"
           ]

    assert Enum.map(state["rows"], & &1["activity_id"]) == ["cmd_lock", "cmd_new"]
  end

  test "validates timeline activity-state row-derived artifact fields" do
    planned = %{
      id: :downlink_equator,
      type: :downlink,
      status: :planned,
      metadata: %{timeline_id: :"timeline:downlink_equator"}
    }

    realized = %{
      id: :downlink_equator,
      type: :downlink,
      status: :completed,
      actual_throughput_mb: 72.0,
      provider: :ksat,
      source_quality: :provider_declared,
      trust_boundary: :provider_adapter,
      metadata: %{timeline_id: :"timeline:downlink_equator"}
    }

    valid_state = OrbitalDynamics.TimelineFeedback.activity_state(planned, realized)

    assert {:ok, %{"schema_contract" => "timeline_activity_state.v1"}} =
             Schema.validate_artifact(valid_state)

    invalid_planned_status_category = Map.put(valid_state, "planned_status_category", 42)

    assert {:error, validation_report} =
             Schema.validate_artifact(invalid_planned_status_category)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.planned_status_category" and
                 &1["message"] =~ "must be a binary")
           )

    invalid_planned_locked = Map.put(valid_state, "planned_locked", "false")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_planned_locked)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.planned_locked" and &1["message"] =~ "must be a boolean")
           )

    invalid_realized_protection =
      Map.put(valid_state, "realized_protection_decision", "mutable")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_realized_protection)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.realized_protection_decision" and
                 &1["message"] =~ "must be a map")
           )

    invalid_model = Map.put(valid_state, "model", "custom")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_model)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] == "must equal \"artifact_only_timeline_activity_state\"")
           )

    stale_model_limits = Map.put(valid_state, "model_limits", ["artifact_level_only"])

    assert {:error, validation_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match timeline activity state model limits")
           )

    stale_row_count = Map.put(valid_state, "row_count", 2)

    assert {:error, validation_report} = Schema.validate_artifact(stale_row_count)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.row_count" and &1["message"] == "must equal 1")
           )

    stale_status_counts = Map.put(valid_state, "status_counts", %{"matched" => 2})

    assert {:error, validation_report} = Schema.validate_artifact(stale_status_counts)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.status_counts" and
                 &1["message"] == "must equal row-derived status_counts")
           )

    stale_provider_counts = Map.put(valid_state, "realized_provider_counts", %{"ksat" => 2})

    assert {:error, validation_report} = Schema.validate_artifact(stale_provider_counts)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.realized_provider_counts" and
                 &1["message"] == "must equal row-derived realized_provider_counts")
           )

    stale_source_quality_counts =
      Map.put(valid_state, "realized_source_quality_counts", %{"provider_declared" => 2})

    assert {:error, validation_report} = Schema.validate_artifact(stale_source_quality_counts)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.realized_source_quality_counts" and
                 &1["message"] == "must equal row-derived realized_source_quality_counts")
           )

    stale_trust_boundary_status =
      Map.put(valid_state, "realized_trust_boundary_status", "missing")

    assert {:error, validation_report} = Schema.validate_artifact(stale_trust_boundary_status)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.realized_trust_boundary_status" and
                 &1["message"] == "must equal row-derived realized_trust_boundary_status")
           )

    stale_trust_boundaries = Map.put(valid_state, "realized_trust_boundaries", ["other_adapter"])

    assert {:error, validation_report} = Schema.validate_artifact(stale_trust_boundaries)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.realized_trust_boundaries" and
                 &1["message"] == "must equal row-derived realized_trust_boundaries")
           )

    stale_state_status = Map.put(valid_state, "state_status", "review_required")

    assert {:error, validation_report} = Schema.validate_artifact(stale_state_status)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.state_status" and
                 &1["message"] == "must equal row-derived state_status")
           )

    stale_activity_ids = Map.put(valid_state, "activity_ids", ["other_activity"])

    assert {:error, validation_report} = Schema.validate_artifact(stale_activity_ids)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.activity_ids" and
                 &1["message"] == "must equal row-derived activity_ids")
           )

    stale_review_activity_ids = Map.put(valid_state, "review_activity_ids", ["downlink_equator"])

    assert {:error, validation_report} = Schema.validate_artifact(stale_review_activity_ids)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.review_activity_ids" and
                 &1["message"] == "must equal row-derived review_activity_ids")
           )

    invalid_assumption =
      put_in(valid_state, ["assumptions", "no_schedule_mutation"], false)

    assert {:error, validation_report} = Schema.validate_artifact(invalid_assumption)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.assumptions.no_schedule_mutation" and
                 &1["message"] == "must equal true")
           )

    invalid_row_id =
      put_in(valid_state, ["rows", Access.at(0), "activity_id"], "bad activity id")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_row_id)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.rows[0].activity_id" and &1["message"] =~ "stable ID")
           )

    invalid_transition =
      put_in(valid_state, ["status_transition", "transition_type"], "custom")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_transition)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.status_transition.transition_type" and
                 &1["message"] =~ "must be one of")
           )
  end

  test "exports and validates timeline activity status-state fields" do
    assert {:ok, schema} = Schema.json_schema("timeline_activity_status_state.v1")

    assert get_in(schema, ["properties", "schema_contract", "const"]) ==
             "timeline_activity_status_state.v1"

    assert get_in(schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_activity_status_state"

    assert get_in(schema, ["properties", "validation_level", "const"]) == "artifact_contract"

    assert get_in(schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert get_in(schema, ["properties", "model_limits", "items", "enum"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert_timeline_activity_state_assumptions_schema(
      schema,
      timeline_activity_status_state_assumption_fields()
    )

    assert get_in(schema, ["properties", "transition_decision", "enum"]) ==
             OrbitalDynamics.Timeline.capabilities().transition_decisions

    assert get_in(schema, ["properties", "operator_action_reason", "type"]) == "string"
    assert get_in(schema, ["properties", "planned_status_category", "type"]) == "string"
    assert get_in(schema, ["properties", "realized_status_category", "type"]) == "string"
    assert get_in(schema, ["properties", "import_action", "type"]) == "string"

    assert get_in(schema, [
             "properties",
             "status_transition",
             "properties",
             "transition_type",
             "enum"
           ]) ==
             ["added", "removed", "changed"]

    assert get_in(schema, ["properties", "activity_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    planned = %{
      id: :obs_provider,
      type: :observe,
      scenario_id: :leo_1,
      status: "In Progress",
      source_window_id: :"visibility:obs_provider",
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

    fixture = read_json!("study_results/timeline_activity_status_state_v1.json")
    state = OrbitalDynamics.timeline_activity_status_state(planned, realized)

    assert state == fixture
    assert state["invalid_activity_input"] == false

    assert {:ok, %{"schema_contract" => "timeline_activity_status_state.v1"}} =
             Schema.validate_artifact(state)

    invalid_assumption = put_in(state, ["assumptions", "no_command_execution"], false)

    assert {:error, validation_report} = Schema.validate_artifact(invalid_assumption)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.assumptions.no_command_execution" and
                 &1["message"] == "must equal true")
           )

    invalid_model = Map.put(state, "model", "custom")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_model)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"artifact_only_timeline_activity_status_state\"")
           )

    stale_model_limits = Map.put(state, "model_limits", ["timeline_model_is_read_only"])

    assert {:error, validation_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match timeline report model limits")
           )

    stale_review_required = Map.put(state, "review_required", true)

    assert {:error, validation_report} = Schema.validate_artifact(stale_review_required)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.review_required" and
                 &1["message"] == "must equal transition-derived review_required")
           )

    stale_operator_action_reason = Map.put(state, "operator_action_reason", "custom")

    assert {:error, validation_report} = Schema.validate_artifact(stale_operator_action_reason)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.operator_action_reason" and
                 &1["message"] == "must equal transition-derived operator_action_reason")
           )

    invalid_status_category = Map.put(state, "planned_status_category", %{"value" => "planned"})

    assert {:error, validation_report} = Schema.validate_artifact(invalid_status_category)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.planned_status_category" and
                 &1["message"] =~ "must be a binary")
           )
  end

  test "exports and validates timeline activity approval-state fields" do
    assert {:ok, schema} = Schema.json_schema("timeline_activity_approval_state.v1")

    assert get_in(schema, ["properties", "schema_contract", "const"]) ==
             "timeline_activity_approval_state.v1"

    assert get_in(schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_activity_approval_state"

    assert get_in(schema, ["properties", "validation_level", "const"]) == "artifact_contract"

    assert get_in(schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert get_in(schema, ["properties", "model_limits", "items", "enum"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert_timeline_activity_state_assumptions_schema(
      schema,
      timeline_activity_status_state_assumption_fields()
    )

    assert get_in(schema, ["properties", "transition_decision", "enum"]) ==
             OrbitalDynamics.Timeline.capabilities().transition_decisions

    assert get_in(schema, ["properties", "operator_action_reason", "type"]) == "string"
    assert get_in(schema, ["properties", "planned_approval_category", "type"]) == "string"
    assert get_in(schema, ["properties", "realized_approval_category", "type"]) == "string"
    assert get_in(schema, ["properties", "import_action", "type"]) == "string"

    assert get_in(schema, [
             "properties",
             "approval_transition",
             "properties",
             "transition_type",
             "enum"
           ]) ==
             ["added", "removed", "changed"]

    assert get_in(schema, ["properties", "activity_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    planned = %{
      id: :cmd_provider,
      type: :command,
      scenario_id: :leo_1,
      approval_status: "Review Required",
      command_window_id: :"command_window:cmd_provider",
      command_window_type: :command_window,
      source_window_id: :"command:cmd_provider",
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
      command_window_id: :"command_window:cmd_provider",
      command_window_type: :command_window,
      metadata: %{timeline_id: :"timeline:cmd_provider"}
    }

    fixture = read_json!("study_results/timeline_activity_approval_state_v1.json")
    state = OrbitalDynamics.timeline_activity_approval_state(planned, realized)

    assert state == fixture
    assert state["invalid_activity_input"] == false

    assert {:ok, %{"schema_contract" => "timeline_activity_approval_state.v1"}} =
             Schema.validate_artifact(state)

    invalid_assumption = put_in(state, ["assumptions", "no_operator_authority_grant"], false)

    assert {:error, validation_report} = Schema.validate_artifact(invalid_assumption)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.assumptions.no_operator_authority_grant" and
                 &1["message"] == "must equal true")
           )

    invalid_model = Map.put(state, "model", "custom")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_model)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"artifact_only_timeline_activity_approval_state\"")
           )

    stale_model_limits = Map.put(state, "model_limits", ["timeline_model_is_read_only"])

    assert {:error, validation_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match timeline report model limits")
           )

    stale_review_required = Map.put(state, "review_required", false)

    assert {:error, validation_report} = Schema.validate_artifact(stale_review_required)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.review_required" and
                 &1["message"] == "must equal transition-derived review_required")
           )

    stale_operator_action_reason = Map.put(state, "operator_action_reason", "custom")

    assert {:error, validation_report} = Schema.validate_artifact(stale_operator_action_reason)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.operator_action_reason" and
                 &1["message"] == "must equal transition-derived operator_action_reason")
           )

    stale_import_action = Map.put(state, "import_action", "import_replacement_activity")

    assert {:error, validation_report} = Schema.validate_artifact(stale_import_action)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.import_action" and
                 &1["message"] == "must equal transition-derived import_action")
           )

    invalid_approval_category =
      Map.put(state, "realized_approval_category", %{"value" => "protected"})

    assert {:error, validation_report} = Schema.validate_artifact(invalid_approval_category)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.realized_approval_category" and
                 &1["message"] =~ "must be a binary")
           )
  end

  test "exports and validates timeline activity lifecycle-state fields" do
    assert {:ok, schema} = Schema.json_schema("timeline_activity_lifecycle_state.v1")

    assert get_in(schema, ["properties", "schema_contract", "const"]) ==
             "timeline_activity_lifecycle_state.v1"

    assert get_in(schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_activity_lifecycle_state"

    assert get_in(schema, ["properties", "validation_level", "const"]) == "artifact_contract"

    assert_timeline_activity_state_assumptions_schema(
      schema,
      timeline_activity_lifecycle_state_assumption_fields()
    )

    assert get_in(schema, ["properties", "transition_decision", "enum"]) ==
             OrbitalDynamics.Timeline.capabilities().transition_decisions

    assert get_in(schema, ["properties", "status_transition_decision", "enum"]) ==
             OrbitalDynamics.Timeline.capabilities().transition_decisions

    assert get_in(schema, ["properties", "approval_transition_decision", "enum"]) ==
             OrbitalDynamics.Timeline.capabilities().transition_decisions

    assert get_in(schema, ["properties", "planned_status_category", "type"]) == "string"
    assert get_in(schema, ["properties", "realized_status_category", "type"]) == "string"
    assert get_in(schema, ["properties", "planned_approval_category", "type"]) == "string"
    assert get_in(schema, ["properties", "realized_approval_category", "type"]) == "string"

    assert get_in(schema, ["properties", "required_operator_actions", "items", "type"]) ==
             "string"

    assert get_in(schema, ["properties", "operator_action_reasons", "items", "type"]) ==
             "string"

    assert get_in(schema, ["properties", "import_action", "type"]) == "string"

    assert get_in(schema, [
             "properties",
             "status_transition",
             "properties",
             "transition_type",
             "enum"
           ]) ==
             ["added", "removed", "changed"]

    assert get_in(schema, [
             "properties",
             "approval_transition",
             "properties",
             "transition_type",
             "enum"
           ]) ==
             ["added", "removed", "changed"]

    assert get_in(schema, [
             "properties",
             "planned_protection_decision",
             "properties",
             "protection_decision",
             "type"
           ]) == "string"

    assert get_in(schema, [
             "properties",
             "planned_protection_decision",
             "properties",
             "timeline_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, ["properties", "activity_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    planned = %{
      id: :cmd_provider,
      type: :command,
      scenario_id: :leo_1,
      status: "In Progress",
      approval_status: "Review Required",
      command_window_id: :"command_window:cmd_provider",
      command_window_type: :command_window,
      source_window_id: :"command:cmd_provider",
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
      command_window_id: :"command_window:cmd_provider",
      command_window_type: :command_window,
      metadata: %{timeline_id: :"timeline:cmd_provider"}
    }

    fixture = read_json!("study_results/timeline_activity_lifecycle_state_v1.json")
    state = OrbitalDynamics.timeline_activity_lifecycle_state(planned, realized)

    assert state == fixture
    assert state["invalid_activity_input"] == false

    assert {:ok, %{"schema_contract" => "timeline_activity_lifecycle_state.v1"}} =
             Schema.validate_artifact(state)

    stale_model_limits = Map.put(state, "model_limits", ["timeline_model_is_read_only"])

    assert {:error, validation_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match timeline report model limits")
           )

    stale_transition_decision = Map.put(state, "transition_decision", "record")

    assert {:error, validation_report} = Schema.validate_artifact(stale_transition_decision)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.transition_decision" and
                 &1["message"] == "must equal lifecycle-derived transition_decision")
           )

    stale_required_operator_actions = Map.put(state, "required_operator_actions", ["none"])

    assert {:error, validation_report} =
             Schema.validate_artifact(stale_required_operator_actions)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.required_operator_actions" and
                 &1["message"] == "must equal lifecycle-derived required_operator_actions")
           )

    stale_required_operator_action = Map.put(state, "required_operator_action", "none")

    assert {:error, validation_report} = Schema.validate_artifact(stale_required_operator_action)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.required_operator_action" and
                 &1["message"] == "must equal lifecycle-derived required_operator_action")
           )

    stale_operator_action_reasons = Map.put(state, "operator_action_reasons", ["custom"])

    assert {:error, validation_report} = Schema.validate_artifact(stale_operator_action_reasons)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.operator_action_reasons" and
                 &1["message"] == "must equal lifecycle-derived operator_action_reasons")
           )

    stale_import_action = Map.put(state, "import_action", "record_preserved_activity")

    assert {:error, validation_report} = Schema.validate_artifact(stale_import_action)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.import_action" and
                 &1["message"] == "must equal lifecycle-derived import_action")
           )

    invalid_status_category = Map.put(state, "planned_status_category", %{"value" => "planned"})

    assert {:error, validation_report} = Schema.validate_artifact(invalid_status_category)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.planned_status_category" and
                 &1["message"] =~ "must be a binary")
           )

    invalid_operator_action_reasons = Map.put(state, "operator_action_reasons", ["ok", 1])

    assert {:error, validation_report} = Schema.validate_artifact(invalid_operator_action_reasons)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.operator_action_reasons[1]" and
                 &1["message"] =~ "must be a string")
           )

    invalid_activity_id = Map.put(state, "activity_id", "bad activity")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_activity_id)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.activity_id" and &1["message"] =~ "stable ID")
           )

    invalid_assumption = put_in(state, ["assumptions", "no_cadence_import"], false)

    assert {:error, validation_report} = Schema.validate_artifact(invalid_assumption)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.assumptions.no_cadence_import" and
                 &1["message"] == "must equal true")
           )
  end

  test "exports and validates timeline lifecycle-state summary fields" do
    assert {:ok, schema} = Schema.json_schema("timeline_lifecycle_state_summary.v1")

    assert get_in(schema, ["properties", "schema_contract", "const"]) ==
             "timeline_lifecycle_state_summary.v1"

    assert get_in(schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_lifecycle_state_summary"

    assert get_in(schema, ["properties", "validation_level", "const"]) == "artifact_contract"

    assert get_in(schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert get_in(schema, ["properties", "source", "type"]) == "string"

    assert get_in(schema, ["properties", "rows", "items", "required"]) == [
             "rank",
             "timeline_id",
             "transition_decision",
             "review_required",
             "required_operator_action",
             "import_action"
           ]

    row_properties = get_in(schema, ["properties", "rows", "items", "properties"])

    assert get_in(row_properties, ["schema_contract", "const"]) ==
             "timeline_activity_lifecycle_state.v1"

    assert get_in(row_properties, ["model", "const"]) ==
             "artifact_only_timeline_activity_lifecycle_state"

    assert get_in(row_properties, ["validation_level", "const"]) == "artifact_contract"

    assert get_in(row_properties, ["planned_timeline_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_properties, ["realized_timeline_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_properties, ["planned_status_category", "type"]) == "string"
    assert get_in(row_properties, ["realized_status_category", "type"]) == "string"
    assert get_in(row_properties, ["planned_approval_category", "type"]) == "string"
    assert get_in(row_properties, ["realized_approval_category", "type"]) == "string"

    assert get_in(row_properties, ["planned_duplicate_activity_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(row_properties, ["realized_duplicate_activity_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(row_properties, ["assumptions", "type"]) == "object"

    assert get_in(schema, [
             "properties",
             "review_timeline_ids_by_required_operator_action",
             "additionalProperties",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, [
             "properties",
             "import_action_counts",
             "additionalProperties",
             "type"
           ]) == "integer"

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
        status: :planned,
        approval_status: :not_required,
        metadata: %{timeline_id: :"timeline:obs_record"}
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
      }
    ]

    summary = OrbitalDynamics.Timeline.lifecycle_state_summary(planned, realized)

    assert {:ok, %{"schema_contract" => "timeline_lifecycle_state_summary.v1"}} =
             Schema.validate_artifact(summary)

    stale_model_limits = Map.put(summary, "model_limits", ["artifact_level_only"])

    assert {:error, validation_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] =~ "must match timeline report model limits")
           )

    invalid_model = Map.put(summary, "model", "custom")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_model)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"artifact_only_timeline_lifecycle_state_summary\"")
           )

    stale_transition_counts = Map.put(summary, "transition_decision_counts", %{"review" => 99})

    assert {:error, validation_report} = Schema.validate_artifact(stale_transition_counts)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.transition_decision_counts" and
                 &1["message"] == "must equal row-derived transition_decision_counts")
           )

    stale_review_ids = Map.put(summary, "review_timeline_ids", [])

    assert {:error, validation_report} = Schema.validate_artifact(stale_review_ids)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.review_timeline_ids" and
                 &1["message"] == "must equal row-derived review_timeline_ids")
           )

    stale_import_counts =
      Map.put(summary, "import_action_counts", %{"review_timeline_diff" => 99})

    assert {:error, validation_report} = Schema.validate_artifact(stale_import_counts)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.import_action_counts" and
                 &1["message"] == "must equal row-derived import_action_counts")
           )

    stale_status_review_ids =
      put_in(
        summary,
        ["review_timeline_ids_by_status_transition_category", "execution_recorded"],
        []
      )

    assert {:error, validation_report} = Schema.validate_artifact(stale_status_review_ids)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.review_timeline_ids_by_status_transition_category" and
                 &1["message"] ==
                   "must equal row-derived review_timeline_ids_by_status_transition_category")
           )

    invalid_review_id_map =
      put_in(
        summary,
        ["review_timeline_ids_by_required_operator_action", "review_activity_approval"],
        ["bad timeline"]
      )

    assert {:error, validation_report} = Schema.validate_artifact(invalid_review_id_map)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] ==
                 "$.review_timeline_ids_by_required_operator_action.review_activity_approval[0]" and
                 &1["message"] =~ "stable ID")
           )
  end

  test "validates checked-in timeline lifecycle-state summary fixture" do
    summary = read_json!("study_results/timeline_lifecycle_state_summary_v1.json")

    planned = [
      %{
        id: :cmd_provider,
        type: :command,
        scenario_id: :leo_1,
        status: "In Progress",
        approval_status: "Review Required",
        command_window_id: :"command_window:cmd_provider",
        command_window_type: :command_window,
        metadata: %{timeline_id: :"timeline:cmd_provider"}
      },
      %{
        id: :obs_record,
        type: :observe,
        status: :planned,
        approval_status: :not_required,
        metadata: %{timeline_id: :"timeline:obs_record"}
      },
      %{
        id: :done_keep,
        type: :command,
        status: :completed,
        approval_status: :approved,
        command_window_id: :"command_window:done_keep",
        command_window_type: :command_window,
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
        scenario_id: :leo_1,
        status: "succeeded",
        approval_status: :approved,
        command_window_id: :"command_window:cmd_provider",
        command_window_type: :command_window,
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
        command_window_id: :"command_window:done_keep",
        command_window_type: :command_window,
        metadata: %{timeline_id: :"timeline:done_keep"}
      }
    ]

    generated_summary =
      OrbitalDynamics.timeline_lifecycle_state_summary(
        planned,
        realized,
        source: "validation.timeline_lifecycle_state_summary"
      )

    assert generated_summary == summary

    assert {:ok, %{"schema_contract" => "timeline_lifecycle_state_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert %{
             "schema_contract" => "timeline_lifecycle_state_summary.v1",
             "model" => "artifact_only_timeline_lifecycle_state_summary",
             "validation_level" => "artifact_contract",
             "model_limits" => model_limits,
             "source" => "validation.timeline_lifecycle_state_summary",
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
             "review_timeline_ids_by_status_transition_category" => %{
               "execution_recorded" => ["timeline:cmd_provider"]
             },
             "review_timeline_ids_by_approval_transition_category" => %{
               "approval_granted" => ["timeline:cmd_provider"]
             },
             "assumptions" => %{
               "cadence_import" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary",
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "identity_match" => "planned and realized rows are paired by timeline identity",
               "operator_authority" => "not_granted_by_summary"
             }
           } = summary

    assert model_limits == OrbitalDynamics.Timeline.model_limits()

    assert [
             %{
               "timeline_id" => "timeline:cmd_provider",
               "transition_decision" => "review",
               "required_operator_action" => "review_activity_approval",
               "status_transition_decision" => "record",
               "approval_transition_decision" => "review",
               "invalid_activity_input" => false,
               "model_limits" => [
                 "artifact_level_only",
                 "no_schedule_mutation",
                 "no_command_execution",
                 "derived_identity_when_no_persistent_timeline_id"
               ],
               "assumptions" => %{
                 "artifact_only" => true,
                 "no_cadence_import" => true,
                 "no_command_execution" => true,
                 "no_operator_authority_grant" => true,
                 "no_schedule_mutation" => true
               }
             },
             %{
               "timeline_id" => "timeline:done_keep",
               "transition_decision" => "none",
               "required_operator_action" => "none",
               "import_action" => "record_preserved_activity",
               "invalid_activity_input" => false
             },
             %{
               "timeline_id" => "timeline:dup",
               "transition_decision" => "review",
               "timeline_identity_collision" => true,
               "planned_activity_ids" => ["dup_a", "dup_b"],
               "required_operator_actions" => ["review_duplicate_timeline_identity"]
             },
             %{
               "timeline_id" => "timeline:obs_record",
               "transition_decision" => "record",
               "required_operator_action" => "record_timeline_change",
               "import_action" => "import_replacement_activity",
               "invalid_activity_input" => false
             }
           ] = summary["rows"]

    assert Enum.map(summary["rows"], & &1["rank"]) == [1, 2, 3, 4]

    assert [
             %{"timeline_id" => "timeline:cmd_provider"},
             %{"timeline_id" => "timeline:dup"}
           ] = summary["review_rows"]

    stale_operator_reason_counts =
      put_in(summary, ["operator_action_reason_counts", "activity_execution_recorded"], 1)

    assert {:error, validation_report} = Schema.validate_artifact(stale_operator_reason_counts)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.operator_action_reason_counts" and
                 &1["message"] == "must equal row-derived operator_action_reason_counts")
           )

    stale_operator_reason_routing =
      put_in(
        summary,
        ["review_timeline_ids_by_operator_action_reason", "activity_execution_recorded"],
        []
      )

    assert {:error, validation_report} =
             Schema.validate_artifact(stale_operator_reason_routing)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.review_timeline_ids_by_operator_action_reason" and
                 &1["message"] ==
                   "must equal row-derived review_timeline_ids_by_operator_action_reason")
           )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  defp timeline_activity_status_state_assumption_fields do
    [
      "artifact_only",
      "no_schedule_mutation",
      "no_operator_authority_grant",
      "no_command_execution"
    ]
  end

  defp timeline_activity_state_assumption_fields do
    [
      "artifact_only",
      "no_schedule_mutation",
      "no_command_execution"
    ]
  end

  defp timeline_activity_lifecycle_state_assumption_fields do
    [
      "artifact_only",
      "no_schedule_mutation",
      "no_operator_authority_grant",
      "no_cadence_import",
      "no_command_execution"
    ]
  end

  defp assert_timeline_activity_state_assumptions_schema(schema, fields) do
    assumptions_schema = get_in(schema, ["properties", "assumptions"])

    assert assumptions_schema["type"] == "object"
    assert assumptions_schema["additionalProperties"] == true
    assert assumptions_schema["required"] == fields

    for field <- fields do
      assert get_in(assumptions_schema, ["properties", field]) == %{
               "type" => "boolean",
               "const" => true
             }
    end
  end
end
