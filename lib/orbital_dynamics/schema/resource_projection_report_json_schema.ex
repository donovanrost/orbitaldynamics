defmodule OrbitalDynamics.Schema.ResourceProjectionReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @stable_id_array_fields [
    "invalid_resource_summary_input_ids",
    "invalid_activity_input_ids",
    "resource_pressure_spacecraft_ids",
    "resource_pressure_types"
  ]

  @count_fields [
    "input_resource_summary_count",
    "activity_count",
    "valid_resource_summary_count",
    "invalid_resource_summary_input_count",
    "valid_activity_count",
    "invalid_activity_input_count",
    "resource_pressure_count"
  ]

  @stable_id_array_map_fields [
    "resource_pressure_spacecraft_ids_by_type",
    "resource_pressure_activity_ids_by_type",
    "resource_spacecraft_ids_by_source_quality",
    "resource_spacecraft_ids_by_trust_boundary_status"
  ]

  @count_map_fields [
    "resource_source_quality_counts",
    "resource_trust_boundary_status_counts"
  ]

  def property_field?(field)
      when field in [
             "model",
             "source",
             "model_limits",
             "assumptions",
             "projected_resources"
           ],
      do: true

  def property_field?(field)
      when field in @stable_id_array_fields or field in @count_fields or
             field in @stable_id_array_map_fields or field in @count_map_fields,
      do: true

  def property_field?(_field), do: false

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_opts("model", deps) do
    [models: fetch_dep!(deps, :models)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts("assumptions", deps) do
    [assumptions_schema: fetch_dep!(deps, :assumptions_schema)]
  end

  def property_opts("projected_resources", deps) do
    [resource_projection_row_schema: fetch_dep!(deps, :resource_projection_row_schema)]
  end

  def property_opts(field, deps)
      when field in @stable_id_array_fields or field in @stable_id_array_map_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(_field, _deps), do: []

  def row_from_deps(deps) do
    deps
    |> row_opts()
    |> row()
  end

  def row_from_context(
        stable_id_pattern,
        stable_id_array_schema,
        string_array_schema,
        resource_projection_flow_row_schema,
        source_window_schema,
        approval_requirement_schema,
        policy_decision_rule_match_schema,
        policy_decision_schema
      ) do
    [
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema,
      string_array_schema: string_array_schema,
      resource_projection_flow_row_schema: resource_projection_flow_row_schema,
      source_window_schema: source_window_schema,
      approval_requirement_schema: approval_requirement_schema,
      policy_decision_rule_match_schema: policy_decision_rule_match_schema,
      policy_decision_schema: policy_decision_schema
    ]
    |> row_opts()
    |> row()
  end

  def row(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "spacecraft_id",
        "activity_count",
        "observation_count",
        "downlink_count",
        "estimated_storage_produced_mb",
        "estimated_downlink_mb"
      ],
      "properties" => %{
        "spacecraft_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "activity_count" => %{"type" => "integer", "minimum" => 0},
        "effective_activity_count" => %{"type" => "integer", "minimum" => 0},
        "observation_count" => %{"type" => "integer", "minimum" => 0},
        "downlink_count" => %{"type" => "integer", "minimum" => 0},
        "ignored_activity_count" => %{"type" => "integer", "minimum" => 0},
        "ignored_activity_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "estimated_storage_produced_mb" => %{"type" => "number"},
        "estimated_downlink_mb" => %{"type" => "number"},
        "starting_storage_used_mb" => %{"type" => "number"},
        "projected_storage_used_mb" => %{"type" => "number"},
        "storage_capacity_mb" => %{"type" => "number"},
        "starting_storage_margin" => %{"type" => "number"},
        "projected_storage_margin" => %{"type" => "number"},
        "projected_storage_remaining_mb" => %{"type" => "number"},
        "projected_storage_overflow_mb" => %{"type" => "number", "minimum" => 0.0},
        "downlink_capacity_mb" => %{"type" => "number"},
        "starting_downlink_margin" => %{"type" => "number"},
        "projected_downlink_margin" => %{"type" => "number"},
        "projected_downlink_remaining_mb" => %{"type" => "number"},
        "projected_downlink_shortfall_mb" => %{"type" => "number", "minimum" => 0.0},
        "storage_limited_downlinked_mb" => %{"type" => "number", "minimum" => 0.0},
        "unused_downlink_capacity_mb" => %{"type" => "number", "minimum" => 0.0},
        "resource_source_quality" => %{"type" => "string"},
        "resource_trust_boundary_status" => %{"type" => "string"},
        "resource_pressure_status" => %{"type" => "string"},
        "resource_pressure_types" => Keyword.fetch!(opts, :string_array_schema),
        "resource_provenance" => %{"type" => "object", "additionalProperties" => true},
        "payload_available" => %{"type" => "boolean"},
        "antenna_available" => %{"type" => "boolean"},
        "mode" => %{"type" => "string"},
        "incompatible_activity_types" => Keyword.fetch!(opts, :string_array_schema),
        "suppressed_activity_types" => Keyword.fetch!(opts, :string_array_schema),
        "activity_resource_flow" => %{
          "type" => "array",
          "items" => Keyword.fetch!(opts, :resource_projection_flow_row_schema)
        },
        "first_resource_pressure_activity_id" => %{
          "type" => "string",
          "pattern" => stable_id_pattern
        },
        "first_resource_pressure_activity_type" => %{"type" => "string"},
        "first_resource_pressure_kind" => %{"type" => "string"},
        "first_resource_pressure_starts_at_s" => %{"type" => "number"},
        "first_resource_pressure_direction" => %{"type" => "string"},
        "first_resource_pressure_ground_station_id" => %{
          "type" => "string",
          "pattern" => stable_id_pattern
        },
        "first_resource_pressure_station_calendar_entry_id" => %{
          "type" => "string",
          "pattern" => stable_id_pattern
        },
        "first_resource_pressure_station_calendar_provider_id" => %{
          "type" => "string",
          "pattern" => stable_id_pattern
        },
        "first_resource_pressure_station_calendar_provider_entry_id" => %{
          "type" => "string",
          "pattern" => stable_id_pattern
        },
        "first_resource_pressure_station_calendar_directions" =>
          Keyword.fetch!(opts, :string_array_schema),
        "first_resource_pressure_capacity_fraction" => %{
          "type" => "number",
          "minimum" => 0.0,
          "maximum" => 1.0
        },
        "first_resource_pressure_source_window_id" => %{
          "type" => "string",
          "pattern" => stable_id_pattern
        },
        "first_resource_pressure_source_window_type" => %{"type" => "string"},
        "first_resource_pressure_source_window" => Keyword.fetch!(opts, :source_window_schema),
        "source_window_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_window_type" => %{"type" => "string"},
        "source_window" => Keyword.fetch!(opts, :source_window_schema),
        "fuel_margin" => %{"type" => "number"},
        "power_margin" => %{"type" => "number"},
        "projected_power_margin" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "battery_capacity_wh" => %{"type" => "number", "minimum" => 0.0},
        "battery_energy_used_wh" => %{"type" => "number", "minimum" => 0.0},
        "starting_battery_energy_used_wh" => %{"type" => "number", "minimum" => 0.0},
        "projected_battery_energy_used_wh" => %{"type" => "number", "minimum" => 0.0},
        "projected_battery_overuse_wh" => %{"type" => "number", "minimum" => 0.0},
        "battery_state_of_charge" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "projected_battery_state_of_charge" => %{
          "type" => "number",
          "minimum" => 0.0,
          "maximum" => 1.0
        },
        "thermal_margin_c" => %{"type" => "number"},
        "warnings" => Keyword.fetch!(opts, :string_array_schema),
        "approval_requirements" => %{
          "type" => "array",
          "items" => Keyword.fetch!(opts, :approval_requirement_schema)
        },
        "approval_rule_matches" => %{
          "type" => "array",
          "items" => Keyword.fetch!(opts, :policy_decision_rule_match_schema)
        },
        "policy_decision" => Keyword.fetch!(opts, :policy_decision_schema)
      }
    }
  end

  def property("model", opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :models)}
  end

  def property("source", _opts) do
    %{"type" => "string"}
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

  def property("projected_resources", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :resource_projection_row_schema)}
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def assumptions do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "subsystem_model_capability_contract" => %{
          "type" => "string",
          "const" => "subsystem_model_capability.v1"
        },
        "subsystem_model_capability_ids" => %{
          "type" => "array",
          "const" =>
            OrbitalDynamics.Schema.ResourceProjectionAssumptionsContracts.subsystem_model_capability_ids(),
          "items" => %{
            "type" => "string",
            "enum" =>
              OrbitalDynamics.Schema.ResourceProjectionAssumptionsContracts.subsystem_model_capability_ids()
          }
        },
        "subsystem_model_capability_ids_by_resource" => %{
          "type" => "object",
          "const" =>
            OrbitalDynamics.Schema.ResourceProjectionAssumptionsContracts.subsystem_model_capability_ids_by_resource(),
          "additionalProperties" => %{"type" => "string"}
        }
      }
    }
  end

  defp row_opts(deps) do
    [
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema),
      string_array_schema: fetch_dep!(deps, :string_array_schema),
      resource_projection_flow_row_schema: fetch_dep!(deps, :resource_projection_flow_row_schema),
      source_window_schema: fetch_dep!(deps, :source_window_schema),
      approval_requirement_schema: fetch_dep!(deps, :approval_requirement_schema),
      policy_decision_rule_match_schema: fetch_dep!(deps, :policy_decision_rule_match_schema),
      policy_decision_schema: fetch_dep!(deps, :policy_decision_schema)
    ]
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
