defmodule OrbitalDynamics.Schema.PlannedActivityJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @stable_id_array_fields [
    "product_ids",
    "dependency_activity_ids",
    "exclusive_with_timeline_ids"
  ]

  @probability_fields [
    "fuel_margin",
    "power_margin",
    "storage_margin",
    "downlink_margin",
    "battery_state_of_charge",
    "contact_success_factor",
    "command_success_factor",
    "observation_success_factor",
    "cloud_cover_fraction",
    "blur_score",
    "maneuver_success_factor"
  ]

  @non_negative_number_fields [
    "battery_capacity_wh",
    "battery_energy_used_wh",
    "battery_energy_generated_wh"
  ]

  def property("direction", _opts) do
    %{
      "type" => "string",
      "enum" => ["downlink", "uplink", "command", "tracking", "health_check"]
    }
  end

  def property("source_window", opts) do
    Keyword.fetch!(opts, :source_window_schema)
  end

  def property("timeline_identity", opts) do
    Keyword.fetch!(opts, :timeline_identity_schema)
  end

  def property("cadence_import", opts) do
    Keyword.fetch!(opts, :cadence_import_schema)
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, _opts) when field in @probability_fields do
    CommonJsonSchema.probability()
  end

  def property(field, _opts) when field in @non_negative_number_fields do
    %{"type" => "number", "minimum" => 0.0}
  end

  def property("suppressed_activity_types", _opts) do
    CommonJsonSchema.string_array()
  end
end
