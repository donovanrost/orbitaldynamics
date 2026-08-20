defmodule OrbitalDynamics.Schema.ResourceProjectionFlowSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @status_fields [
    "resource_flow_status",
    "resource_pressure_status",
    "latency_status"
  ]

  @count_fields [
    "activity_count",
    "valid_activity_count",
    "invalid_activity_input_count",
    "input_resource_summary_count",
    "valid_resource_summary_count",
    "invalid_resource_summary_input_count",
    "projected_resource_count",
    "flow_row_count",
    "resource_pressure_count",
    "actual_data_volume_evidence_count",
    "latency_evidence_count",
    "latency_review_count",
    "ignored_activity_count"
  ]

  @count_map_fields [
    "ignored_activity_reason_counts"
  ]

  @stable_id_array_fields [
    "invalid_activity_input_ids",
    "invalid_resource_summary_input_ids",
    "resource_pressure_types",
    "resource_pressure_spacecraft_ids",
    "actual_data_volume_under_delivered_activity_ids",
    "actual_data_volume_over_delivered_activity_ids",
    "actual_data_volume_exact_activity_ids",
    "latency_review_activity_ids",
    "ignored_activity_ids"
  ]

  @stable_id_array_map_fields [
    "resource_pressure_spacecraft_ids_by_type",
    "resource_pressure_activity_ids_by_type",
    "resource_pressure_ground_station_ids_by_type",
    "resource_pressure_source_window_ids_by_type",
    "resource_pressure_station_calendar_entry_ids_by_type",
    "resource_pressure_station_calendar_provider_ids_by_type",
    "resource_pressure_station_calendar_provider_entry_ids_by_type",
    "ignored_activity_ids_by_reason"
  ]

  @number_fields [
    "total_storage_produced_mb",
    "total_planned_downlink_mb",
    "total_storage_limited_downlinked_mb",
    "total_unused_downlink_capacity_mb",
    "total_storage_overflow_mb",
    "total_downlink_shortfall_mb",
    "total_actual_data_volume_mb",
    "total_data_volume_delta_mb",
    "total_projected_storage_remaining_mb",
    "minimum_projected_storage_remaining_mb",
    "total_projected_downlink_remaining_mb",
    "minimum_projected_downlink_remaining_mb",
    "total_battery_energy_consumed_wh",
    "total_battery_energy_generated_wh",
    "net_battery_energy_delta_wh",
    "peak_battery_overuse_wh",
    "max_planned_latency_s",
    "max_actual_latency_s"
  ]

  def property_field?(field)
      when field in [
             "model",
             "source",
             "resource_pressure_station_calendar_directions_by_type",
             "resource_pressure_capacity_fractions_by_type",
             "projected_resources",
             "activity_resource_flow",
             "model_limits",
             "assumptions"
           ],
      do: true

  def property_field?(field)
      when field in @status_fields or field in @count_fields or field in @count_map_fields or
             field in @stable_id_array_fields or field in @stable_id_array_map_fields or
             field in @number_fields,
      do: true

  def property_field?(_field), do: false

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_opts(field, deps)
      when field in @stable_id_array_fields or field in @stable_id_array_map_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts("activity_resource_flow", deps) do
    [activity_resource_flow_row_schema: fetch_dep!(deps, :activity_resource_flow_row_schema)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts("assumptions", deps) do
    [assumptions_schema: fetch_dep!(deps, :assumptions_schema)]
  end

  def property_opts(_field, _deps), do: []

  def row_from_deps(deps) do
    deps
    |> row_opts()
    |> row()
  end

  def row_from_context(
        stable_id_pattern,
        string_array_schema,
        source_window_schema,
        resource_capability
      ) do
    [
      stable_id_pattern: stable_id_pattern,
      string_array_schema: string_array_schema,
      source_window_schema: source_window_schema,
      resource_capability: resource_capability
    ]
    |> row_opts()
    |> row()
  end

  def row(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "downlink_link_budget_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "activity_type" => %{"type" => "string"},
        "mode" => %{"type" => "string"},
        "contact_mode" => %{"type" => "string"},
        "direction" => %{"type" => "string"},
        "incompatible_activity_types" => Keyword.fetch!(opts, :string_array_schema),
        "suppressed_activity_types" => Keyword.fetch!(opts, :string_array_schema),
        "ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "station_calendar_entry_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "station_calendar_provider_id" => %{
          "type" => "string",
          "pattern" => stable_id_pattern
        },
        "station_calendar_provider_entry_id" => %{
          "type" => "string",
          "pattern" => stable_id_pattern
        },
        "station_calendar_directions" => Keyword.fetch!(opts, :string_array_schema),
        "source_window_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_window_revision" => %{"type" => "string", "minLength" => 1},
        "source_window_type" => %{"type" => "string"},
        "source_window" => Keyword.fetch!(opts, :source_window_schema),
        "downlink_link_budget" =>
          OrbitalDynamics.Schema.DownlinkLinkBudgetJsonSchema.artifact_schema(
            stable_id_pattern: stable_id_pattern
          ),
        "capacity_fraction" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "planned_data_volume_mb" => %{"type" => "number", "minimum" => 0.0},
        "actual_data_volume_mb" => %{"type" => "number", "minimum" => 0.0},
        "data_volume_delta_mb" => %{"type" => "number"},
        "data_volume_completion_fraction" => %{"type" => "number", "minimum" => 0.0},
        "completed_fraction" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "starts_at_s" => %{"type" => "number"},
        "ends_at_s" => %{"type" => "number"},
        "collection_ends_at_s" => %{"type" => "number"},
        "planned_delivery_at_s" => %{"type" => "number"},
        "actual_delivery_at_s" => %{"type" => "number"},
        "max_latency_s" => %{"type" => "number", "minimum" => 0.0},
        "planned_latency_s" => %{"type" => "number", "minimum" => 0.0},
        "actual_latency_s" => %{"type" => "number", "minimum" => 0.0},
        "latency_margin_s" => %{"type" => "number"},
        "latency_basis" => %{"type" => "string", "enum" => ["planned", "actual"]},
        "latency_status" => %{"type" => "string", "enum" => ["within_limit", "late"]},
        "resource_effect_status" => %{
          "type" => "string",
          "enum" =>
            Keyword.fetch!(opts, :resource_capability).roll_forward_resource_effect_statuses
        },
        "resource_effect_reason" => %{"type" => "string"},
        "storage_used_before_mb" => %{"type" => "number", "minimum" => 0.0},
        "storage_produced_mb" => %{"type" => "number", "minimum" => 0.0},
        "storage_available_before_downlink_mb" => %{"type" => "number", "minimum" => 0.0},
        "planned_downlink_mb" => %{"type" => "number", "minimum" => 0.0},
        "downlinked_mb" => %{"type" => "number", "minimum" => 0.0},
        "unused_downlink_capacity_mb" => %{"type" => "number", "minimum" => 0.0},
        "storage_delta_mb" => %{"type" => "number"},
        "storage_used_after_mb" => %{"type" => "number", "minimum" => 0.0},
        "storage_margin_after" => %{"type" => "number"},
        "storage_overflow_mb" => %{"type" => "number", "minimum" => 0.0},
        "downlink_used_before_mb" => %{"type" => "number", "minimum" => 0.0},
        "downlink_used_after_mb" => %{"type" => "number", "minimum" => 0.0},
        "downlink_margin_after" => %{"type" => "number"},
        "downlink_shortfall_mb" => %{"type" => "number", "minimum" => 0.0},
        "battery_energy_used_before_wh" => %{"type" => "number", "minimum" => 0.0},
        "battery_energy_consumed_wh" => %{"type" => "number", "minimum" => 0.0},
        "battery_energy_generated_wh" => %{"type" => "number", "minimum" => 0.0},
        "battery_energy_delta_wh" => %{"type" => "number"},
        "battery_energy_used_after_wh" => %{"type" => "number", "minimum" => 0.0},
        "battery_state_of_charge_after" => %{
          "type" => "number",
          "minimum" => 0.0,
          "maximum" => 1.0
        },
        "battery_overuse_wh" => %{"type" => "number", "minimum" => 0.0}
      }
    }
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_selected_activity_resource_flow_summary"}
  end

  def property("source", _opts) do
    %{"type" => "string"}
  end

  def property(field, _opts) when field in @status_fields do
    %{"type" => "string", "enum" => ["clear", "review_required"]}
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def property("resource_pressure_station_calendar_directions_by_type", _opts) do
    CommonJsonSchema.string_list_map()
  end

  def property("resource_pressure_capacity_fractions_by_type", _opts) do
    CommonJsonSchema.number_array_map()
  end

  def property(field, _opts) when field in @number_fields do
    %{"type" => "number"}
  end

  def property("projected_resources", _opts) do
    %{
      "type" => "array",
      "items" => %{"type" => "object", "additionalProperties" => true}
    }
  end

  def property("activity_resource_flow", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :activity_resource_flow_row_schema)
    }
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("assumptions", opts) do
    Keyword.fetch!(opts, :assumptions_schema)
  end

  defp row_opts(deps) do
    [
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      string_array_schema: fetch_dep!(deps, :string_array_schema),
      source_window_schema: fetch_dep!(deps, :source_window_schema),
      resource_capability: fetch_dep!(deps, :resource_capability)
    ]
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
