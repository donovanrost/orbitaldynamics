defmodule OrbitalDynamics.Schema.TimelinePreservationRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "timeline_preservation_report.v1" => %{
        "schema_contract" => "timeline_preservation_report.v1",
        "artifact_family" => "timeline_preservation_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source",
          "activity_count",
          "mutable_activity_count",
          "preserve_activity_count",
          "review_change_activity_count",
          "preservation_sensitive_activity_count",
          "timeline_preservation_status",
          "protection_decision_counts",
          "protection_category_counts",
          "protection_reason_counts",
          "preserve_activity_ids",
          "preserve_timeline_ids",
          "review_change_activity_ids",
          "review_change_timeline_ids",
          "mutable_activity_ids",
          "preservation_sensitive_activity_ids",
          "preservation_sensitive_timeline_ids",
          "activity_id_sets_by_protection_decision",
          "timeline_id_sets_by_protection_decision",
          "activity_id_sets_by_protection_category",
          "timeline_id_sets_by_protection_category",
          "activity_id_sets_by_protection_reason",
          "timeline_id_sets_by_protection_reason",
          "rows",
          "assumptions"
        ],
        "optional_fields" => ["model_limits"],
        "nested_contracts" => []
      },
      "timeline_preservation_status.v1" => %{
        "schema_contract" => "timeline_preservation_status.v1",
        "artifact_family" => "timeline_preservation_status",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "timeline_preservation_status",
          "requires_preservation",
          "requires_operator_review",
          "activity_id",
          "protection_decision",
          "protection_category",
          "protection_reason",
          "assumptions"
        ],
        "optional_fields" => [
          "timeline_id",
          "status",
          "approval_status",
          "locked",
          "approved",
          "timeline_identity",
          "invalid_activity_input",
          "invalid_activity_input_reason",
          "model_limits"
        ],
        "nested_contracts" => []
      },
      "timeline_lifecycle_state_summary.v1" => %{
        "schema_contract" => "timeline_lifecycle_state_summary.v1",
        "artifact_family" => "timeline_lifecycle_state_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source",
          "validation_level",
          "model_limits",
          "planned_activity_count",
          "realized_activity_count",
          "row_count",
          "recordable_count",
          "preserved_count",
          "review_required_count",
          "duplicate_timeline_identity_count",
          "invalid_activity_input_count",
          "transition_decision_counts",
          "required_operator_action_counts",
          "import_action_counts",
          "rows",
          "review_rows",
          "assumptions"
        ],
        "optional_fields" => [
          "planned_status_category_counts",
          "realized_status_category_counts",
          "planned_approval_category_counts",
          "realized_approval_category_counts",
          "status_transition_category_counts",
          "approval_transition_category_counts",
          "recordable_timeline_ids",
          "preserved_timeline_ids",
          "review_timeline_ids",
          "review_activity_ids",
          "invalid_activity_input_ids",
          "review_timeline_ids_by_required_operator_action",
          "operator_action_reason_counts",
          "review_timeline_ids_by_operator_action_reason",
          "review_timeline_ids_by_status_transition_category",
          "review_timeline_ids_by_approval_transition_category"
        ],
        "nested_contracts" => []
      }
    }
  end
end
