defmodule OrbitalDynamics.CampaignPlanner.CommandActivityClassification do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ScalarValues

  @command_health_activity_types ~w(command health_check)

  def command?(activity) do
    type = Map.get(activity, "type") || Map.get(activity, "activity_type")
    direction = activity_direction(activity)

    type in @command_health_activity_types or
      (type in ["planned_contact", "contact"] and
         direction in ["command", "uplink", "health_check"]) or
      Map.has_key?(activity, "command_success")
  end

  defp activity_direction(activity),
    do: ScalarValues.normalized_status_token(Map.get(activity, "direction"))
end
