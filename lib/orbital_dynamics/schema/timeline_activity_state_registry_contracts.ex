defmodule OrbitalDynamics.Schema.TimelineActivityStateRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "timeline_activity_status_state.v1" => %{
        "schema_contract" => "timeline_activity_status_state.v1",
        "artifact_family" => "timeline_activity_status_state",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "validation_level",
          "activity_id",
          "timeline_id",
          "transition_decision",
          "review_required",
          "required_operator_action",
          "operator_action_reason",
          "import_action",
          "assumptions"
        ],
        "optional_fields" => [
          "planned_activity_id",
          "realized_activity_id",
          "planned_timeline_id",
          "realized_timeline_id",
          "planned_status",
          "realized_status",
          "planned_status_category",
          "realized_status_category",
          "status_transition",
          "invalid_activity_input",
          "invalid_activity_input_count",
          "invalid_activity_input_reasons",
          "planned_activity_context",
          "realized_activity_context",
          "model_limits"
        ],
        "nested_contracts" => []
      },
      "timeline_activity_approval_state.v1" => %{
        "schema_contract" => "timeline_activity_approval_state.v1",
        "artifact_family" => "timeline_activity_approval_state",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "validation_level",
          "activity_id",
          "timeline_id",
          "transition_decision",
          "review_required",
          "required_operator_action",
          "operator_action_reason",
          "import_action",
          "assumptions"
        ],
        "optional_fields" => [
          "planned_activity_id",
          "realized_activity_id",
          "planned_timeline_id",
          "realized_timeline_id",
          "planned_approval_status",
          "realized_approval_status",
          "planned_approval_category",
          "realized_approval_category",
          "approval_transition",
          "invalid_activity_input",
          "invalid_activity_input_count",
          "invalid_activity_input_reasons",
          "planned_activity_context",
          "realized_activity_context",
          "model_limits"
        ],
        "nested_contracts" => []
      },
      "timeline_activity_lifecycle_state.v1" => %{
        "schema_contract" => "timeline_activity_lifecycle_state.v1",
        "artifact_family" => "timeline_activity_lifecycle_state",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "validation_level",
          "activity_id",
          "timeline_id",
          "transition_decision",
          "review_required",
          "required_operator_action",
          "required_operator_actions",
          "import_action",
          "assumptions"
        ],
        "optional_fields" => [
          "planned_activity_id",
          "realized_activity_id",
          "planned_timeline_id",
          "realized_timeline_id",
          "planned_status",
          "realized_status",
          "planned_status_category",
          "realized_status_category",
          "planned_approval_status",
          "realized_approval_status",
          "planned_approval_category",
          "realized_approval_category",
          "planned_locked",
          "realized_locked",
          "planned_executed",
          "realized_executed",
          "status_transition",
          "approval_transition",
          "status_transition_decision",
          "approval_transition_decision",
          "operator_action_reasons",
          "planned_protection_decision",
          "realized_protection_decision",
          "invalid_activity_input",
          "invalid_activity_input_count",
          "invalid_activity_input_reasons",
          "planned_activity_context",
          "realized_activity_context",
          "model_limits"
        ],
        "nested_contracts" => []
      }
    }
  end
end
