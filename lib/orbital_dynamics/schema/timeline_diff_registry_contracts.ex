defmodule OrbitalDynamics.Schema.TimelineDiffRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "timeline_diff_report.v1" => %{
        "schema_contract" => "timeline_diff_report.v1",
        "artifact_family" => "timeline_diff_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source",
          "source_activity_count",
          "replacement_activity_count",
          "row_count",
          "added_count",
          "removed_count",
          "changed_count",
          "unchanged_count",
          "review_required_count",
          "rows",
          "assumptions"
        ],
        "optional_fields" => [
          "model_limits",
          "diff_status_counts",
          "required_operator_action_counts",
          "transition_decision_counts",
          "changed_field_counts",
          "status_transition_counts",
          "approval_transition_counts",
          "status_transition_category_counts",
          "approval_transition_category_counts",
          "valid_source_activity_count",
          "valid_replacement_activity_count",
          "invalid_source_activity_input_count",
          "invalid_replacement_activity_input_count",
          "invalid_source_activity_input_ids",
          "invalid_replacement_activity_input_ids",
          "duplicate_timeline_identity_count",
          "duplicate_source_timeline_identity_count",
          "duplicate_replacement_timeline_identity_count"
        ],
        "nested_contracts" => ["operational_timeline_report.v1"]
      },
      "timeline_diff_summary.v1" => %{
        "schema_contract" => "timeline_diff_summary.v1",
        "artifact_family" => "timeline_diff_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "validation_level",
          "source_artifact_type",
          "source",
          "source_activity_count",
          "replacement_activity_count",
          "row_count",
          "added_count",
          "removed_count",
          "changed_count",
          "unchanged_count",
          "review_required_count",
          "diff_status_counts",
          "transition_decision_counts",
          "required_operator_action_counts",
          "changed_field_counts",
          "status_transition_category_counts",
          "approval_transition_category_counts",
          "added_timeline_ids",
          "removed_timeline_ids",
          "changed_timeline_ids",
          "unchanged_timeline_ids",
          "duplicate_timeline_identity_ids",
          "invalid_source_activity_input_ids",
          "invalid_replacement_activity_input_ids",
          "review_timeline_ids",
          "review_timeline_ids_by_required_operator_action",
          "review_timeline_ids_by_status_transition_category",
          "review_timeline_ids_by_approval_transition_category",
          "timeline_ids_by_changed_field",
          "review_rows",
          "assumptions",
          "model_limits"
        ],
        "optional_fields" => [
          "duplicate_timeline_identity_count",
          "invalid_source_activity_input_count",
          "invalid_replacement_activity_input_count"
        ],
        "nested_contracts" => ["timeline_diff_report.v1"]
      }
    }
  end
end
