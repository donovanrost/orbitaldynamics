defmodule OrbitalDynamics.Timeline.LifecycleTransitionReviewPolicy do
  @moduledoc false

  def status_review(
        nil,
        to,
        _executed_statuses,
        terminal_exception_statuses,
        unsupported_activity_status?,
        _repairable_status?
      ) do
    cond do
      unsupported_activity_status?.(to) ->
        transition_review("unsupported_status", true, "unsupported_replacement_status")

      to in terminal_exception_statuses ->
        transition_review("terminal_exception_recorded", true, "added_terminal_exception_status")

      to == "blocked_by_policy" ->
        transition_review("status_blocked", true, "activity_status_blocked_by_policy")

      true ->
        transition_review("status_added", false, "added_activity_status")
    end
  end

  def status_review(
        from,
        nil,
        executed_statuses,
        _terminal_exception_statuses,
        unsupported_activity_status?,
        _repairable_status?
      ) do
    cond do
      unsupported_activity_status?.(from) ->
        transition_review("unsupported_status", true, "unsupported_source_status")

      from in executed_statuses ->
        transition_review("executed_activity_removed", true, "removed_executed_status")

      true ->
        transition_review("status_removed", false, "removed_activity_status")
    end
  end

  def status_review(
        from,
        to,
        executed_statuses,
        terminal_exception_statuses,
        unsupported_activity_status?,
        repairable_status?
      ) do
    cond do
      unsupported_activity_status?.(from) ->
        transition_review("unsupported_status", true, "unsupported_source_status")

      unsupported_activity_status?.(to) ->
        transition_review("unsupported_status", true, "unsupported_replacement_status")

      to == "blocked_by_policy" ->
        transition_review("status_blocked", true, "activity_status_blocked_by_policy")

      from == "blocked_by_policy" and to != "blocked_by_policy" ->
        transition_review("status_block_cleared", true, "blocked_status_cleared")

      from in executed_statuses ->
        transition_review("executed_activity_changed", true, "executed_status_changed")

      to in executed_statuses ->
        transition_review("execution_recorded", false, "activity_execution_recorded")

      from in terminal_exception_statuses and to not in terminal_exception_statuses ->
        transition_review("terminal_exception_reopened", true, "terminal_exception_reopened")

      to in terminal_exception_statuses ->
        transition_review("terminal_exception_recorded", true, "terminal_exception_recorded")

      repairable_status?.(to) ->
        transition_review("repair_status_recorded", true, "repair_status_recorded")

      true ->
        transition_review("status_changed", false, "status_changed")
    end
  end

  def approval_review(
        nil,
        to,
        review_approval_statuses,
        _protected_approval_statuses,
        unsupported_approval_status?
      ) do
    cond do
      unsupported_approval_status?.(to) ->
        transition_review(
          "unsupported_approval_status",
          true,
          "unsupported_replacement_approval_status"
        )

      to == "rejected" ->
        transition_review("approval_rejected", true, "approval_rejected")

      to == "blocked_by_policy" ->
        transition_review("approval_blocked", true, "approval_blocked_by_policy")

      to in review_approval_statuses ->
        transition_review("approval_review_required", true, "approval_requires_review")

      true ->
        transition_review("approval_added", false, "approval_status_added")
    end
  end

  def approval_review(
        from,
        nil,
        _review_approval_statuses,
        protected_approval_statuses,
        unsupported_approval_status?
      ) do
    cond do
      unsupported_approval_status?.(from) ->
        transition_review(
          "unsupported_approval_status",
          true,
          "unsupported_source_approval_status"
        )

      from in protected_approval_statuses ->
        transition_review("protected_approval_removed", true, "protected_approval_removed")

      true ->
        transition_review("approval_removed", false, "approval_status_removed")
    end
  end

  def approval_review(
        from,
        to,
        review_approval_statuses,
        protected_approval_statuses,
        unsupported_approval_status?
      ) do
    cond do
      unsupported_approval_status?.(from) ->
        transition_review(
          "unsupported_approval_status",
          true,
          "unsupported_source_approval_status"
        )

      unsupported_approval_status?.(to) ->
        transition_review(
          "unsupported_approval_status",
          true,
          "unsupported_replacement_approval_status"
        )

      to == "blocked_by_policy" ->
        transition_review("approval_blocked", true, "approval_blocked_by_policy")

      from in protected_approval_statuses and to not in protected_approval_statuses ->
        transition_review("approval_regressed", true, "protected_approval_regressed")

      to == "rejected" ->
        transition_review("approval_rejected", true, "approval_rejected")

      to in review_approval_statuses ->
        transition_review("approval_review_required", true, "approval_requires_review")

      to in protected_approval_statuses ->
        transition_review("approval_granted", true, "approval_grant_requires_operator_authority")

      true ->
        transition_review("approval_changed", false, "approval_status_changed")
    end
  end

  def requires_operator_review?(nil), do: false

  def requires_operator_review?(%{"requires_operator_review" => requires_review?}),
    do: requires_review?

  defp transition_review(category, requires_review?, reason) do
    %{
      "transition_category" => category,
      "requires_operator_review" => requires_review?,
      "operator_action_reason" => reason
    }
  end
end
