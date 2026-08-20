defmodule OrbitalDynamics.Schema.TimelineTransitionRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "timeline_revision.v1" => %{
        "schema_contract" => "timeline_revision.v1",
        "artifact_family" => "timeline_revision",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "identity_scheme",
          "canonicalization",
          "prior_revision_id",
          "transition_batch_id",
          "replacement_revision_id"
        ],
        "optional_fields" => [],
        "nested_contracts" => []
      },
      "timeline_transition_application_report.v1" => %{
        "schema_contract" => "timeline_transition_application_report.v1",
        "artifact_family" => "timeline_transition_application_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source",
          "source_activity_count",
          "replacement_activity_count",
          "application_count",
          "selected_activity_count",
          "review_required_count",
          "applications",
          "assumptions"
        ],
        "optional_fields" => [
          "application_status_counts",
          "approval_transition_category_counts",
          "approval_transition_counts",
          "model_limits",
          "preserved_source_count",
          "recorded_replacement_count",
          "required_operator_action_counts",
          "selected_activities",
          "selected_timeline_integrity_issue_count",
          "selected_timeline_integrity_issue_types",
          "selected_timeline_integrity_review_count",
          "status_transition_category_counts",
          "status_transition_counts",
          "timeline_revision",
          "transition_decision_counts",
          "withheld_review_count"
        ],
        "nested_contracts" => ["timeline_diff_report.v1", "timeline_revision.v1"]
      },
      "timeline_transition_application_summary.v1" => %{
        "schema_contract" => "timeline_transition_application_summary.v1",
        "artifact_family" => "timeline_transition_application_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "validation_level",
          "source_artifact_type",
          "source",
          "source_activity_count",
          "replacement_activity_count",
          "application_count",
          "selected_activity_count",
          "review_required_count",
          "preserved_source_count",
          "recorded_replacement_count",
          "withheld_review_count",
          "selected_timeline_integrity_review_count",
          "selected_timeline_integrity_issue_count",
          "selected_timeline_integrity_issue_types",
          "application_status_counts",
          "transition_decision_counts",
          "required_operator_action_counts",
          "status_transition_category_counts",
          "approval_transition_category_counts",
          "selected_activity_ids",
          "selected_timeline_ids",
          "review_timeline_ids",
          "review_activity_ids",
          "review_timeline_ids_by_required_operator_action",
          "review_timeline_ids_by_status_transition_category",
          "review_timeline_ids_by_approval_transition_category",
          "preserved_source_timeline_ids",
          "recorded_replacement_timeline_ids",
          "withheld_review_timeline_ids",
          "review_applications",
          "assumptions",
          "model_limits"
        ],
        "optional_fields" => ["timeline_revision"],
        "nested_contracts" => [
          "timeline_revision.v1",
          "timeline_transition_application_report.v1"
        ]
      }
    }
  end
end
