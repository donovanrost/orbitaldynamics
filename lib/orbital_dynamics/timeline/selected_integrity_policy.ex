defmodule OrbitalDynamics.Timeline.SelectedIntegrityPolicy do
  @moduledoc false

  def gate_application(
        application,
        selected_activity,
        timeline_integrity_review?,
        list_value,
        compact_map
      ) do
    if timeline_integrity_review?.(selected_activity) do
      issue_types = list_value.(selected_activity, "timeline_integrity_issue_types")

      application
      |> Map.put("requires_operator_review", true)
      |> put_selected_integrity_review_action()
      |> put_selected_integrity_application_status()
      |> Map.merge(context(selected_activity, list_value))
      |> Map.update("reason", reason(issue_types), fn reason ->
        if reason in [nil, "no_timeline_change"],
          do: reason(issue_types),
          else: reason
      end)
      |> compact_map.()
    else
      application
    end
  end

  def context(selected_activity, list_value) do
    %{
      "selected_timeline_integrity_status" => selected_activity["timeline_integrity_status"],
      "selected_timeline_integrity_issue_count" =>
        selected_activity["timeline_integrity_issue_count"],
      "selected_timeline_integrity_issue_types" =>
        list_value.(selected_activity, "timeline_integrity_issue_types"),
      "selected_timeline_integrity_issues" => selected_activity["timeline_integrity_issues"],
      "selected_missing_dependency_activity_ids" =>
        selected_activity["missing_dependency_activity_ids"],
      "selected_missing_dependency_timeline_ids" =>
        selected_activity["missing_dependency_timeline_ids"],
      "selected_self_dependency_activity_ids" =>
        selected_activity["self_dependency_activity_ids"],
      "selected_self_dependency_timeline_ids" =>
        selected_activity["self_dependency_timeline_ids"],
      "selected_duplicate_dependency_activity_ids" =>
        selected_activity["duplicate_dependency_activity_ids"],
      "selected_duplicate_dependency_timeline_ids" =>
        selected_activity["duplicate_dependency_timeline_ids"],
      "selected_duplicate_exclusivity_activity_ids" =>
        selected_activity["duplicate_exclusivity_activity_ids"],
      "selected_duplicate_exclusivity_timeline_ids" =>
        selected_activity["duplicate_exclusivity_timeline_ids"],
      "selected_dependency_cycle_activity_ids" =>
        selected_activity["dependency_cycle_activity_ids"],
      "selected_dependency_cycle_timeline_ids" =>
        selected_activity["dependency_cycle_timeline_ids"],
      "selected_dependency_order_violation_activity_ids" =>
        selected_activity["dependency_order_violation_activity_ids"],
      "selected_dependency_order_violation_timeline_ids" =>
        selected_activity["dependency_order_violation_timeline_ids"],
      "selected_exclusivity_violation_activity_ids" =>
        selected_activity["exclusivity_violation_activity_ids"],
      "selected_exclusivity_violation_timeline_ids" =>
        selected_activity["exclusivity_violation_timeline_ids"],
      "selected_exclusivity_violation_group" => selected_activity["exclusivity_violation_group"]
    }
  end

  def reason([]), do: "selected_timeline_integrity_issue_requires_review"

  def reason(issue_types) do
    "selected_timeline_integrity_issue_requires_review:#{Enum.join(issue_types, ",")}"
  end

  defp put_selected_integrity_review_action(%{"required_operator_action" => action} = application)
       when action in ["none", "record_timeline_change", nil] do
    Map.put(application, "required_operator_action", "review_timeline_integrity")
  end

  defp put_selected_integrity_review_action(application), do: application

  defp put_selected_integrity_application_status(%{"application_status" => status} = application)
       when status in ["source_unchanged", "replacement_unchanged", "replacement_recorded"] do
    Map.put(application, "application_status", "selected_timeline_integrity_review_required")
  end

  defp put_selected_integrity_application_status(application), do: application
end
