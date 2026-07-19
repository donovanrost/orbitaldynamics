defmodule OrbitalDynamics.MissionPlan.Activity.LifecycleTransition do
  @moduledoc false

  def status_review(status, status, _status_preserving),
    do: {true, false, "status_unchanged"}

  def status_review(:invalid, _to, _status_preserving),
    do: {false, true, "invalid_status_change_requires_review"}

  def status_review(_from, :invalid, _status_preserving),
    do: {false, true, "invalid_status_requires_review"}

  def status_review(:blocked_by_policy, _to, _status_preserving),
    do: {false, true, "blocked_status_clear_requires_review"}

  def status_review(_from, :blocked_by_policy, _status_preserving),
    do: {false, true, "policy_block_requires_review"}

  def status_review(from, _to, status_preserving) do
    if from in status_preserving do
      {false, true, "terminal_or_executed_status_change_requires_review"}
    else
      {true, false, "status_transition_allowed"}
    end
  end

  def status_category(status, status_preserving, activity_statuses) do
    cond do
      status in status_preserving -> "terminal_or_executed"
      status == :blocked_by_policy -> "blocked"
      status == :invalid -> "invalid"
      status == :executing -> "executing"
      status == :delayed -> "repairable"
      status in activity_statuses -> "planned"
    end
  end

  def approval_review(status, status),
    do: {true, false, "approval_status_unchanged"}

  def approval_review(:blocked_by_policy, _to),
    do: {false, true, "blocked_approval_clear_requires_review"}

  def approval_review(:rejected, _to),
    do: {false, true, "rejected_approval_clear_requires_review"}

  def approval_review(:locked, _to),
    do: {false, true, "locked_approval_change_requires_review"}

  def approval_review(_from, to) when to in [:approved, :auto_approvable],
    do: {false, true, "approval_grant_requires_operator_authority"}

  def approval_review(_from, :not_required),
    do: {false, true, "approval_review_clear_requires_operator_authority"}

  def approval_review(_from, _to),
    do: {true, false, "approval_transition_allowed"}

  def approval_category(status) do
    cond do
      status in [:approved, :auto_approvable] -> "approval_granted"
      status in [:pending, :operator_review_required] -> "review_required"
      status == :not_evaluated -> "not_evaluated"
      status == :not_required -> "not_required"
      status == :blocked_by_policy -> "blocked"
      status == :locked -> "locked"
      status == :rejected -> "rejected"
    end
  end

  def event!(event, aliases, events) when is_atom(event) do
    event
    |> Atom.to_string()
    |> event!(aliases, events)
  end

  def event!(event, aliases, events) when is_binary(event) do
    normalized =
      event
      |> String.trim()
      |> String.downcase()
      |> String.replace(~r/[\s-]+/, "_")

    cond do
      Map.has_key?(aliases, normalized) ->
        Map.fetch!(aliases, normalized)

      event = Enum.find(events, &(Atom.to_string(&1) == normalized)) ->
        event

      true ->
        invalid_event!(events)
    end
  end

  def event!(_event, _aliases, events), do: invalid_event!(events)

  defp invalid_event!(events) do
    raise ArgumentError, "lifecycle event must be one of #{inspect(events)}"
  end
end
