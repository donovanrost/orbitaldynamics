defmodule OrbitalDynamics.CampaignPlanner.RepairAccumulator do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    ActivityTiming,
    DownlinkActivityNormalization,
    PlanDelta,
    ValueEncoding
  }

  alias OrbitalDynamics.Timeline

  def add_delta(
        acc,
        activity,
        realized,
        status,
        action,
        reason,
        replacement_id,
        requires_approval?,
        replacement_activity \\ nil
      ) do
    add_delta(
      acc,
      activity,
      realized,
      status,
      action,
      reason,
      replacement_id,
      requires_approval?,
      replacement_activity,
      callbacks()
    )
  end

  def add_delta(
        acc,
        activity,
        realized,
        status,
        action,
        reason,
        replacement_id,
        requires_approval?,
        replacement_activity,
        callbacks
      ) do
    activity_id = Keyword.fetch!(callbacks, :activity_id)
    activity_timeline_id = Keyword.fetch!(callbacks, :activity_timeline_id)
    replacement_timeline_id = Keyword.fetch!(callbacks, :replacement_timeline_id)
    optional_timeline_link = Keyword.fetch!(callbacks, :optional_timeline_link)
    operational_activity_context = Keyword.fetch!(callbacks, :operational_activity_context)

    optional_operational_activity_context =
      Keyword.fetch!(callbacks, :optional_operational_activity_context)

    delta = %PlanDelta{
      activity_id: activity_id.(activity),
      activity_type: activity["type"],
      status: status,
      planned: planned_snapshot(activity, operational_activity_context),
      realized: realized,
      repair_action: action,
      reason: reason,
      replacement_activity_id: replacement_id,
      source_timeline_id: activity_timeline_id.(activity),
      replacement_timeline_id: replacement_timeline_id.(replacement_activity),
      timeline_link: optional_timeline_link.(activity, replacement_activity),
      source_activity_context: operational_activity_context.(activity),
      replacement_activity_context: optional_operational_activity_context.(replacement_activity),
      requires_approval: requires_approval?
    }

    Map.update!(acc, :deltas, &[delta | &1])
  end

  def add_ambiguous_realized_delta(acc, activity, realized_rows, reason) do
    add_ambiguous_realized_delta(acc, activity, realized_rows, reason, callbacks())
  end

  def add_ambiguous_realized_delta(acc, activity, realized_rows, reason, callbacks) do
    activity_id = Keyword.fetch!(callbacks, :activity_id)
    activity_timeline_id = Keyword.fetch!(callbacks, :activity_timeline_id)
    operational_activity_context = Keyword.fetch!(callbacks, :operational_activity_context)

    delta = %PlanDelta{
      activity_id: activity_id.(activity),
      activity_type: activity["type"],
      status: "ambiguous_realized_feedback",
      planned: planned_snapshot(activity, operational_activity_context),
      repair_action: "review_realized_feedback",
      reason: reason,
      source_timeline_id: activity_timeline_id.(activity),
      source_activity_context: operational_activity_context.(activity),
      realized_feedback_rows: realized_rows,
      realized_feedback_count: length(realized_rows),
      requires_approval: true
    }

    Map.update!(acc, :deltas, &[delta | &1])
  end

  def add_approval_requirement(acc, activity, action, reason) do
    add_approval_requirement(acc, activity, action, reason, callbacks())
  end

  def add_approval_requirement(acc, activity, action, reason, callbacks) do
    activity_id = Keyword.fetch!(callbacks, :activity_id)
    operational_activity_context = Keyword.fetch!(callbacks, :operational_activity_context)

    requirement =
      %{
        "schema_contract" => "approval_requirement.v1",
        "activity_id" => activity_id.(activity),
        "activity_type" => activity["type"],
        "requirement_type" => approval_requirement_type(action, activity),
        "action" => action,
        "reason" => reason,
        "activity_context" => operational_activity_context.(activity)
      }
      |> drop_empty_activity_context()

    Map.update!(acc, :approval_requirements, &[requirement | &1])
  end

  def approval_requirement_type("approve_moved_contact", _activity),
    do: "contact_schedule_change"

  def approval_requirement_type("approve_reassigned_observation", _activity),
    do: "observation_reassignment"

  def approval_requirement_type("approve_delayed_maneuver", _activity),
    do: "maneuver_timing_change"

  def approval_requirement_type("review_downstream_window", _activity),
    do: "downstream_window_review"

  def approval_requirement_type("review_realized_feedback", _activity),
    do: "realized_feedback_review"

  def approval_requirement_type("approve_strategic_addition", _activity),
    do: "strategic_addition"

  def approval_requirement_type("cancel", _activity), do: "cancellation"
  def approval_requirement_type(_action, %{"type" => "command"}), do: "command_review"
  def approval_requirement_type(_action, %{"type" => "health_check"}), do: "health_check_review"
  def approval_requirement_type(_action, _activity), do: "operator_review"

  defp callbacks,
    do: [
      activity_id: &ActivityIdentity.activity_id/1,
      activity_timeline_id: &activity_timeline_id/1,
      replacement_timeline_id: &replacement_timeline_id/1,
      optional_timeline_link: &optional_timeline_link/2,
      operational_activity_context: &Timeline.activity_context/1,
      optional_operational_activity_context: &optional_operational_activity_context/1
    ]

  defp planned_snapshot(activity, operational_activity_context) do
    Map.take(activity, [
      "id",
      "type",
      "scenario_id",
      "target_id",
      "ground_station_id",
      "starts_at_s",
      "ends_at_s",
      "duration_s",
      "score"
    ])
    |> Map.merge(operational_activity_context.(activity))
  end

  defp drop_empty_activity_context(%{"activity_context" => context} = requirement)
       when map_size(context) == 0 do
    Map.delete(requirement, "activity_context")
  end

  defp drop_empty_activity_context(requirement), do: requirement

  defp optional_timeline_link(_source_activity, nil), do: nil

  defp optional_timeline_link(source_activity, replacement_activity),
    do: Timeline.timeline_link(source_activity, replacement_activity)

  defp optional_operational_activity_context(nil), do: nil

  defp optional_operational_activity_context(activity),
    do: Timeline.activity_context(activity)

  defp replacement_timeline_id(nil), do: nil
  defp replacement_timeline_id(activity), do: activity_timeline_id(activity)

  defp activity_timeline_id(activity) do
    activity["timeline_id"] ||
      activity["persistent_id"] ||
      get_in(activity, ["metadata", "timeline_id"]) ||
      get_in(activity, ["metadata", "persistent_id"]) ||
      derived_timeline_id(activity)
  end

  defp derived_timeline_id(activity) do
    [
      "timeline",
      activity["scenario_id"],
      activity["type"],
      activity_subject_id(activity),
      activity_source_window_id(activity) || ActivityTiming.activity_start(activity)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&ValueEncoding.encode_value/1)
    |> Enum.join(":")
  end

  defp activity_subject_id(activity) do
    activity["target_id"] ||
      activity_ground_station_id(activity) ||
      activity["spacecraft_id"] ||
      activity["resource_id"]
  end

  defp activity_ground_station_id(activity) do
    Map.get(activity, "ground_station_id") ||
      Map.get(activity, "station_id") ||
      DownlinkActivityNormalization.nested_ground_station_id(activity)
  end

  defp activity_source_window_id(activity) do
    activity["source_window_id"] ||
      get_in(activity, ["source_window", "id"]) ||
      get_in(activity, ["metadata", "source_window_id"])
  end
end
