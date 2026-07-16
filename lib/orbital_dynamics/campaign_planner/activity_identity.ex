defmodule OrbitalDynamics.CampaignPlanner.ActivityIdentity do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ValueEncoding

  def same_scenario?(left, right), do: left["scenario_id"] == right["scenario_id"]

  def activity_id(activity) do
    activity_id(activity, callbacks())
  end

  def activity_id(activity, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    activity
    |> Map.fetch!("id")
    |> encode_value.()
  end

  def window_id(scenario_id, type, source_id, index) do
    window_id(scenario_id, type, source_id, index, callbacks())
  end

  def window_id(scenario_id, type, source_id, index, callbacks) do
    ["window", scenario_id, type, source_id, index]
    |> encoded_segments(callbacks)
    |> Enum.join(":")
  end

  def activity_id(scenario_id, type, source_id, index) do
    activity_id(scenario_id, type, source_id, index, callbacks())
  end

  def activity_id(scenario_id, type, source_id, index, callbacks) do
    [scenario_id, type, source_id, index]
    |> encoded_segments(callbacks)
    |> Enum.join("_")
  end

  def ground_station_id(activity) do
    Map.get(activity, "ground_station_id") || Map.get(activity, "station_id") ||
      nested_ground_station_id(activity)
  end

  defp encoded_segments(segments, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    Enum.map(segments, encode_value)
  end

  defp callbacks do
    [
      encode_value: &ValueEncoding.encode_value/1
    ]
  end

  defp nested_ground_station_id(activity) do
    Enum.find_value(["ground_station", "station", :ground_station, :station], fn station_key ->
      case Map.get(activity, station_key) do
        %{} = station ->
          Enum.find_value(
            ["ground_station_id", "station_id", "id", :ground_station_id, :station_id, :id],
            fn identity_key -> Map.get(station, identity_key) end
          )

        _station ->
          nil
      end
    end)
  end
end
