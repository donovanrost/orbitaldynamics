defmodule OrbitalDynamics.CampaignPlanner.RepairActivityDispatch do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    ActivityTiming,
    DownlinkActivityNormalization,
    RepairActivityStateTransitions,
    RepairManeuverTransitions,
    RepairPolicySemantics,
    RepairRealizedState,
    RepairReplacementTransitions,
    ValueEncoding
  }

  alias OrbitalDynamics.Timeline

  @realized_preserved_executed_statuses ~w(completed executed partial)
  @realized_failure_statuses ~w(missed failed canceled cancelled rejected)
  @terminal_realized_statuses @realized_preserved_executed_statuses ++ @realized_failure_statuses

  def repair(activity, acc, context) do
    activity = ValueEncoding.stringify_keys(activity)
    activity_id = ActivityIdentity.activity_id(activity)

    case RepairRealizedState.activity_match(context.realized_by_id, activity_id) do
      {:ambiguous, realized_rows} ->
        RepairActivityStateTransitions.review_ambiguous(activity, realized_rows, acc)

      {:ok, realized} ->
        status = realized_status(activity, realized, context.current_epoch_s)

        repair_with_status(activity, realized, status, acc, context)
    end
  end

  defp repair_with_status(activity, realized, status, acc, context) do
    cond do
      status in @realized_preserved_executed_statuses and
          context.repair_policy.preserve_executed? ->
        RepairActivityStateTransitions.preserve_executed(activity, realized, status, acc)

      preserve_locked_before_repair?(activity, status, context) ->
        RepairActivityStateTransitions.preserve_locked(activity, realized, status, acc)

      RepairPolicySemantics.degraded_incompatible?(
        activity,
        context.degraded_modes,
        context.repair_policy
      ) ->
        RepairActivityStateTransitions.suppress_degraded(activity, realized, status, acc)

      status == "missed" and DownlinkActivityNormalization.downlink?(activity) ->
        RepairReplacementTransitions.move_missed_downlink(activity, realized, acc, context)

      status == "failed" and activity["type"] == "observe" ->
        RepairReplacementTransitions.replace_failed_observation(
          activity,
          realized,
          acc,
          context
        )

      status == "delayed" and maneuver_activity?(activity) ->
        RepairManeuverTransitions.move_delayed(activity, realized, acc)

      status in @terminal_realized_statuses ->
        RepairActivityStateTransitions.cancel(activity, realized, status, acc)

      ActivityTiming.within_remaining_horizon?(activity, context.remaining_horizon) ->
        RepairActivityStateTransitions.preserve(activity, realized, status, acc)

      true ->
        acc
    end
  end

  defp preserve_locked_before_repair?(activity, status, context) do
    decision =
      Timeline.protection_decision(activity,
        realized_status: status,
        preserve_approved?: context.repair_policy.preserve_approved?,
        preserve_executed?: context.repair_policy.preserve_executed?,
        allow_locked_changes?: context.repair_policy.allow_locked_changes?
      )

    decision["protection_decision"] == "preserve" and
      decision["protection_category"] == "locked_or_approved" and
      status not in @terminal_realized_statuses
  end

  defp realized_status(activity, nil, current_epoch_s) do
    if ActivityTiming.activity_end(activity) <= current_epoch_s,
      do: "unreported_past",
      else: "planned"
  end

  defp realized_status(_activity, realized, _current_epoch_s),
    do: RepairRealizedState.normalize_status_value(realized["status"])

  defp maneuver_activity?(activity), do: activity["type"] in ["maneuver", "impulsive_burn"]
end
