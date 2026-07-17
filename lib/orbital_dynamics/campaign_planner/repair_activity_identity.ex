defmodule OrbitalDynamics.CampaignPlanner.RepairActivityIdentity do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityTiming,
    DownlinkActivityNormalization,
    ValueEncoding
  }

  alias OrbitalDynamics.Timeline

  def context(activity), do: Timeline.activity_context(activity)

  def timeline_link(source_activity, replacement_activity),
    do: Timeline.timeline_link(source_activity, replacement_activity)

  def timeline_id(activity) do
    activity["timeline_id"] ||
      activity["persistent_id"] ||
      get_in(activity, ["metadata", "timeline_id"]) ||
      get_in(activity, ["metadata", "persistent_id"]) ||
      derived_timeline_id(activity)
  end

  def ground_station_id(activity) do
    Map.get(activity, "ground_station_id") || Map.get(activity, "station_id") ||
      DownlinkActivityNormalization.nested_ground_station_id(activity)
  end

  def source_window_id(activity) do
    activity["source_window_id"] ||
      get_in(activity, ["source_window", "id"]) ||
      get_in(activity, ["metadata", "source_window_id"])
  end

  defp derived_timeline_id(activity) do
    [
      "timeline",
      activity["scenario_id"],
      activity["type"],
      activity_subject_id(activity),
      source_window_id(activity) || ActivityTiming.activity_start(activity)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&ValueEncoding.encode_value/1)
    |> Enum.join(":")
  end

  defp activity_subject_id(activity) do
    activity["target_id"] ||
      ground_station_id(activity) ||
      activity["spacecraft_id"] ||
      activity["resource_id"]
  end
end
