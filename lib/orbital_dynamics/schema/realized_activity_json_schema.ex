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

  def property_opts("product_ids", deps) do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(field, deps) when field in @numeric_triplet_fields do
    [numeric_triplet_schema: fetch_dep!(deps, :numeric_triplet_schema)]
  end

  def property_opts(field, deps) when field in ["station", "ground_station"] do
    [ground_station_schema: fetch_dep!(deps, :ground_station_schema)]
  end

  def property_opts(field, deps) when field in ["spacecraft", "satellite"] do
    [spacecraft_schema: fetch_dep!(deps, :spacecraft_schema)]
  end

  def property_opts("target", deps) do
    [target_schema: fetch_dep!(deps, :target_schema)]
  end

  def property_opts(_field, _deps), do: []

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_field?(field)
      when field in @status_fields or field in @string_fields or field in @probability_fields or
             field in @non_negative_number_fields or field in @string_array_fields or
             field in @numeric_triplet_fields or
             field in [
               "product_ids",
               "station",
               "ground_station",
               "spacecraft",
               "satellite",
               "target"
             ],
      do: true

  def property_field?(_field), do: false

  def dispatch_property(field, contract, opts) do
    focused_property = Keyword.fetch!(opts, :focused_property)
    execution_uncertainty_schema = Keyword.fetch!(opts, :execution_uncertainty_schema)
    number_or_string_schema = Keyword.fetch!(opts, :number_or_string_schema)
    default_property = Keyword.fetch!(opts, :default_property)

    cond do
      property_field?(field) ->
        focused_property.(field)

      field in ["execution_uncertainty", "maneuver_execution_uncertainty"] ->
        execution_uncertainty_schema.()

      field == "lighting_confidence" ->
        number_or_string_schema.()

      true ->
        default_property.(field, contract)
    end
  end

  def schema(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    stable_id_array_schema = Keyword.fetch!(opts, :stable_id_array_schema)
    string_array_schema = Keyword.fetch!(opts, :string_array_schema)
    numeric_triplet_schema = Keyword.fetch!(opts, :numeric_triplet_schema)
    probability_schema = Keyword.fetch!(opts, :probability_schema)
    number_or_string_schema = Keyword.fetch!(opts, :number_or_string_schema)
    execution_uncertainty_schema = Keyword.fetch!(opts, :execution_uncertainty_schema)
    ground_station_schema = Keyword.fetch!(opts, :ground_station_schema)
    spacecraft_schema = Keyword.fetch!(opts, :spacecraft_schema)
    target_schema = Keyword.fetch!(opts, :target_schema)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["schema_contract", "id", "status"],
      "properties" => %{
        "schema_contract" => %{"type" => "string", "const" => "realized_activity.v1"},
        "id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "planned_activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "status" => property("status", []),
        "type" => %{"type" => "string"},
        "activity_type" => %{"type" => "string"},
        "direction" => %{"type" => "string"},
        "ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "station" => ground_station_schema,
        "ground_station" => ground_station_schema,
        "spacecraft_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "satellite_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "spacecraft" => spacecraft_schema,
        "satellite" => spacecraft_schema,
        "target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "target" => target_schema,
        "source_window_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "resource_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "resource_source_quality" => %{"type" => "string"},
        "resource_trust_boundary" => %{"type" => "string"},
        "resource_trust_boundary_status" => %{"type" => "string"},
        "resource_provenance" => %{"type" => "object", "additionalProperties" => true},
        "resource_blocking_dimension" => %{"type" => "string"},
        "fuel_margin" => probability_schema,
        "power_margin" => probability_schema,
        "storage_margin" => probability_schema,
        "downlink_margin" => probability_schema,
        "battery_capacity_wh" => %{"type" => "number"},
        "battery_energy_used_wh" => %{"type" => "number"},
        "battery_energy_generated_wh" => %{"type" => "number", "minimum" => 0.0},
        "battery_state_of_charge" => probability_schema,
        "spacecraft_available" => %{"type" => "boolean"},
        "payload_available" => %{"type" => "boolean"},
        "antenna_available" => %{"type" => "boolean"},
        "degraded" => %{"type" => "boolean"},
        "mode" => %{"type" => "string"},
        "incompatible_activity_types" => string_array_schema,
        "suppressed_activity_types" => string_array_schema,
        "collection_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "product_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "product_ids" => stable_id_array_schema,
        "payload_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "instrument_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "data_volume_mb" => %{"type" => "number"},
        "planned_data_volume_mb" => %{"type" => "number"},
        "actual_data_volume_mb" => %{"type" => "number"},
        "estimated_data_volume_mb" => %{"type" => "number"},
        "estimated_storage_mb" => %{"type" => "number"},
        "estimated_downlink_mb" => %{"type" => "number"},
        "required_downlink_mb" => %{"type" => "number"},
        "collection_ends_at_s" => %{"type" => "number"},
        "planned_delivery_at_s" => %{"type" => "number"},
        "actual_delivery_at_s" => %{"type" => "number"},
        "max_latency_s" => %{"type" => "number"},
        "planned_latency_s" => %{"type" => "number"},
        "actual_latency_s" => %{"type" => "number"},
        "planned_estimated_throughput_mb" => %{"type" => "number"},
        "target_priority" => %{"type" => "number"},
        "contact_result" => %{"type" => "string"},
        "contact_success_factor" => probability_schema,
        "contact_success_factor_source" => %{"type" => "string"},
        "command_success_factor" => probability_schema,
        "command_success_factor_source" => %{"type" => "string"},
        "command_authority_status" => %{"type" => "string"},
        "required_authority" => %{"type" => "string"},
        "command_safety_status" => %{"type" => "string"},
        "command_authorized" => %{"type" => "boolean"},
        "command_safety_checked" => %{"type" => "boolean"},
        "observation_success" => %{"type" => "boolean"},
        "observation_result" => %{"type" => "string"},
        "observation_success_factor" => probability_schema,
        "observation_success_factor_source" => %{"type" => "string"},
        "image_quality_score" => probability_schema,
        "image_quality_status" => %{"type" => "string"},
        "image_quality_source" => %{"type" => "string"},
        "cloud_cover_fraction" => probability_schema,
        "blur_score" => probability_schema,
        "maneuver_success" => %{"type" => "boolean"},
        "maneuver_result" => %{"type" => "string"},
        "maneuver_success_factor" => probability_schema,
        "maneuver_success_factor_source" => %{"type" => "string"},
        "feedback_weight" => %{"type" => "number"},
        "feedback_weight_source" => %{"type" => "string"},
        "delta_v_km_s" => numeric_triplet_schema,
        "actual_delta_v_km_s" => numeric_triplet_schema,
        "executed_delta_v_km_s" => numeric_triplet_schema,
        "delta_v_magnitude_km_s" => %{"type" => "number"},
        "execution_uncertainty" => execution_uncertainty_schema,
        "maneuver_execution_uncertainty" => execution_uncertainty_schema,
        "execution_uncertainty_status" => %{"type" => "string"},
        "timing_3sigma_s" => %{"type" => "number"},
        "delta_v_3sigma_km_s" => numeric_triplet_schema,
        "delta_v_3sigma_magnitude_km_s" => %{"type" => "number"},
        "execution_uncertainty_source" => %{"type" => "string"},
        "pointing_mode" => %{"type" => "string"},
        "pointing_target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "boresight_axis" => %{"type" => "string"},
        "off_nadir_angle_deg" => %{"type" => "number"},
        "slew_angle_deg" => %{"type" => "number"},
        "slew_rate_deg_s" => %{"type" => "number"},
        "pointing_error_deg" => %{"type" => "number"},
        "pointing_status" => %{"type" => "string"},
        "pointing_model" => %{"type" => "string"},
        "pointing_source" => %{"type" => "string"},
        "pointing_confidence" => probability_schema,
        "attitude_mode" => %{"type" => "string"},
        "attitude_target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "roll_deg" => %{"type" => "number"},
        "pitch_deg" => %{"type" => "number"},
        "yaw_deg" => %{"type" => "number"},
        "attitude_error_deg" => %{"type" => "number"},
        "attitude_status" => %{"type" => "string"},
        "attitude_model" => %{"type" => "string"},
        "attitude_source" => %{"type" => "string"},
        "attitude_confidence" => probability_schema,
        "thermal_zone_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "temperature_c" => %{"type" => "number"},
        "planned_temperature_c" => %{"type" => "number"},
        "actual_temperature_c" => %{"type" => "number"},
        "min_operating_temperature_c" => %{"type" => "number"},
        "max_operating_temperature_c" => %{"type" => "number"},
        "thermal_margin_c" => %{"type" => "number"},
        "thermal_status" => %{"type" => "string"},
        "thermal_model" => %{"type" => "string"},
        "thermal_source" => %{"type" => "string"},
        "thermal_confidence" => probability_schema,
        "eclipse_overlap_fraction" => probability_schema,
        "eclipse_overlap_s" => %{"type" => "number"},
        "lighting_condition" => %{"type" => "string"},
        "lighting_condition_detail" => %{"type" => "string"},
        "lighting_condition_model" => %{"type" => "string"},
        "lighting_detail_model" => %{"type" => "string"},
        "lighting_confidence" => number_or_string_schema,
        "link_protocol" => %{"type" => "string"},
        "frequency_band" => %{"type" => "string"},
        "modulation" => %{"type" => "string"},
        "coding_scheme" => %{"type" => "string"},
        "polarization" => %{"type" => "string"},
        "data_rate_mbps" => %{"type" => "number"},
        "downlink_rate_mbps" => %{"type" => "number"},
        "data_rate_mb_s" => %{"type" => "number"},
        "downlink_rate_mb_s" => %{"type" => "number"},
        "actual_data_rate_mbps" => %{"type" => "number"},
        "actual_downlink_rate_mbps" => %{"type" => "number"},
        "actual_data_rate_mb_s" => %{"type" => "number"},
        "actual_downlink_rate_mb_s" => %{"type" => "number"},
        "delivered_rate_mbps" => %{"type" => "number"},
        "received_rate_mbps" => %{"type" => "number"},
        "delivered_rate_mb_s" => %{"type" => "number"},
        "received_rate_mb_s" => %{"type" => "number"},
        "link_margin_db" => %{"type" => "number"},
        "snr_db" => %{"type" => "number"},
        "eb_no_db" => %{"type" => "number"},
        "bit_error_rate" => probability_schema,
        "packet_loss_rate" => probability_schema,
        "frame_loss_rate" => probability_schema,
        "carrier_lock" => %{"type" => "boolean"},
        "symbol_lock" => %{"type" => "boolean"},
        "link_quality_status" => %{"type" => "string"},
        "actual_starts_at_s" => %{"type" => "number"},
        "actual_ends_at_s" => %{"type" => "number"},
        "actual_duration_s" => %{"type" => "number"},
        "actual_contact_duration_s" => %{"type" => "number"},
        "contact_duration_s" => %{"type" => "number"},
        "actual_throughput_mb" => %{"type" => "number"},
        "contact_success" => %{"type" => "boolean"},
        "command_success" => %{"type" => "boolean"},
        "command_result" => %{"type" => "string"},
        "completed_fraction" => probability_schema,
        "reason" => %{"type" => "string"},
        "provider" => %{"type" => "string"},
        "adapter" => %{"type" => "string"},
        "adapter_version" => %{"type" => "string"},
        "external_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "trust_boundary" => %{"type" => "string"},
        "source" => %{"type" => "object", "additionalProperties" => true},
        "provenance" => %{
          "type" => "object",
          "additionalProperties" => true,
          "properties" => %{"trust_boundary" => %{"type" => "string"}}
        },
        "metadata" => %{"type" => "object", "additionalProperties" => true}
      },
      "allOf" => [
        %{
          "if" => %{
            "anyOf" => [
              %{"required" => ["provider"]},
              %{"required" => ["adapter"]},
              %{"required" => ["adapter_version"]},
              %{"required" => ["external_id"]}
            ]
          },
          "then" => %{
            "required" => ["external_id"],
            "anyOf" => [
              %{"required" => ["trust_boundary"]},
              %{
                "required" => ["provenance"],
                "properties" => %{
                  "provenance" => %{
                    "type" => "object",
                    "required" => ["trust_boundary"],
                    "properties" => %{"trust_boundary" => %{"type" => "string"}},
                    "additionalProperties" => true
                  }
                }
              }
            ]
          }
        }
      ]
    }
  end

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

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
