defmodule OrbitalDynamics.CampaignPlanner.RepairManeuverTransitions do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    ActivityTiming,
    RepairAccumulator,
    ScalarValues
  }

  def move_delayed(activity, realized, acc) do
    actual_start = realized["actual_starts_at_s"] || realized["actual_start_s"]

    delay_s =
      max(
        0.0,
        ScalarValues.numeric!(actual_start, "actual_starts_at_s") -
          ActivityTiming.activity_start(activity)
      )

    reason = "delayed_maneuver_shifted_and_downstream_windows_marked_affected"

    moved =
      activity
      |> ActivityTiming.shift_activity(delay_s)
      |> put_repair_metadata(%{
        "action" => "moved",
        "reason" => reason,
        "realized_status" => "delayed",
        "requires_approval" => true,
        "schedule_churn_s" => delay_s
      })

    acc
    |> RepairAccumulator.add_activity(moved)
    |> RepairAccumulator.add_delta(
      activity,
      realized,
      "delayed",
      "moved",
      reason,
      ActivityIdentity.activity_id(moved),
      true,
      moved
    )
    |> RepairAccumulator.add_approval_requirement(moved, "approve_delayed_maneuver", reason)
    |> RepairAccumulator.track_delayed_maneuver(activity, delay_s)
  end

  def mark_downstream_effects(%{delayed_maneuvers: []} = acc), do: acc

  def mark_downstream_effects(acc) do
    affected =
      acc.delayed_maneuvers
      |> Enum.flat_map(fn %{"activity" => maneuver} ->
        acc.activities
        |> Enum.reject(
          &(ActivityIdentity.activity_id(&1) == ActivityIdentity.activity_id(maneuver))
        )
        |> Enum.filter(fn activity ->
          ActivityIdentity.same_scenario?(activity, maneuver) and
            ActivityTiming.activity_start(activity) > ActivityTiming.activity_start(maneuver)
        end)
        |> Enum.map(&{maneuver, &1})
      end)

    Enum.reduce(affected, acc, fn {_maneuver, activity}, repaired ->
      reason = "affected_by_delayed_maneuver_requires_operator_review"

      activities =
        Enum.map(repaired.activities, fn existing ->
          if ActivityIdentity.activity_id(existing) == ActivityIdentity.activity_id(activity) do
            put_repair_metadata(existing, %{
              "action" => get_in(existing, ["repair", "action"]) || "preserved",
              "reason" => reason,
              "affected_by_delayed_maneuver" => true,
              "requires_approval" => true
            })
          else
            existing
          end
        end)

      repaired
      |> RepairAccumulator.replace_activities(activities)
      |> RepairAccumulator.add_approval_requirement(activity, "review_downstream_window", reason)
      |> RepairAccumulator.add_warning(
        "#{ActivityIdentity.activity_id(activity)} affected by delayed maneuver"
      )
    end)
  end

  defp put_repair_metadata(activity, metadata) do
    Map.update(activity, "repair", metadata, &Map.merge(&1, metadata))
  end
end
