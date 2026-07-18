defmodule OrbitalDynamics.Timeline.IdentityGroupingPolicy do
  @moduledoc false

  def normalized_activity_groups(activities, opts, normalize_activities) do
    activities
    |> normalize_activities.(opts)
    |> Enum.group_by(& &1["timeline_id"])
  end

  def unique_timeline_activity(groups, timeline_id) do
    case Map.get(groups, timeline_id, []) do
      [activity] -> activity
      _duplicates_or_missing -> nil
    end
  end

  def rows_by_timeline_id(rows) do
    rows
    |> Enum.group_by(& &1["timeline_id"])
    |> Map.new(fn {timeline_id, matches} ->
      {timeline_id, Enum.sort_by(matches, & &1["activity_id"])}
    end)
  end
end
