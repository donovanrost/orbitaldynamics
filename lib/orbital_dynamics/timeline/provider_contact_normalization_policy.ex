defmodule OrbitalDynamics.Timeline.ProviderContactNormalizationPolicy do
  @moduledoc false

  def normalize_provider_downlink(activity) do
    if provider_downlink_activity?(activity) do
      activity
      |> Map.put_new("type", "downlink")
      |> Map.put_new("direction", "downlink")
    else
      activity
    end
  end

  def normalize_direction_contact(activity) do
    type = Map.get(activity, "type") || Map.get(activity, "activity_type")
    direction = Map.get(activity, "direction")

    cond do
      typed_contact_window?(type, direction, activity) and direction == "health_check" ->
        Map.put_new(activity, "type", "health_check")

      typed_contact_window?(type, direction, activity) ->
        Map.put_new(activity, "type", "planned_contact")

      true ->
        activity
    end
  end

  def normalize_type_alias(%{"type" => type} = activity) when not is_nil(type),
    do: activity

  def normalize_type_alias(%{"activity_type" => type} = activity)
      when is_binary(type) and type != "",
      do: Map.put(activity, "type", type)

  def normalize_type_alias(activity), do: activity

  defp typed_contact_window?(type, direction, activity) do
    type in [nil, "contact", "planned_contact"] and
      direction in ["tracking", "uplink", "command", "health_check"] and
      is_binary(Map.get(activity, "ground_station_id")) and
      Map.get(activity, "ground_station_id") != "" and
      is_number(Map.get(activity, "starts_at_s")) and
      is_number(Map.get(activity, "ends_at_s"))
  end

  defp provider_downlink_activity?(activity) do
    type = Map.get(activity, "type") || Map.get(activity, "activity_type")
    direction = Map.get(activity, "direction")

    type in [nil, "contact", "planned_contact"] and
      direction in [nil, "downlink"] and
      not command_feedback_activity?(activity) and
      is_binary(Map.get(activity, "ground_station_id")) and
      Map.get(activity, "ground_station_id") != "" and
      is_number(Map.get(activity, "starts_at_s")) and
      is_number(Map.get(activity, "ends_at_s"))
  end

  defp command_feedback_activity?(activity) do
    Map.has_key?(activity, "command_success") or Map.has_key?(activity, "command_result")
  end
end
