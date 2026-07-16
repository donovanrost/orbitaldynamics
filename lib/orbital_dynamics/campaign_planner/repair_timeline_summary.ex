defmodule OrbitalDynamics.CampaignPlanner.RepairTimelineSummary do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ActivityIdentity, ScalarValues}

  @preserved_executed_statuses ~w(completed executed partial)

  def delta_to_map(delta) do
    %{
      "schema_contract" => "plan_delta.v1",
      "activity_id" => delta.activity_id,
      "activity_type" => delta.activity_type,
      "status" => delta.status,
      "planned" => delta.planned,
      "realized" => delta.realized,
      "repair_action" => delta.repair_action,
      "reason" => delta.reason,
      "replacement_activity_id" => delta.replacement_activity_id,
      "source_timeline_id" => delta.source_timeline_id,
      "replacement_timeline_id" => delta.replacement_timeline_id,
      "timeline_link" => delta.timeline_link,
      "source_activity_context" => delta.source_activity_context,
      "replacement_activity_context" => delta.replacement_activity_context,
      "realized_feedback_rows" => delta.realized_feedback_rows,
      "realized_feedback_count" => delta.realized_feedback_count,
      "requires_approval" => delta.requires_approval
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  def preserved_activities(activities) do
    Enum.filter(activities, fn activity ->
      get_in(activity, ["repair", "action"]) in ["preserved", "preserved_executed"]
    end)
  end

  def change_summary(deltas) do
    deltas
    |> Enum.group_by(& &1.repair_action)
    |> Map.new(fn {action, rows} -> {action, length(rows)} end)
  end

  def protection_summary(activities, deltas) do
    preserved_locked_ids =
      activities
      |> Enum.filter(&(get_in(&1, ["repair", "reason"]) == "activity_locked_or_approved"))
      |> Enum.map(&ActivityIdentity.activity_id/1)
      |> Enum.sort()

    preserved_executed_ids =
      activities
      |> Enum.filter(&(get_in(&1, ["repair", "action"]) == "preserved_executed"))
      |> Enum.map(&ActivityIdentity.activity_id/1)
      |> Enum.sort()

    changed_locked_ids =
      deltas
      |> Enum.reject(&(&1.repair_action in ["preserved", "preserved_executed"]))
      |> Enum.filter(&locked_or_approved?(&1.planned || %{}))
      |> Enum.map(& &1.activity_id)
      |> Enum.sort()

    changed_executed_ids =
      deltas
      |> Enum.reject(&(&1.repair_action in ["preserved", "preserved_executed"]))
      |> Enum.filter(&(&1.status in @preserved_executed_statuses))
      |> Enum.map(& &1.activity_id)
      |> Enum.sort()

    %{
      "preserved_locked_or_approved_count" => length(preserved_locked_ids),
      "preserved_executed_count" => length(preserved_executed_ids),
      "changed_locked_or_approved_count" => length(changed_locked_ids),
      "changed_executed_count" => length(changed_executed_ids),
      "preserved_locked_or_approved_activity_ids" => preserved_locked_ids,
      "preserved_executed_activity_ids" => preserved_executed_ids,
      "changed_locked_or_approved_activity_ids" => changed_locked_ids,
      "changed_executed_activity_ids" => changed_executed_ids
    }
  end

  defp locked_or_approved?(activity) do
    metadata = Map.get(activity, "metadata", %{})

    ScalarValues.truthy?(Map.get(activity, "locked")) or
      ScalarValues.truthy?(Map.get(activity, "approved")) or
      ScalarValues.truthy?(Map.get(metadata, "locked")) or
      ScalarValues.truthy?(Map.get(metadata, "approved")) or
      Map.get(activity, "approval_status") in ["approved", "locked"] or
      Map.get(metadata, "approval_status") in ["approved", "locked"]
  end
end
