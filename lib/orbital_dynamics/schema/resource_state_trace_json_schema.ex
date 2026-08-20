defmodule OrbitalDynamics.Schema.ResourceStateTraceJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.ResourceStateTrace

  @count_fields ~w(
    input_activity_count
    applied_activity_count
    ignored_activity_count
    invalid_activity_count
    violation_count
  )

  def property("schema_contract", _opts),
    do: %{"type" => "string", "const" => "resource_state_trace.v1"}

  def property("id", opts), do: stable_id(opts)
  def property("spacecraft_id", opts), do: stable_id(opts)

  def property("model", _opts),
    do: %{"type" => "string", "const" => ResourceStateTrace.model()}

  def property("status", _opts),
    do: %{"type" => "string", "enum" => ["clear", "limit_exceeded", "review_required"]}

  def property("initial_state", _opts), do: state_schema(true)
  def property("final_state", _opts), do: state_schema(true)

  def property(field, _opts) when field in @count_fields,
    do: %{"type" => "integer", "minimum" => 0}

  def property("invalid_activity_ids", opts), do: stable_id_array(opts)

  def property("trace_rows", opts),
    do: %{"type" => "array", "items" => trace_row_schema(opts)}

  def property("invalid_activities", opts),
    do: %{"type" => "array", "items" => invalid_activity_schema(opts)}

  def property("violation_types", _opts),
    do: string_enum_array(ResourceStateTrace.violation_types())

  def property("activity_ids_by_violation_type", opts) do
    %{
      "type" => "object",
      "additionalProperties" => stable_id_array(opts)
    }
  end

  def property(field, _opts) when field in ["assumptions", "provenance"],
    do: open_object()

  def property("model_limits", _opts),
    do: %{"type" => "array", "const" => ResourceStateTrace.model_limits()}

  defp trace_row_schema(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "id",
        "activity_id",
        "activity_type",
        "spacecraft_id",
        "starts_at_s",
        "ends_at_s",
        "effect_at_s",
        "effect_status",
        "ignored_reason",
        "state_status",
        "declared_effects",
        "applied_effects",
        "state_before",
        "state_after",
        "limit_evidence",
        "violation_types",
        "assumptions",
        "provenance"
      ],
      "properties" => %{
        "id" => stable_id(opts),
        "activity_id" => stable_id(opts),
        "activity_type" => %{"type" => "string"},
        "spacecraft_id" => stable_id(opts),
        "starts_at_s" => number(),
        "ends_at_s" => number(),
        "effect_at_s" => number(),
        "effect_status" => %{
          "type" => "string",
          "enum" => ResourceStateTrace.effect_statuses()
        },
        "ignored_reason" => %{"type" => ["string", "null"]},
        "state_status" => %{
          "type" => "string",
          "enum" => ResourceStateTrace.state_statuses()
        },
        "declared_effects" => effects_schema(),
        "applied_effects" => effects_schema(),
        "state_before" => state_schema(false),
        "state_after" => state_schema(false),
        "limit_evidence" => limit_evidence_schema(),
        "violation_types" => string_enum_array(ResourceStateTrace.violation_types()),
        "assumptions" => open_object(),
        "provenance" => open_object()
      }
    }
  end

  defp invalid_activity_schema(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "id",
        "activity_id",
        "reason_codes",
        "review_status",
        "source_activity"
      ],
      "properties" => %{
        "id" => stable_id(opts),
        "activity_id" => stable_id(opts),
        "reason_codes" => %{
          "type" => "array",
          "items" => %{"type" => "string"},
          "uniqueItems" => true
        },
        "review_status" => %{
          "type" => "string",
          "const" => "operator_review_required"
        },
        "source_activity" => open_object()
      }
    }
  end

  defp state_schema(include_time?) do
    properties = %{
      "battery_capacity_wh" => positive_number(),
      "battery_energy_remaining_wh" => non_negative_number(),
      "battery_state_of_charge" => probability(),
      "recorder_capacity_mb" => positive_number(),
      "recorder_used_mb" => non_negative_number(),
      "recorder_remaining_mb" => non_negative_number(),
      "recorder_fill_fraction" => probability()
    }

    required = Map.keys(properties) |> Enum.sort()

    {properties, required} =
      if include_time? do
        {Map.put(properties, "at_s", number()), ["at_s" | required]}
      else
        {properties, required}
      end

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => required,
      "properties" => properties
    }
  end

  defp effects_schema do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "status",
        "ignored_reason",
        "energy_consumed_wh",
        "energy_generated_wh",
        "data_stored_mb",
        "data_removed_mb",
        "battery_delta_wh",
        "recorder_delta_mb"
      ],
      "properties" => %{
        "status" => %{
          "type" => "string",
          "enum" => ResourceStateTrace.effect_statuses()
        },
        "ignored_reason" => %{"type" => ["string", "null"]},
        "energy_consumed_wh" => non_negative_number(),
        "energy_generated_wh" => non_negative_number(),
        "data_stored_mb" => non_negative_number(),
        "data_removed_mb" => non_negative_number(),
        "battery_delta_wh" => number(),
        "recorder_delta_mb" => number()
      }
    }
  end

  defp limit_evidence_schema do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "unconstrained_battery_energy_remaining_wh",
        "unconstrained_recorder_used_mb",
        "battery_depletion_wh",
        "battery_overflow_wh",
        "recorder_depletion_mb",
        "recorder_overflow_mb"
      ],
      "properties" => %{
        "unconstrained_battery_energy_remaining_wh" => number(),
        "unconstrained_recorder_used_mb" => number(),
        "battery_depletion_wh" => non_negative_number(),
        "battery_overflow_wh" => non_negative_number(),
        "recorder_depletion_mb" => non_negative_number(),
        "recorder_overflow_mb" => non_negative_number()
      }
    }
  end

  defp stable_id(opts) do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  defp stable_id_array(opts) do
    %{
      "type" => "array",
      "items" => stable_id(opts),
      "uniqueItems" => true
    }
  end

  defp string_enum_array(values) do
    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => values},
      "uniqueItems" => true
    }
  end

  defp number, do: %{"type" => "number"}
  defp non_negative_number, do: %{"type" => "number", "minimum" => 0.0}
  defp positive_number, do: %{"type" => "number", "exclusiveMinimum" => 0.0}
  defp probability, do: %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0}
  defp open_object, do: %{"type" => "object", "additionalProperties" => true}
end
