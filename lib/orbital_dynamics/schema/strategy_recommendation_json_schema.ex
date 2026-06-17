defmodule OrbitalDynamics.Schema.StrategyRecommendationJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @approval_status_values [
    "auto_approvable",
    "operator_review_required",
    "blocked_by_policy"
  ]

  def property("schema_contract", opts) do
    schema_contract = Keyword.fetch!(opts, :schema_contract)

    %{
      "type" => "string",
      "const" => schema_contract,
      "description" => "Stable executable contract identifier"
    }
  end

  def property("recommended_branch_id", opts) do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def property("ranked_branch_ids", opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property("approval_status", _opts) do
    %{"type" => "string", "enum" => @approval_status_values}
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
end
