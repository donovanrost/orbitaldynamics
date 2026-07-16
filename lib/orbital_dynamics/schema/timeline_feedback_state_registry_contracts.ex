defmodule OrbitalDynamics.Schema.TimelineFeedbackStateRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "timeline_feedback_report.v1" => %{
        "schema_contract" => "timeline_feedback_report.v1",
        "artifact_family" => "timeline_feedback_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "planned_count",
          "realized_count",
          "row_count",
          "status_counts",
          "rows",
          "assumptions"
        ],
        "optional_fields" => [
          "ambiguous_timeline_feedback_count",
          "ambiguous_timeline_match_count",
          "cadence_import_manifest",
          "cadence_import_status_counts",
          "duplicate_realized_feedback_count",
          "duplicate_realized_match_count",
          "execution_uncertainty_declared_count",
          "execution_uncertainty_missing_count",
          "feedback_kind_counts",
          "match_strategy_counts",
          "model_limits",
          "operational_feedback",
          "operational_feedback_excluded_count",
          "operational_feedback_provenance",
          "operator_review_package",
          "planned_protection_decision_counts"
        ],
        "nested_contracts" => ["realized_activity.v1", "operator_review_package.v1"]
      },
      "timeline_activity_state.v1" => %{
        "schema_contract" => "timeline_activity_state.v1",
        "artifact_family" => "timeline_activity_state",
        "schema_version" => 1,
        "required_fields" => [
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
        ],
        "optional_fields" => [
          "activity_id",
          "activity_ids",
          "feedback_kind",
          "feedback_status",
          "approval_transition",
          "match_strategy",
          "planned_approval_category",
          "planned_approval_status",
          "planned_executed",
          "planned_locked",
          "planned_protection_category",
          "planned_protection_decision",
          "planned_protection_reason",
          "planned_status",
          "planned_status_category",
          "planned_timeline_id",
          "realized_approval_category",
          "realized_approval_status",
          "realized_executed",
          "realized_locked",
          "realized_provider_counts",
          "realized_protection_decision",
          "realized_source_quality_counts",
          "realized_status",
          "realized_status_category",
          "realized_timeline_id",
          "realized_trust_boundaries",
          "realized_trust_boundary_status",
          "source_activity_context",
          "source_protection_decision",
          "realized_activity_context",
          "status_transition",
          "timeline_id",
          "timeline_identity"
        ],
        "nested_contracts" => ["timeline_feedback_report.v1"]
      },
      "timeline_activity_precondition_summary.v1" => %{
        "schema_contract" => "timeline_activity_precondition_summary.v1",
        "artifact_family" => "timeline_activity_precondition_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "validation_level",
          "model_limits",
          "precondition_status",
          "blocked_precondition_count",
          "review_precondition_count",
          "blocked_precondition_types",
          "review_precondition_types",
          "preconditions",
          "assumptions"
        ],
        "optional_fields" => [
          "activity_id",
          "timeline_id",
          "activity_type",
          "timeline_identity",
          "dependency_activity_ids",
          "dependency_timeline_ids",
          "exclusive_with_activity_ids",
          "exclusive_with_timeline_ids",
          "allow_overlap",
          "invalid_activity_input",
          "invalid_activity_input_reason",
          "source_activity"
        ],
        "nested_contracts" => []
      }
    }
  end
end
