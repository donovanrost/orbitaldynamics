defmodule OrbitalDynamics.Schema.SourceEvidenceSchemaProviders do
  @moduledoc false

  alias OrbitalDynamics.Schema.{CommonJsonSchema, SourceEvidenceJsonSchema}

  def build(stable_id_pattern, opts) when is_binary(stable_id_pattern) and is_list(opts) do
    dependencies = Map.new(opts)

    %{
      source_evidence: fn ->
        SourceEvidenceJsonSchema.source_evidence(
          source_dependencies(stable_id_pattern, dependencies)
        )
      end,
      operational_readiness_source_report_evidence: fn ->
        SourceEvidenceJsonSchema.operational_readiness_source_report(
          source_dependencies(stable_id_pattern, dependencies)
        )
      end,
      quality_gate_source_report_evidence: fn ->
        SourceEvidenceJsonSchema.quality_gate_source_report(
          quality_gate_dependencies(stable_id_pattern, dependencies)
        )
      end,
      source_freshness_report_evidence: fn ->
        SourceEvidenceJsonSchema.freshness_report(
          source_dependencies(stable_id_pattern, dependencies),
          OrbitalDynamics.Schema.SourceEvidenceValidation.freshness_statuses()
        )
      end,
      source_schema_validation_report_evidence: fn ->
        SourceEvidenceJsonSchema.schema_validation_report(
          source_dependencies(stable_id_pattern, dependencies),
          OrbitalDynamics.Schema.SourceEvidenceValidation.schema_validation_statuses()
        )
      end,
      source_execution_report_evidence: fn ->
        SourceEvidenceJsonSchema.execution_report(
          source_dependencies(stable_id_pattern, dependencies),
          OrbitalDynamics.Schema.ExecutionReportContracts.statuses()
        )
      end
    }
  end

  defp source_dependencies(stable_id_pattern, dependencies) do
    %{
      stable_id_pattern: stable_id_pattern,
      battery_handoff_properties:
        dependencies |> Map.fetch!(:battery_handoff_properties) |> apply([])
    }
  end

  defp quality_gate_dependencies(stable_id_pattern, dependencies) do
    source_dependencies(stable_id_pattern, dependencies)
    |> Map.merge(%{
      count_map_schema: CommonJsonSchema.non_negative_integer_count_map(),
      stable_id_array_map_schema: CommonJsonSchema.stable_id_array_map(stable_id_pattern)
    })
  end
end
