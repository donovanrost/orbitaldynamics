defmodule OrbitalDynamics.Schema.PlanChangeRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "candidate_rejection_report.v1" => %{
        "schema_contract" => "candidate_rejection_report.v1",
        "artifact_family" => "candidate_rejection_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source",
          "candidate_count",
          "row_count",
          "rejected_count",
          "not_rejected_count",
          "reviewable_count",
          "rejection_reason_counts",
          "rows",
          "assumptions"
        ],
        "optional_fields" => [
          "model_limits",
          "invalid_candidate_input_count",
          "rejected_candidate_ids",
          "not_rejected_candidate_ids",
          "reviewable_candidate_ids",
          "invalid_candidate_input_ids",
          "candidate_id_sets_by_rejection_reason",
          "candidate_ids_by_required_operator_action",
          "required_operator_action_counts"
        ],
        "nested_contracts" => ["planned_activity.v1"]
      },
      "plan_delta.v1" => %{
        "schema_contract" => "plan_delta.v1",
        "artifact_family" => "plan_delta",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "activity_id",
          "activity_type",
          "status",
          "repair_action"
        ],
        "optional_fields" => [
          "reason",
          "requires_approval",
          "replacement_activity_id",
          "source_timeline_id",
          "replacement_timeline_id",
          "planned",
          "realized",
          "timeline_link",
          "source_activity_context",
          "replacement_activity_context"
        ],
        "nested_contracts" => ["planned_activity.v1", "realized_activity.v1"]
      }
    }
  end
end
