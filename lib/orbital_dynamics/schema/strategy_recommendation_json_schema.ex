defmodule OrbitalDynamics.Schema.StrategyRecommendationJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @approval_status_values [
    "auto_approvable",
    "operator_review_required",
    "blocked_by_policy"
  ]

  @property_fields [
    "schema_contract",
    "recommended_branch_id",
    "ranked_branch_ids",
    "approval_status",
    "status",
    "reason",
    "tradeoffs",
    "explanation",
    "risks_remaining",
    "requires_approval",
    "counterfactual"
  ]

  def property_field?(field) when field in @property_fields, do: true
  def property_field?(_field), do: false

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_from_context(
        field,
        schema_contract,
        stable_id_pattern,
        tradeoff_schema,
        explanation_schema,
        risk_schema,
        approval_requirement_schema
      ) do
    deps = [
      schema_contract: schema_contract,
      stable_id_pattern: stable_id_pattern,
      tradeoff_schema: tradeoff_schema,
      explanation_schema: explanation_schema,
      risk_schema: risk_schema,
      approval_requirement_schema: approval_requirement_schema
    ]

    property_from_context(field, deps)
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property_from_context(field, deps)
    end
  end

  def property_fun_from_context(
        schema_contract,
        stable_id_pattern,
        tradeoff_schema,
        explanation_schema,
        risk_schema,
        approval_requirement_schema
      ) do
    deps = [
      schema_contract: schema_contract,
      stable_id_pattern: stable_id_pattern,
      tradeoff_schema: tradeoff_schema,
      explanation_schema: explanation_schema,
      risk_schema: risk_schema,
      approval_requirement_schema: approval_requirement_schema
    ]

    fn field ->
      property_from_context(field, deps)
    end
  end

  def property_opts(field, deps) do
    [schema_contract: fetch_dep!(deps, :schema_contract)] ++ property_field_opts(field, deps)
  end

  def property_field_opts(field, deps)
      when field in ["ranked_branch_ids", "recommended_branch_id", "counterfactual"] do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_field_opts("tradeoffs", deps) do
    [tradeoff_schema: fetch_dep!(deps, :tradeoff_schema)]
  end

  def property_field_opts("explanation", deps) do
    [explanation_schema: fetch_dep!(deps, :explanation_schema)]
  end

  def property_field_opts("risks_remaining", deps) do
    [risk_schema: fetch_dep!(deps, :risk_schema)]
  end

  def property_field_opts("requires_approval", deps) do
    [approval_requirement_schema: fetch_dep!(deps, :approval_requirement_schema)]
  end

  def property_field_opts(_field, _deps), do: []

  def property("schema_contract", opts) do
    schema_contract = Keyword.fetch!(opts, :schema_contract)

    %{
      "type" => "string",
      "const" => schema_contract,
      "description" => "Stable executable contract identifier"
    }
  end

  def property("recommended_branch_id", opts) do
    %{"type" => ["string", "null"], "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def property("ranked_branch_ids", opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property("approval_status", _opts) do
    %{"type" => "string", "enum" => @approval_status_values ++ ["not_applicable"]}
  end

  def property("status", _opts) do
    %{"type" => "string"}
  end

  def property("reason", _opts) do
    %{"type" => "string"}
  end

  def property("tradeoffs", opts) do
    array(Keyword.fetch!(opts, :tradeoff_schema))
  end

  def property("explanation", opts) do
    array(Keyword.fetch!(opts, :explanation_schema))
  end

  def property("risks_remaining", opts) do
    array(Keyword.fetch!(opts, :risk_schema))
  end

  def property("requires_approval", opts) do
    array(Keyword.fetch!(opts, :approval_requirement_schema))
  end

  def property("counterfactual", opts) do
    OrbitalDynamics.Schema.StrategyRecommendationEligibilityContracts.counterfactual_json_schema(
      Keyword.fetch!(opts, :stable_id_pattern)
    )
  end

  def explanation(stable_id_pattern, branch_event_summary_properties) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["type"],
      "properties" =>
        %{
          "type" => %{"type" => "string"},
          "activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "activity_type" => %{"type" => "string"},
          "target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "spacecraft_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "direction" => %{"type" => "string"},
          "risk_type" => %{"type" => "string"},
          "severity" => %{"type" => "string"},
          "reason" => %{"type" => "string"},
          "action" => %{"type" => "string"},
          "classification" => %{"type" => "string", "enum" => @approval_status_values},
          "objective" => %{"type" => "string"},
          "satisfied_target_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
          "missed_target_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
          "baseline_branch_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "recommended_branch_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "summary" => %{"type" => "string"},
          "feasibility_status" => %{"type" => "string"},
          "pressure_kind" => %{"type" => "string"},
          "starts_at_s" => %{"type" => "number"},
          "storage_overflow_mb" => %{"type" => "number"},
          "downlink_shortfall_mb" => %{"type" => "number"},
          "battery_overuse_wh" => %{"type" => "number"},
          "payload_available" => %{"type" => "boolean"},
          "antenna_available" => %{"type" => "boolean"},
          "degraded" => %{"type" => "boolean"},
          "resource_pressure_status" => %{"type" => "string"},
          "resource_pressure_types" => CommonJsonSchema.string_array(),
          "peak_storage_overflow_mb" => %{"type" => "number"},
          "peak_downlink_shortfall_mb" => %{"type" => "number"},
          "peak_battery_overuse_wh" => %{"type" => "number"},
          "station_calendar_entry_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "station_calendar_provider_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "station_calendar_provider_entry_id" => %{
            "type" => "string",
            "pattern" => stable_id_pattern
          },
          "station_calendar_directions" => CommonJsonSchema.string_array(),
          "station_reservation_expiration_status" => %{"type" => "string"},
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
            CommonJsonSchema.string_array(),
          "requires_approval" => %{"type" => "boolean"}
        }
        |> Map.merge(branch_event_summary_properties)
    }
  end

  def branch_event_summary_properties(
        stable_id_pattern,
        branch_scoped_downlink_context_properties
      ) do
    %{
      "branch_event_count" => %{"type" => "integer", "minimum" => 0},
      "branch_event_types" => CommonJsonSchema.string_array(),
      "branch_event_trust_boundary_status_counts" => %{
        "type" => "object",
        "propertyNames" => %{"enum" => ["declared", "missing"]},
        "additionalProperties" => %{"type" => "integer", "minimum" => 0}
      },
      "combined_source_branch_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern)
    }
    |> Map.merge(branch_scoped_downlink_context_properties)
  end

  defp array(item_schema) do
    %{"type" => "array", "items" => item_schema}
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
