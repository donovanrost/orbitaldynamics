defmodule OrbitalDynamics.Validation.ArtifactObservations.ManeuverRecommendation do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    delta_v = list_values(artifact, "delta_v_km_s")
    model_limits = list_values(artifact, "model_limits")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "id" => Map.get(artifact, "id"),
      "type" => Map.get(artifact, "type"),
      "scenario_id" => Map.get(artifact, "scenario_id"),
      "epoch_s" => Map.get(artifact, "epoch_s"),
      "epoch_scale" => Map.get(artifact, "epoch_scale"),
      "frame" => Map.get(artifact, "frame"),
      "maneuver_model" => Map.get(artifact, "maneuver_model"),
      "validation_level" => Map.get(artifact, "validation_level"),
      "delta_v_component_count" => length(delta_v),
      "delta_v_y_km_s" => Enum.at(delta_v, 1),
      "delta_v_magnitude_km_s" => Map.get(artifact, "delta_v_magnitude_km_s"),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "assumption_source" => get_in(artifact, ["assumptions", "source"]),
      "recommendation_only_no_command_execution" =>
        "recommendation_only_no_command_execution" in model_limits,
      "requires_operator_review_before_execution" =>
        "requires_operator_review_before_execution" in model_limits,
      "model_limit_count" => length(model_limits)
    }
  end

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _values -> []
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
