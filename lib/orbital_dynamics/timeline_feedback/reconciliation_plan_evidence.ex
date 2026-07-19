defmodule OrbitalDynamics.TimelineFeedback.ReconciliationPlanEvidence do
  @moduledoc false

  def context(planned) do
    %{
      "dependency_activity_ids" => value(planned, "dependency_activity_ids"),
      "dependency_timeline_ids" => value(planned, "dependency_timeline_ids"),
      "exclusive_with_activity_ids" => value(planned, "exclusive_with_activity_ids"),
      "exclusive_with_timeline_ids" => value(planned, "exclusive_with_timeline_ids"),
      "cadence_import_status" => value(planned, "cadence_import_status"),
      "cadence_import_type" => value(planned, "cadence_import_type"),
      "cadence_import_id" => value(planned, "cadence_import_id"),
      "cadence_import_contract" => value(planned, "cadence_import_contract"),
      "has_cadence_import" => value(planned, "has_cadence_import"),
      "planned_operator_action" => value(planned, "required_operator_action"),
      "planned_operator_action_reason" => value(planned, "operator_action_reason"),
      "superseded_planned_operator_action" =>
        value(planned, "superseded_required_operator_action"),
      "superseded_planned_operator_action_reason" =>
        value(planned, "superseded_operator_action_reason"),
      "timeline_integrity_status" => value(planned, "timeline_integrity_status"),
      "timeline_integrity_issue_count" => value(planned, "timeline_integrity_issue_count"),
      "timeline_integrity_issue_types" => value(planned, "timeline_integrity_issue_types"),
      "timeline_integrity_issues" => value(planned, "timeline_integrity_issues"),
      "invalid_activity_input" => value(planned, "invalid_activity_input"),
      "invalid_activity_input_reason" => value(planned, "invalid_activity_input_reason"),
      "missing_dependency_activity_ids" => value(planned, "missing_dependency_activity_ids"),
      "missing_dependency_timeline_ids" => value(planned, "missing_dependency_timeline_ids"),
      "dependency_cycle_activity_ids" => value(planned, "dependency_cycle_activity_ids"),
      "dependency_cycle_timeline_ids" => value(planned, "dependency_cycle_timeline_ids"),
      "dependency_order_violation_activity_ids" =>
        value(planned, "dependency_order_violation_activity_ids"),
      "dependency_order_violation_timeline_ids" =>
        value(planned, "dependency_order_violation_timeline_ids"),
      "exclusivity_violation_activity_ids" =>
        value(planned, "exclusivity_violation_activity_ids"),
      "exclusivity_violation_timeline_ids" =>
        value(planned, "exclusivity_violation_timeline_ids"),
      "exclusivity_violation_group" => value(planned, "exclusivity_violation_group")
    }
  end

  defp value(nil, _key), do: nil
  defp value(map, key), do: Map.get(map, key)
end
