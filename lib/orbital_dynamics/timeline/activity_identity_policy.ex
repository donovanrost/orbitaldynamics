defmodule OrbitalDynamics.Timeline.ActivityIdentityPolicy do
  @moduledoc false

  def activity_id(%{"id" => id}, encode_value), do: encode_value.(id)

  def timeline_id(activity, activity_start, encode_value) do
    activity["timeline_id"] ||
      activity["persistent_id"] ||
      get_in(activity, ["metadata", "timeline_id"]) ||
      get_in(activity, ["metadata", "persistent_id"]) ||
      derived_timeline_id(activity, activity_start, encode_value)
  end

  def subject_id(activity) do
    activity["target_id"] ||
      activity["ground_station_id"] ||
      activity["maneuver_id"] ||
      activity["spacecraft_id"] ||
      activity["resource_id"]
  end

  def source_window_id(activity) do
    activity["source_window_id"] ||
      get_in(activity, ["source_window", "id"]) ||
      get_in(activity, ["source_window", "window_id"]) ||
      get_in(activity, ["metadata", "source_window_id"]) ||
      get_in(activity, ["metadata", "source_window", "id"]) ||
      get_in(activity, ["metadata", "source_window", "window_id"])
  end

  def source_window_type(activity) do
    activity["source_window_type"] ||
      activity["source_window_kind"] ||
      get_in(activity, ["source_window", "type"]) ||
      get_in(activity, ["source_window", "kind"]) ||
      get_in(activity, ["source_window", "window_type"]) ||
      get_in(activity, ["metadata", "source_window_type"]) ||
      get_in(activity, ["metadata", "source_window_kind"]) ||
      get_in(activity, ["metadata", "source_window", "type"]) ||
      get_in(activity, ["metadata", "source_window", "kind"]) ||
      get_in(activity, ["metadata", "source_window", "window_type"])
  end

  defp derived_timeline_id(activity, activity_start, encode_value) do
    [
      "timeline",
      activity["scenario_id"],
      activity["type"],
      subject_id(activity),
      source_window_id(activity) || activity_start.(activity)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&encode_value.(&1))
    |> Enum.join(":")
  end
end
