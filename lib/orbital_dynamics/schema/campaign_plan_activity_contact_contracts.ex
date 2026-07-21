defmodule OrbitalDynamics.Schema.CampaignPlanActivityContactContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2, require_fields: 4]

  @contact_activity_types ["downlink", "command", "tracking", "health_check"]
  @contact_directions ["downlink", "uplink", "command", "tracking", "health_check"]

  def validate(issues, path, %{"type" => type} = activity)
      when type in @contact_activity_types do
    issues
    |> require_fields(path, activity, required_fields(type))
    |> validate_direction(path, activity, type)
  end

  def validate(issues, _path, _activity), do: issues

  # Base activity validation already owns downlink contact-field presence.
  defp required_fields("downlink"), do: []
  defp required_fields(_type), do: ["ground_station_id", "direction"]

  defp validate_direction(issues, _path, %{"direction" => type}, type), do: issues

  defp validate_direction(issues, _path, activity, _type)
       when not is_map_key(activity, "direction"),
       do: issues

  defp validate_direction(issues, _path, %{"direction" => direction}, "downlink")
       when direction not in @contact_directions,
       do: issues

  defp validate_direction(issues, path, _activity, _type) do
    [error(path <> ".direction", "must match activity type") | issues]
  end
end
