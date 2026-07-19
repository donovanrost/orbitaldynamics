defmodule OrbitalDynamics.Schema.TimelineContextJsonSchema do
  @moduledoc false

  def timeline_identity(stable_id_pattern) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "activity_type" => %{"type" => "string"},
        "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "subject_id" => %{"type" => "string"},
        "source_window_id" => %{"type" => "string", "pattern" => stable_id_pattern}
      }
    }
  end

  def provenance do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "source" => %{"type" => "string"},
        "adapter" => %{"type" => "string"},
        "import_adapter" => %{"type" => "string"},
        "trust_boundary" => %{"type" => "string"},
        "trust_boundary_status" => %{"type" => "string"}
      }
    }
  end

  def actual_data_rate_throughput_derivation do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "derivation" => %{"type" => "string"},
        "rate_unit" => %{"type" => "string"},
        "actual_data_rate_mbps" => %{"type" => "number"},
        "actual_data_rate_mb_s" => %{"type" => "number"},
        "duration_s" => %{"type" => "number"},
        "actual_throughput_mb" => %{"type" => "number"}
      }
    }
  end

  def actual_data_rate_throughput_derivations do
    %{
      "type" => "array",
      "items" => actual_data_rate_throughput_derivation()
    }
  end

  def execution_uncertainty(numeric_triplet_schema) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "timing_3sigma_s" => %{"type" => "number"},
        "delta_v_3sigma_km_s" => numeric_triplet_schema,
        "delta_v_3sigma_magnitude_km_s" => %{"type" => "number"},
        "source" => %{"type" => "string"},
        "model" => %{"type" => "string"}
      }
    }
  end

  def protection_decision(stable_id_pattern) do
    OrbitalDynamics.Schema.TimelineSupportJsonSchema.protection_decision_from_context(
      stable_id_pattern: stable_id_pattern,
      timeline_identity_schema: fn -> timeline_identity(stable_id_pattern) end
    )
  end

  def lifecycle_transition do
    OrbitalDynamics.Schema.TimelineSupportJsonSchema.lifecycle_transition_from_context()
  end

  def timeline_link(stable_id_pattern) do
    OrbitalDynamics.Schema.TimelineSupportJsonSchema.timeline_link_from_context(
      stable_id_pattern: stable_id_pattern,
      timeline_identity_schema: fn -> timeline_identity(stable_id_pattern) end
    )
  end

  def timeline_protection_summary(stable_id_array_schema) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "preserved_locked_or_approved_count" => %{"type" => "integer", "minimum" => 0},
        "preserved_executed_count" => %{"type" => "integer", "minimum" => 0},
        "changed_locked_or_approved_count" => %{"type" => "integer", "minimum" => 0},
        "changed_executed_count" => %{"type" => "integer", "minimum" => 0},
        "preserved_locked_or_approved_activity_ids" => stable_id_array_schema,
        "preserved_executed_activity_ids" => stable_id_array_schema,
        "changed_locked_or_approved_activity_ids" => stable_id_array_schema,
        "changed_executed_activity_ids" => stable_id_array_schema
      }
    }
  end

  def activity_context(context) do
    stable_id_pattern = Keyword.fetch!(context, :stable_id_pattern)
    numeric_triplet_schema = Keyword.fetch!(context, :numeric_triplet_schema)

    OrbitalDynamics.Schema.ActivityContextJsonSchema.schema(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: Keyword.fetch!(context, :stable_id_array_schema),
      string_array_schema: Keyword.fetch!(context, :string_array_schema),
      number_array_schema: Keyword.fetch!(context, :number_array_schema),
      numeric_map_schema: Keyword.fetch!(context, :numeric_map_schema),
      provenance_schema: provenance(),
      timeline_identity_schema: timeline_identity(stable_id_pattern),
      candidate_activity_source_window_schema:
        Keyword.fetch!(context, :candidate_activity_source_window_schema),
      actual_data_rate_throughput_derivation_schema: actual_data_rate_throughput_derivation(),
      execution_uncertainty_schema: execution_uncertainty(numeric_triplet_schema),
      numeric_triplet_schema: numeric_triplet_schema,
      probability_schema: Keyword.fetch!(context, :probability_schema)
    )
  end
end
