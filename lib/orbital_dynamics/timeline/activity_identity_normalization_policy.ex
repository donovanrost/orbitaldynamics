defmodule OrbitalDynamics.Timeline.ActivityIdentityNormalizationPolicy do
  @moduledoc false

  def normalize_spacecraft_id(%{"spacecraft_id" => spacecraft_id} = activity)
      when not is_nil(spacecraft_id),
      do: activity

  def normalize_spacecraft_id(%{"satellite_id" => spacecraft_id} = activity)
      when not is_nil(spacecraft_id),
      do: Map.put(activity, "spacecraft_id", spacecraft_id)

  def normalize_spacecraft_id(%{} = activity) do
    case first_nested_identity(activity, ["spacecraft", "satellite"], [
           "spacecraft_id",
           "satellite_id",
           "id"
         ]) do
      nil -> activity
      spacecraft_id -> Map.put(activity, "spacecraft_id", spacecraft_id)
    end
  end

  def normalize_station_id(%{"ground_station_id" => station_id} = activity)
      when not is_nil(station_id),
      do: activity

  def normalize_station_id(%{"station_id" => station_id} = activity)
      when not is_nil(station_id),
      do: Map.put(activity, "ground_station_id", station_id)

  def normalize_station_id(%{} = activity) do
    case first_nested_identity(activity, ["ground_station", "station"], [
           "ground_station_id",
           "station_id",
           "id"
         ]) do
      nil -> activity
      station_id -> Map.put(activity, "ground_station_id", station_id)
    end
  end

  def normalize_target_id(%{"target_id" => target_id} = activity) when not is_nil(target_id),
    do: activity

  def normalize_target_id(%{} = activity) do
    case first_nested_identity(activity, ["target"], ["target_id", "id"]) do
      nil -> activity
      target_id -> Map.put(activity, "target_id", target_id)
    end
  end

  defp first_nested_identity(activity, object_keys, identity_keys) do
    Enum.find_value(object_keys, fn object_key ->
      case Map.get(activity, object_key) do
        %{} = object -> Enum.find_value(identity_keys, &present_identity(Map.get(object, &1)))
        _value -> nil
      end
    end)
  end

  defp present_identity(value) when value in [nil, ""], do: nil
  defp present_identity(value), do: value
end
