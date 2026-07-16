defmodule OrbitalDynamics.Schema.ThermalHandoffJsonSchema do
  @moduledoc false

  @number_fields [
    "temperature_c",
    "planned_temperature_c",
    "actual_temperature_c",
    "temperature_delta_c",
    "min_operating_temperature_c",
    "max_operating_temperature_c",
    "thermal_margin_c"
  ]

  @string_fields [
    "thermal_status",
    "thermal_model",
    "thermal_source"
  ]

  def properties(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    probability_schema = Keyword.fetch!(opts, :probability_schema)

    @number_fields
    |> typed_fields("number")
    |> Map.merge(typed_fields(@string_fields, "string"))
    |> Map.merge(%{
      "thermal_zone_id" => %{"type" => "string", "pattern" => stable_id_pattern},
      "thermal_confidence" => probability_schema
    })
  end

  defp typed_fields(fields, type) do
    Map.new(fields, &{&1, %{"type" => type}})
  end
end
