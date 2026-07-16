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

  @base_fields [
    "direction",
    "source_window",
    "timeline_identity",
    "cadence_import",
    "suppressed_activity_types"
  ]

  def property_field?(field) do
    field in @base_fields or field in @stable_id_array_fields or field in @probability_fields or
      field in @non_negative_number_fields
  end

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_from_context(
        field,
        cadence_import_schema,
        source_window_schema,
        stable_id_pattern,
        timeline_identity_schema
      ) do
    deps = [
      cadence_import_schema: cadence_import_schema,
      source_window_schema: source_window_schema,
      stable_id_pattern: stable_id_pattern,
      timeline_identity_schema: timeline_identity_schema
    ]

    property_from_context(field, deps)
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_fun_from_context(
        cadence_import_schema,
        source_window_schema,
        stable_id_pattern,
        timeline_identity_schema
      ) do
    fn field ->
      property_from_context(
        field,
        cadence_import_schema: cadence_import_schema,
        source_window_schema: source_window_schema,
        stable_id_pattern: stable_id_pattern,
        timeline_identity_schema: timeline_identity_schema
      )
    end
  end

  def dispatch_property(field, contract, opts) do
    focused_property = Keyword.fetch!(opts, :focused_property)
    execution_uncertainty_schema = Keyword.fetch!(opts, :execution_uncertainty_schema)
    number_or_string_schema = Keyword.fetch!(opts, :number_or_string_schema)
    default_property = Keyword.fetch!(opts, :default_property)

    cond do
      property_field?(field) ->
        focused_property.(field)

      field == "execution_uncertainty" ->
        execution_uncertainty_schema.()

      field == "lighting_confidence" ->
        number_or_string_schema.()

      true ->
        default_property.(field, contract)
    end
  end

  def property_opts("source_window", deps) do
    [source_window_schema: fetch_dep!(deps, :source_window_schema)]
  end

  def property_opts("timeline_identity", deps) do
    [timeline_identity_schema: fetch_dep!(deps, :timeline_identity_schema)]
  end

  def property_opts("cadence_import", deps) do
    [cadence_import_schema: fetch_dep!(deps, :cadence_import_schema)]
  end

  def property_opts(field, deps) when field in @stable_id_array_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(_field, _deps), do: []

  def schema(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    stable_id_array_schema = Keyword.fetch!(opts, :stable_id_array_schema)
    string_array_schema = Keyword.fetch!(opts, :string_array_schema)
    probability_schema = Keyword.fetch!(opts, :probability_schema)
    source_window_schema = Keyword.fetch!(opts, :source_window_schema)
    timeline_identity_schema = Keyword.fetch!(opts, :timeline_identity_schema)
    cadence_import_schema = Keyword.fetch!(opts, :cadence_import_schema)
    execution_uncertainty_schema = Keyword.fetch!(opts, :execution_uncertainty_schema)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["id", "scenario_id", "starts_at_s", "ends_at_s"],
      "anyOf" => [
        %{"required" => ["type"]},
        %{"required" => ["activity_type"]}
      ],
      "properties" => %{
        "id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "type" => %{"type" => "string"},
        "activity_type" => %{"type" => "string"},
        "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "starts_at_s" => %{"type" => "number"},
        "ends_at_s" => %{"type" => "number"},
        "duration_s" => %{"type" => "number"},
        "direction" => property("direction", []),
        "source_window_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_window" => source_window_schema,
        "timeline_identity" => timeline_identity_schema,
        "cadence_import" => cadence_import_schema,
        "timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "spacecraft_id" => %{"type" => "string", "pattern" => stable_id_pattern},
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
        "spacecraft_available" => %{"type" => "boolean"},
        "payload_available" => %{"type" => "boolean"},
        "degraded" => %{"type" => "boolean"},
        "mode" => %{"type" => "string"},
        "product_ids" => stable_id_array_schema,
        "data_volume_mb" => %{"type" => "number"},
        "planned_data_volume_mb" => %{"type" => "number"},
        "planned_volume_mb" => %{"type" => "number"},
        "actual_data_volume_mb" => %{"type" => "number"},
        "actual_volume_mb" => %{"type" => "number"},
        "estimated_data_volume_mb" => %{"type" => "number"},
        "estimated_storage_mb" => %{"type" => "number"},
        "estimated_downlink_mb" => %{"type" => "number"},
        "required_downlink_mb" => %{"type" => "number"},
        "required_volume_mb" => %{"type" => "number"},
        "required_data_volume_mb" => %{"type" => "number"},
        "target_downlink_mb" => %{"type" => "number"},
        "target_volume_mb" => %{"type" => "number"},
        "target_data_volume_mb" => %{"type" => "number"},
        "min_downlink_mb" => %{"type" => "number"},
        "selected_downlink_mb" => %{"type" => "number"},
        "selected_data_volume_mb" => %{"type" => "number"},
        "selected_volume_mb" => %{"type" => "number"},
        "delivered_data_volume_mb" => %{"type" => "number"},
        "received_data_volume_mb" => %{"type" => "number"},
        "selected_downlink_shortfall_mb" => %{"type" => "number"},
        "selected_data_volume_shortfall_mb" => %{"type" => "number"},
        "data_volume_shortfall_mb" => %{"type" => "number"},
        "actual_data_volume_shortfall_mb" => %{"type" => "number"},
        "missing_data_volume_mb" => %{"type" => "number"},
        "required_data_volume_gap_mb" => %{"type" => "number"},
        "downlink_requirement_status" => %{"type" => "string"},
        "downlink_completion_source" => %{"type" => "string"},
        "downlink_completion_sources" => string_array_schema,
        "link_protocol" => %{"type" => "string"},
        "frequency_band" => %{"type" => "string"},
        "modulation" => %{"type" => "string"},
        "coding_scheme" => %{"type" => "string"},
        "polarization" => %{"type" => "string"},
        "data_rate_mbps" => %{"type" => "number"},
        "downlink_rate_mbps" => %{"type" => "number"},
        "data_rate_mb_s" => %{"type" => "number"},
        "downlink_rate_mb_s" => %{"type" => "number"},
        "link_margin_db" => %{"type" => "number"},
        "snr_db" => %{"type" => "number"},
        "eb_no_db" => %{"type" => "number"},
        "bit_error_rate" => probability_schema,
        "packet_loss_rate" => probability_schema,
        "frame_loss_rate" => probability_schema,
        "carrier_lock" => %{"type" => "boolean"},
        "symbol_lock" => %{"type" => "boolean"},
        "link_quality_status" => %{"type" => "string"},
        "thermal_margin_c" => %{"type" => "number"},
        "dependency_activity_ids" => stable_id_array_schema,
        "exclusive_with_timeline_ids" => stable_id_array_schema,
        "suppressed_activity_types" => string_array_schema,
        "contact_success_factor" => probability_schema,
        "contact_success_factor_source" => %{"type" => "string"},
        "command_success_factor" => probability_schema,
        "command_success_factor_source" => %{"type" => "string"},
        "command_authority_status" => %{"type" => "string"},
        "required_authority" => %{"type" => "string"},
        "command_safety_status" => %{"type" => "string"},
        "command_authorized" => %{"type" => "boolean"},
        "command_safety_checked" => %{"type" => "boolean"},
        "observation_success_factor" => probability_schema,
        "observation_success_factor_source" => %{"type" => "string"},
        "cloud_cover_fraction" => probability_schema,
        "blur_score" => probability_schema,
        "maneuver_success_factor" => probability_schema,
        "maneuver_success_factor_source" => %{"type" => "string"},
        "execution_uncertainty" => execution_uncertainty_schema
      }
    }
  end

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

  defp fetch_dep!(deps, key), do: Keyword.fetch!(deps, key)
end
