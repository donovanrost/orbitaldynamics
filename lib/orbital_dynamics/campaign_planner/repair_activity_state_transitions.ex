defmodule OrbitalDynamics.CampaignPlanner.RepairActivityStateTransitions do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    RepairAccumulator,
    RepairRealizedState,
    ValueEncoding
  }

  def review_ambiguous(activity, realized_rows, acc) do
    reason = "ambiguous_realized_activity_feedback"

    activity =
      put_repair_metadata(activity, %{
        "action" => "review_realized_feedback",
        "reason" => reason,
        "realized_status" => "ambiguous",
        "realized_feedback_count" => length(realized_rows),
        "realized_feedback_statuses" => RepairRealizedState.feedback_statuses(realized_rows),
        "requires_approval" => true
      })

    acc
    |> RepairAccumulator.add_activity(activity)
    |> RepairAccumulator.add_ambiguous_realized_delta(activity, realized_rows, reason)
    |> RepairAccumulator.add_approval_requirement(activity, "review_realized_feedback", reason)
    |> RepairAccumulator.add_warning(
      "ambiguous realized feedback for #{ActivityIdentity.activity_id(activity)} requires operator review"
    )
  end

  def suppress_degraded(activity, realized, status, acc) do
    reason = "spacecraft_degraded_mode_suppressed_incompatible_payload_activity"

    acc
    |> RepairAccumulator.add_delta(activity, realized, status, "suppressed", reason, nil, true)
    |> RepairAccumulator.add_approval_requirement(activity, "cancel", reason)
    |> RepairAccumulator.add_warning(
      "spacecraft degraded mode suppressed #{ActivityIdentity.activity_id(activity)}"
    )
  end

  def preserve_executed(activity, realized, status, acc) do
    activity =
      put_repair_metadata(
        activity,
        %{
          "action" => "preserved_executed",
          "reason" => "activity_already_#{status}",
          "realized_status" => status,
          "completed_fraction" => Map.get(realized || %{}, "completed_fraction"),
          "actual_starts_at_s" => Map.get(realized || %{}, "actual_starts_at_s"),
          "actual_ends_at_s" => Map.get(realized || %{}, "actual_ends_at_s"),
          "requires_approval" => false
        }
        |> ValueEncoding.compact_map()
      )

    acc
    |> RepairAccumulator.add_activity(activity)
    |> RepairAccumulator.add_delta(
      activity,
      realized,
      status,
      "preserved_executed",
      "already_#{status}",
      nil,
      false
    )
  end

  def cancel(activity, realized, status, acc) do
    reason = "realized_status_#{status}_removed_from_remaining_plan"

    acc
    |> RepairAccumulator.add_delta(activity, realized, status, "canceled", reason, nil, true)
    |> RepairAccumulator.add_approval_requirement(activity, "cancel", reason)
  end

  def preserve_locked(activity, realized, status, acc) do
    activity =
      put_repair_metadata(activity, %{
        "action" => "preserved",
        "reason" => "activity_locked_or_approved",
        "realized_status" => status,
        "requires_approval" => false
      })

    acc
    |> RepairAccumulator.add_activity(activity)
    |> RepairAccumulator.add_delta(
      activity,
      realized,
      status,
      "preserved",
      "activity_locked_or_approved",
      nil,
      false
    )
  end

  def preserve(activity, realized, status, acc) do
    activity =
      put_repair_metadata(activity, %{
        "action" => "preserved",
        "reason" => "still_viable_in_remaining_horizon",
        "realized_status" => status,
        "requires_approval" => false
      })

    acc
    |> RepairAccumulator.add_activity(activity)
    |> RepairAccumulator.add_delta(
      activity,
      realized,
      status,
      "preserved",
      "still_viable_in_remaining_horizon",
      nil,
      false
    )
  end

  defp put_repair_metadata(activity, metadata) do
    Map.update(activity, "repair", metadata, &Map.merge(&1, metadata))
  end
end
