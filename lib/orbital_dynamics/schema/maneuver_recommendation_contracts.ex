defmodule OrbitalDynamics.Schema.ManeuverRecommendationContracts do
  @moduledoc false

  @required_fields [
    "schema_contract",
    "id",
    "scenario_id",
    "type",
    "epoch_s",
    "frame",
    "delta_v_km_s",
    "maneuver_model",
    "assumptions"
  ]

  def validate(issues, path, maneuver, model_limits, callbacks)
      when is_list(model_limits) and is_list(callbacks) do
    issues
    |> call(callbacks, :require_fields, [path, maneuver, @required_fields])
    |> call(callbacks, :validate_stable_ids, [path, maneuver, ["id", "scenario_id"]])
    |> call(callbacks, :expect_equal, [
      path,
      maneuver,
      "schema_contract",
      "maneuver_recommendation.v1"
    ])
    |> call(callbacks, :expect_equal, [path, maneuver, "type", "impulsive_burn"])
    |> call(callbacks, :expect_number, [path, maneuver, "epoch_s"])
    |> call(callbacks, :expect_optional_type, [path, maneuver, "epoch_scale", :binary])
    |> call(callbacks, :expect_type, [path, maneuver, "frame", :binary])
    |> call(callbacks, :expect_number_vector, [
      path <> ".delta_v_km_s",
      Map.get(maneuver, "delta_v_km_s")
    ])
    |> call(callbacks, :expect_optional_number, [path, maneuver, "delta_v_magnitude_km_s"])
    |> validate_delta_v_magnitude(callbacks, path, maneuver)
    |> call(callbacks, :expect_type, [path, maneuver, "maneuver_model", :binary])
    |> call(callbacks, :expect_optional_type, [path, maneuver, "validation_level", :binary])
    |> call(callbacks, :expect_optional_type, [path, maneuver, "model_limits", :list])
    |> call(callbacks, :validate_string_list_items, [path, maneuver, "model_limits"])
    |> validate_model_limits(callbacks, path, maneuver, model_limits)
    |> call(callbacks, :expect_type, [path, maneuver, "assumptions", :map])
  end

  defp validate_delta_v_magnitude(issues, callbacks, path, %{
         "delta_v_km_s" => [x, y, z],
         "delta_v_magnitude_km_s" => magnitude
       })
       when is_number(x) and is_number(y) and is_number(z) and is_number(magnitude) do
    expected = :math.sqrt(x * x + y * y + z * z)

    if abs(magnitude - expected) <= 1.0e-9 do
      issues
    else
      [
        error(
          callbacks,
          "#{path}.delta_v_magnitude_km_s",
          "must equal magnitude derived from delta_v_km_s"
        )
        | issues
      ]
    end
  end

  defp validate_delta_v_magnitude(issues, _callbacks, _path, _maneuver), do: issues

  defp validate_model_limits(issues, callbacks, path, maneuver, expected_model_limits) do
    case Map.get(maneuver, "model_limits") do
      nil ->
        issues

      :null ->
        issues

      limits when is_list(limits) ->
        if limits == expected_model_limits do
          issues
        else
          [
            error(
              callbacks,
              "#{path}.model_limits",
              "must match maneuver recommendation model limits"
            )
            | issues
          ]
        end

      _value ->
        issues
    end
  end

  defp error(callbacks, path, message), do: require_callback(callbacks, :error).(path, message)

  defp call(issues, callbacks, name, args) do
    apply(require_callback(callbacks, name), [issues | args])
  end

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
