defmodule OrbitalDynamics.Schema.RealizedActivityJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @status_fields ["status", "realized_status"]

  @status_values [
    "completed",
    "executed",
    "partial",
    "missed",
    "failed",
    "delayed",
    "canceled",
    "cancelled",
    "rejected"
  ]

  @string_fields ["feedback_status", "source_quality", "quality"]

  @probability_fields [
    "completed_fraction",
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
    "maneuver_success_factor",
    "pointing_confidence",
    "attitude_confidence",
    "thermal_confidence",
    "image_quality_score",
    "eclipse_overlap_fraction",
    "bit_error_rate",
    "packet_loss_rate",
    "frame_loss_rate"
  ]

  @non_negative_number_fields [
    "battery_capacity_wh",
    "battery_energy_used_wh",
    "battery_energy_generated_wh"
  ]

  @string_array_fields ["incompatible_activity_types", "suppressed_activity_types"]

  @numeric_triplet_fields [
    "delta_v_km_s",
    "actual_delta_v_km_s",
    "executed_delta_v_km_s",
    "delta_v_3sigma_km_s"
  ]

  def property(field, _opts) when field in @status_fields do
    %{"type" => "string", "enum" => @status_values}
  end

  def property(field, _opts) when field in @string_fields do
    %{"type" => "string"}
  end

  def property(field, _opts) when field in @probability_fields do
    CommonJsonSchema.probability()
  end

  def property(field, _opts) when field in @non_negative_number_fields do
    %{"type" => "number", "minimum" => 0.0}
  end

  def property(field, _opts) when field in @string_array_fields do
    CommonJsonSchema.string_array()
  end

  def property("product_ids", opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, opts) when field in @numeric_triplet_fields do
    Keyword.fetch!(opts, :numeric_triplet_schema)
  end

  def property(field, opts) when field in ["station", "ground_station"] do
    Keyword.fetch!(opts, :ground_station_schema)
  end

  def property(field, opts) when field in ["spacecraft", "satellite"] do
    Keyword.fetch!(opts, :spacecraft_schema)
  end

  def property("target", opts) do
    Keyword.fetch!(opts, :target_schema)
  end
end
