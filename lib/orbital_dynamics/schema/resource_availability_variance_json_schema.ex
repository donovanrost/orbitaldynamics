defmodule OrbitalDynamics.Schema.ResourceAvailabilityVarianceJsonSchema do
  @moduledoc false

  @boolean_fields [
    "spacecraft_available",
    "planned_spacecraft_available",
    "realized_spacecraft_available",
    "payload_available",
    "planned_payload_available",
    "realized_payload_available",
    "antenna_available",
    "planned_antenna_available",
    "realized_antenna_available",
    "degraded",
    "planned_degraded",
    "realized_degraded"
  ]

  @string_fields [
    "spacecraft_available_match_status",
    "payload_available_match_status",
    "antenna_available_match_status",
    "degraded_match_status",
    "mode",
    "planned_mode",
    "realized_mode",
    "mode_match_status"
  ]

  def properties do
    @boolean_fields
    |> typed_fields("boolean")
    |> Map.merge(typed_fields(@string_fields, "string"))
  end

  defp typed_fields(fields, type) do
    Map.new(fields, &{&1, %{"type" => type}})
  end
end
