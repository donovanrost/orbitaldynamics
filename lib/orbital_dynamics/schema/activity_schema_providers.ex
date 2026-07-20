defmodule OrbitalDynamics.Schema.ActivitySchemaProviders do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  def build(stable_id_pattern, opts) when is_binary(stable_id_pattern) and is_list(opts) do
    dependencies = Map.new(opts)

    %{
      {:campaign_activity_json_schema, 0} => fn ->
        candidate_activity(stable_id_pattern, opts)
      end,
      {:candidate_activity_json_schema, 0} => fn ->
        candidate_activity(stable_id_pattern, opts)
      end,
      {:planned_activity_json_schema, 0} => fn ->
        planned_activity(stable_id_pattern, dependencies)
      end,
      {:realized_activity_json_schema, 0} => fn ->
        realized_activity(stable_id_pattern, dependencies)
      end,
      {:ground_station_identity_json_schema, 0} => fn ->
        OrbitalDynamics.Schema.IdentityJsonSchema.ground_station_from_context(stable_id_pattern)
      end,
      {:spacecraft_identity_json_schema, 0} => fn ->
        OrbitalDynamics.Schema.IdentityJsonSchema.spacecraft_from_context(stable_id_pattern)
      end,
      {:target_identity_json_schema, 0} => fn ->
        OrbitalDynamics.Schema.IdentityJsonSchema.target_from_context(stable_id_pattern)
      end
    }
  end

  def candidate_activity(stable_id_pattern, opts)
      when is_binary(stable_id_pattern) and is_list(opts) do
    dependencies = Map.new(opts)

    OrbitalDynamics.Schema.CandidateActivityJsonSchema.schema_from_context(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: fn -> CommonJsonSchema.stable_id_array(stable_id_pattern) end,
      string_array_schema: &CommonJsonSchema.string_array/0,
      source_window_schema: Map.fetch!(dependencies, :source_window_schema),
      probability_schema: &CommonJsonSchema.probability/0,
      number_or_string_schema: &CommonJsonSchema.number_or_string/0,
      activity_context_schema: Map.fetch!(dependencies, :activity_context_schema)
    )
  end

  defp planned_activity(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.PlannedActivityJsonSchema.schema(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: CommonJsonSchema.stable_id_array(stable_id_pattern),
      string_array_schema: CommonJsonSchema.string_array(),
      probability_schema: CommonJsonSchema.probability(),
      source_window_schema: call(dependencies, :source_window_schema),
      timeline_identity_schema: call(dependencies, :timeline_identity_schema),
      cadence_import_schema:
        dependencies |> Map.fetch!(:cadence_import_schema) |> apply(["planned_activity.v1"]),
      execution_uncertainty_schema: call(dependencies, :execution_uncertainty_schema)
    )
  end

  defp realized_activity(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.RealizedActivityJsonSchema.schema(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: CommonJsonSchema.stable_id_array(stable_id_pattern),
      string_array_schema: CommonJsonSchema.string_array(),
      numeric_triplet_schema: CommonJsonSchema.numeric_triplet(),
      probability_schema: CommonJsonSchema.probability(),
      number_or_string_schema: CommonJsonSchema.number_or_string(),
      execution_uncertainty_schema: call(dependencies, :execution_uncertainty_schema),
      ground_station_schema:
        OrbitalDynamics.Schema.IdentityJsonSchema.ground_station_from_context(stable_id_pattern),
      spacecraft_schema:
        OrbitalDynamics.Schema.IdentityJsonSchema.spacecraft_from_context(stable_id_pattern),
      target_schema:
        OrbitalDynamics.Schema.IdentityJsonSchema.target_from_context(stable_id_pattern)
    )
  end

  defp call(dependencies, name), do: dependencies |> Map.fetch!(name) |> apply([])
end
