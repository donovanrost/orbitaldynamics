defmodule OrbitalDynamics.Schema.OperationalReadinessSchemaProviders do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  def build(stable_id_pattern, opts) when is_binary(stable_id_pattern) and is_list(opts) do
    dependencies = Map.new(opts)

    %{
      {:operational_readiness_gate_json_schema, 0} => fn ->
        operational_readiness_gate(stable_id_pattern, dependencies)
      end,
      {:quality_gate_report_row_json_schema, 0} => fn ->
        quality_gate_report_row(stable_id_pattern, dependencies)
      end,
      {:operational_readiness_evidence_json_schema, 0} => fn ->
        operational_readiness_evidence(stable_id_pattern)
      end,
      {:cadence_import_operational_readiness_evidence_json_schema_properties, 0} => fn ->
        cadence_import_operational_readiness_evidence_properties(
          stable_id_pattern,
          dependencies
        )
      end,
      {:cadence_import_resource_projection_evidence_json_schema_properties, 0} => fn ->
        cadence_import_resource_projection_evidence_properties(
          stable_id_pattern,
          dependencies
        )
      end,
      {:resource_projection_battery_handoff_json_schema_properties, 0} =>
        &resource_projection_battery_handoff_properties/0
    }
  end

  defp operational_readiness_gate(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.OperationalReadinessGateJsonSchema.gate(
      capability: call(dependencies, :readiness_capability),
      stable_id_pattern: stable_id_pattern
    )
  end

  defp quality_gate_report_row(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.QualityGateReportJsonSchema.row(
      capability: call(dependencies, :readiness_capability),
      stable_id_pattern: stable_id_pattern,
      gate_schema: operational_readiness_gate(stable_id_pattern, dependencies)
    )
  end

  defp cadence_import_operational_readiness_evidence_properties(
         stable_id_pattern,
         dependencies
       ) do
    OrbitalDynamics.Schema.CadenceImportOperationalReadinessJsonSchema.evidence_properties(%{
      gate_schema: operational_readiness_gate(stable_id_pattern, dependencies),
      evidence_schema: operational_readiness_evidence(stable_id_pattern)
    })
  end

  defp resource_projection_battery_handoff_properties do
    OrbitalDynamics.Schema.ResourceProjectionHandoffJsonSchema.battery_properties(
      OrbitalDynamics.Schema.ResourceProjectionHandoffContracts.battery_handoff_number_fields()
    )
  end

  defp cadence_import_resource_projection_evidence_properties(
         stable_id_pattern,
         dependencies
       ) do
    OrbitalDynamics.Schema.ResourceProjectionHandoffJsonSchema.evidence_properties(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: CommonJsonSchema.stable_id_array(stable_id_pattern),
      string_array_schema: CommonJsonSchema.string_array(),
      approval_requirement_schema: call(dependencies, :approval_requirement_schema),
      policy_decision_rule_match_schema: call(dependencies, :policy_decision_rule_match_schema)
    )
  end

  defp operational_readiness_evidence(stable_id_pattern) do
    OrbitalDynamics.Schema.OperationalReadinessEvidenceJsonSchema.schema(
      count_map_schema: CommonJsonSchema.non_negative_integer_count_map(),
      string_array_schema: CommonJsonSchema.string_array(),
      stable_id_array_schema: CommonJsonSchema.stable_id_array(stable_id_pattern),
      branch_event_trust_boundary_status_counts_schema:
        OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.trust_boundary_status_count_map(),
      timeline_publication_context_properties:
        OrbitalDynamics.Schema.CandidateRefreshReportJsonSchema.timeline_publication_context_properties(
          stable_id_pattern: stable_id_pattern
        )
    )
  end

  defp call(dependencies, name), do: dependencies |> Map.fetch!(name) |> apply([])
end
