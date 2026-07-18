defmodule OrbitalDynamics.Timeline.ActivityFeedbackContext do
  @moduledoc false

  def build(activity, provider_result_map_value_keys) do
    %{
      "contact_success" => first_boolean(activity, ["contact_success"]),
      "contact_result" =>
        first_provider_result_string(activity, ["contact_result"], provider_result_map_value_keys),
      "contact_success_factor" => first_number(activity, ["contact_success_factor"]),
      "contact_success_factor_source" =>
        first_scalar_string(activity, ["contact_success_factor_source"]),
      "command_success" => first_boolean(activity, ["command_success"]),
      "command_result" =>
        first_provider_result_string(activity, ["command_result"], provider_result_map_value_keys),
      "command_success_factor" => first_number(activity, ["command_success_factor"]),
      "command_success_factor_source" =>
        first_scalar_string(activity, ["command_success_factor_source"]),
      "observation_success" => first_boolean(activity, ["observation_success"]),
      "observation_result" =>
        first_provider_result_string(
          activity,
          ["observation_result"],
          provider_result_map_value_keys
        ),
      "observation_success_factor" => first_number(activity, ["observation_success_factor"]),
      "observation_success_factor_source" =>
        first_scalar_string(activity, ["observation_success_factor_source"]),
      "maneuver_success" => first_boolean(activity, ["maneuver_success"]),
      "maneuver_result" =>
        first_provider_result_string(
          activity,
          ["maneuver_result"],
          provider_result_map_value_keys
        ),
      "maneuver_success_factor" => first_number(activity, ["maneuver_success_factor"]),
      "maneuver_success_factor_source" =>
        first_scalar_string(activity, ["maneuver_success_factor_source"]),
      "feedback_weight" => first_number(activity, ["feedback_weight"]),
      "feedback_weight_source" => first_scalar_string(activity, ["feedback_weight_source"])
    }
    |> compact_map()
  end

  defp first_boolean(activity, keys) do
    OrbitalDynamics.Timeline.ActivityBooleanPolicy.first_boolean(activity, keys)
  end

  defp first_provider_result_string(activity, keys, provider_result_map_value_keys) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_provider_result_string(
      activity,
      keys,
      fn result ->
        OrbitalDynamics.Timeline.ProviderResult.artifact_value(
          result,
          provider_result_map_value_keys
        )
      end
    )
  end

  defp first_number(activity, keys) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_number(
      activity,
      keys,
      &OrbitalDynamics.Timeline.ActivityNumericValuePolicy.numeric_value/1
    )
  end

  defp first_scalar_string(activity, keys) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_scalar_string(activity, keys)
  end

  defp compact_map(map) do
    OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.compact(map)
  end
end
