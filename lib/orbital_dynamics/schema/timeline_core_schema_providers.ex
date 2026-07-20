defmodule OrbitalDynamics.Schema.TimelineCoreSchemaProviders do
  @moduledoc false

  alias OrbitalDynamics.Schema.{CommonJsonSchema, TimelineContextJsonSchema}

  def build(stable_id_pattern) when is_binary(stable_id_pattern) do
    %{
      {:activity_context_json_schema, 0} => fn -> activity_context(stable_id_pattern) end,
      {:cadence_import_json_schema, 1} => fn schema_contract ->
        cadence_import(stable_id_pattern, schema_contract)
      end,
      {:candidate_activity_source_window_json_schema, 0} => fn ->
        candidate_activity_source_window(stable_id_pattern)
      end,
      {:execution_uncertainty_json_schema, 0} => &execution_uncertainty/0,
      {:protection_decision_json_schema, 0} => fn -> protection_decision(stable_id_pattern) end,
      {:timeline_identity_json_schema, 0} => fn -> timeline_identity(stable_id_pattern) end
    }
  end

  def activity_context(stable_id_pattern) when is_binary(stable_id_pattern) do
    TimelineContextJsonSchema.activity_context(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: CommonJsonSchema.stable_id_array(stable_id_pattern),
      string_array_schema: CommonJsonSchema.string_array(),
      number_array_schema: CommonJsonSchema.number_array(),
      numeric_map_schema: CommonJsonSchema.numeric_map(),
      candidate_activity_source_window_schema:
        candidate_activity_source_window(stable_id_pattern),
      numeric_triplet_schema: CommonJsonSchema.numeric_triplet(),
      probability_schema: CommonJsonSchema.probability()
    )
  end

  def candidate_activity_source_window(stable_id_pattern) when is_binary(stable_id_pattern) do
    OrbitalDynamics.Schema.CandidateActivityJsonSchema.source_window_from_context(
      stable_id_pattern: stable_id_pattern
    )
  end

  def cadence_import(stable_id_pattern, schema_contract)
      when is_binary(stable_id_pattern) and is_binary(schema_contract) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["external_id", "activity_type"],
      "properties" => %{
        "external_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "activity_type" => %{"type" => "string"},
        "schema_contract" => %{"type" => "string", "const" => schema_contract}
      }
    }
  end

  def execution_uncertainty do
    TimelineContextJsonSchema.execution_uncertainty(CommonJsonSchema.numeric_triplet())
  end

  def protection_decision(stable_id_pattern) when is_binary(stable_id_pattern) do
    TimelineContextJsonSchema.protection_decision(stable_id_pattern)
  end

  def timeline_identity(stable_id_pattern) when is_binary(stable_id_pattern) do
    TimelineContextJsonSchema.timeline_identity(stable_id_pattern)
  end

  def timeline_link(stable_id_pattern) when is_binary(stable_id_pattern) do
    TimelineContextJsonSchema.timeline_link(stable_id_pattern)
  end

  def timeline_preservation_source(stable_id_pattern) when is_binary(stable_id_pattern) do
    OrbitalDynamics.Schema.TimelinePreservationJsonSchema.source_from_context(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: fn -> CommonJsonSchema.stable_id_array(stable_id_pattern) end,
      timeline_identity_schema: fn -> timeline_identity(stable_id_pattern) end
    )
  end

  def timeline_protection_summary(stable_id_pattern) when is_binary(stable_id_pattern) do
    stable_id_pattern
    |> CommonJsonSchema.stable_id_array()
    |> TimelineContextJsonSchema.timeline_protection_summary()
  end
end
