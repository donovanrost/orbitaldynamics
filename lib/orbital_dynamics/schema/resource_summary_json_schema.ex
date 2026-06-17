defmodule OrbitalDynamics.Schema.ResourceSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @probability_fields [
    "fuel_margin",
    "power_margin",
    "battery_state_of_charge",
    "storage_margin",
    "downlink_margin"
  ]

  @non_negative_number_fields [
    "battery_capacity_wh",
    "battery_energy_used_wh",
    "battery_energy_generated_wh",
    "storage_capacity_mb",
    "storage_used_mb",
    "downlink_capacity_mb"
  ]

  @boolean_fields [
    "payload_available",
    "antenna_available",
    "spacecraft_available",
    "degraded"
  ]

  def property("schema_contract", opts) do
    schema_contract = Keyword.fetch!(opts, :schema_contract)

    %{
      "type" => "string",
      "const" => schema_contract,
      "description" => "Stable executable contract identifier"
    }
  end

  def property("spacecraft_id", opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{"type" => "string", "pattern" => stable_id_pattern}
  end

  def property(field, _opts) when field in @probability_fields do
    CommonJsonSchema.probability()
  end

  def property(field, _opts) when field in @non_negative_number_fields do
    %{"type" => "number", "minimum" => 0.0}
  end

  def property("thermal_margin_c", _opts), do: %{"type" => "number"}

  def property(field, _opts) when field in @boolean_fields do
    %{"type" => "boolean"}
  end

  def property(field, _opts)
      when field in ["mode", "source_quality", "trust_boundary"] do
    %{"type" => "string"}
  end

  def property(field, _opts)
      when field in ["incompatible_activity_types", "suppressed_activity_types"] do
    CommonJsonSchema.string_array()
  end

  def property(field, _opts) when field in ["assumptions", "provenance"] do
    %{"type" => "object", "additionalProperties" => true}
  end
end
