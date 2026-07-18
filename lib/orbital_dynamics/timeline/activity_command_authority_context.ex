defmodule OrbitalDynamics.Timeline.ActivityCommandAuthorityContext do
  @moduledoc false

  def build(activity) do
    %{
      "command_authority_status" =>
        first_scalar_string(activity, ["command_authority_status", "authority_status"]),
      "required_authority" =>
        first_scalar_string(activity, ["required_authority", "required_escalation_authority"]),
      "command_safety_status" =>
        first_scalar_string(activity, ["command_safety_status", "safety_status"]),
      "command_authorized" =>
        first_boolean(activity, ["command_authorized", "command_authorized?", "authority_granted"]),
      "command_safety_checked" =>
        first_boolean(activity, [
          "command_safety_checked",
          "command_safety_checked?",
          "safety_checked"
        ])
    }
    |> compact_map()
  end

  defp first_scalar_string(activity, keys) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_scalar_string(activity, keys)
  end

  defp first_boolean(activity, keys) do
    OrbitalDynamics.Timeline.ActivityBooleanPolicy.first_boolean(activity, keys)
  end

  defp compact_map(map) do
    OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.compact(map)
  end
end
