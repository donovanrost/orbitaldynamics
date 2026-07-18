defmodule OrbitalDynamics.Timeline.OperationalActionPolicy do
  @moduledoc false

  def cadence_import_status(activity, operational_kind, invalid_cadence_import?) do
    cond do
      invalid_cadence_import?.(activity) ->
        "invalid"

      is_map(Map.get(activity, "cadence_import")) ->
        "present"

      operational_kind in ["contact", "command"] ->
        "missing"

      true ->
        "not_applicable"
    end
  end

  def required_operator_action(
        activity,
        operational_kind,
        cadence_import_status,
        terminal_exception_statuses,
        executed_statuses,
        activity_status,
        activity_approval_status,
        activity_schedule_conflict_status,
        provider_execution_failure_reason,
        cadence_import_issue,
        activity_locked?
      ) do
    status = activity_status.(activity)
    approval_status = activity_approval_status.(activity)
    conflict_status = activity_schedule_conflict_status.(activity)
    provider_failure_reason = provider_execution_failure_reason.(activity, operational_kind)

    cond do
      status in terminal_exception_statuses ->
        {"review_terminal_activity_exception", "activity_status_#{status}_requires_review"}

      is_binary(provider_failure_reason) ->
        {"review_terminal_activity_exception", provider_failure_reason}

      status == "blocked_by_policy" ->
        {"resolve_blocked_activity", "activity_status_blocked_by_policy"}

      approval_status == "rejected" ->
        {"resolve_rejected_activity", "approval_status_rejected"}

      approval_status == "blocked_by_policy" ->
        {"resolve_blocked_activity", "approval_status_blocked_by_policy"}

      status in executed_statuses ->
        {"none_terminal_activity", "activity_status_terminal"}

      conflict_status in ["conflicted", "conflict", "overlap"] ->
        {"resolve_contact_conflict", "schedule_conflict_status_#{conflict_status}"}

      cadence_import_status == "invalid" ->
        {"review_invalid_cadence_import",
         cadence_import_issue.(Map.get(activity, "cadence_import")) ||
           "cadence_import_invalid_shape"}

      command_review_required?(activity, operational_kind, approval_status) ->
        {"review_command_contact", "command_boundary_requires_review"}

      approval_status in ["pending", "operator_review_required", "not_evaluated"] ->
        {"review_activity_approval", "approval_status_#{approval_status}"}

      cadence_import_status == "missing" ->
        {"prepare_cadence_import", "cadence_import_missing"}

      activity_locked?.(activity) ->
        {"none_locked_activity", "activity_locked"}

      true ->
        {"monitor_activity", "no_operator_action_required"}
    end
  end

  defp command_review_required?(_activity, operational_kind, approval_status) do
    operational_kind == "command" and
      approval_status not in ["approved", "auto_approvable", "locked"]
  end
end
