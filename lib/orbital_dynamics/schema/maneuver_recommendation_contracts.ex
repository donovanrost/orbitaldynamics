defmodule OrbitalDynamics.Schema.ManeuverRecommendationContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_number: 4,
      expect_number_vector: 3,
      expect_optional_number: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

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

  def validate(issues, path, maneuver, model_limits) when is_list(model_limits) do
    issues
    |> require_fields(path, maneuver, @required_fields)
    |> validate_stable_ids(path, maneuver, ["id", "scenario_id"])
    |> expect_equal(
      path,
      maneuver,
      "schema_contract",
      "maneuver_recommendation.v1"
    )
    |> expect_equal(path, maneuver, "type", "impulsive_burn")
    |> expect_number(path, maneuver, "epoch_s")
    |> expect_optional_type(path, maneuver, "epoch_scale", :binary)
    |> expect_type(path, maneuver, "frame", :binary)
    |> expect_number_vector(path <> ".delta_v_km_s", Map.get(maneuver, "delta_v_km_s"))
    |> expect_optional_number(path, maneuver, "delta_v_magnitude_km_s")
    |> validate_delta_v_magnitude(path, maneuver)
    |> expect_type(path, maneuver, "maneuver_model", :binary)
    |> expect_optional_type(path, maneuver, "validation_level", :binary)
    |> expect_optional_type(path, maneuver, "model_limits", :list)
    |> validate_string_list_items(path, maneuver, "model_limits")
    |> validate_model_limits(path, maneuver, model_limits)
    |> expect_type(path, maneuver, "assumptions", :map)
  end

  defp validate_delta_v_magnitude(issues, path, %{
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
          "#{path}.delta_v_magnitude_km_s",
          "must equal magnitude derived from delta_v_km_s"
        )
        | issues
      ]
    end
  end

  defp validate_delta_v_magnitude(issues, _path, _maneuver), do: issues

  defp validate_model_limits(issues, path, maneuver, expected_model_limits) do
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
end
