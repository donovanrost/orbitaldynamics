defmodule OrbitalDynamics.Schema.OperationalTimelineRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "operational_timeline_report.v1" => %{
        "schema_contract" => "operational_timeline_report.v1",
        "artifact_family" => "operational_timeline_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source",
          "activity_count",
          "row_count",
          "contact_count",
          "command_count",
          "locked_count",
          "approved_count",
          "executed_count",
          "source_window_lineage_count",
          "rows",
          "assumptions"
        ],
        "optional_fields" => [
          "model_limits",
          "valid_activity_count",
          "invalid_activity_input_count",
          "invalid_activity_input_ids",
          "terminal_exception_count",
          "activity_status_counts",
          "approval_status_counts",
          "required_operator_action_counts",
          "cadence_import_status_counts",
          "operational_kind_counts",
          "execution_uncertainty_declared_count",
          "execution_uncertainty_missing_count",
          "dependency_count",
          "dependency_issue_count",
          "exclusivity_count",
          "exclusivity_issue_count",
          "timeline_integrity_review_count",
          "timeline_integrity_issue_count",
          "duplicate_timeline_identity_count",
          "duplicate_timeline_identity_activity_count",
          "duplicate_dependency_activity_ids",
          "duplicate_dependency_timeline_ids",
          "duplicate_exclusivity_activity_ids",
          "duplicate_exclusivity_timeline_ids"
        ],
        "nested_contracts" => []
      }
    }
  end
end
