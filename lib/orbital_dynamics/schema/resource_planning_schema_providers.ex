defmodule OrbitalDynamics.Schema.ResourcePlanningSchemaProviders do
  @moduledoc false

  def build(stable_id_pattern, opts) when is_binary(stable_id_pattern) and is_list(opts) do
    dependencies = Map.new(opts)

    %{
      {:resource_projection_flow_row_json_schema, 0} => fn ->
        resource_projection_flow_row(stable_id_pattern, dependencies)
      end,
      {:resource_projection_row_json_schema, 0} => fn ->
        resource_projection_row(stable_id_pattern, dependencies)
      end,
      {:resource_summary_row_json_schema, 0} => fn ->
        resource_summary_row(stable_id_pattern)
      end,
      {:suppressed_candidate_json_schema, 0} => fn ->
        suppressed_candidate(stable_id_pattern, dependencies)
      end
    }
  end

  defp resource_projection_row(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.ResourceProjectionReportJsonSchema.row_from_deps(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: fn ->
        OrbitalDynamics.Schema.CommonJsonSchema.stable_id_array(stable_id_pattern)
      end,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      resource_projection_flow_row_schema: fn ->
        resource_projection_flow_row(stable_id_pattern, dependencies)
      end,
      source_window_schema: Map.fetch!(dependencies, :source_window_schema),
      approval_requirement_schema: Map.fetch!(dependencies, :approval_requirement_schema),
      policy_decision_rule_match_schema:
        Map.fetch!(dependencies, :policy_decision_rule_match_schema),
      policy_decision_schema: Map.fetch!(dependencies, :policy_decision_schema)
    )
  end

  defp resource_projection_flow_row(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.ResourceProjectionFlowSummaryJsonSchema.row_from_deps(
      stable_id_pattern: stable_id_pattern,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      source_window_schema: Map.fetch!(dependencies, :source_window_schema),
      resource_capability: &OrbitalDynamics.ResourceSummary.capabilities/0
    )
  end

  defp suppressed_candidate(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.SuppressedCandidateJsonSchema.schema_from_context(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: fn ->
        OrbitalDynamics.Schema.CommonJsonSchema.stable_id_array(stable_id_pattern)
      end,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      suppression_reasons: fn -> suppression_reasons(dependencies) end,
      policy_decision_schema: Map.fetch!(dependencies, :policy_decision_schema)
    )
  end

  defp suppression_reasons(dependencies) do
    (call(dependencies, :contact_filter_suppression_reasons) ++
       call(dependencies, :resource_filter_suppression_reasons))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp resource_summary_row(stable_id_pattern) do
    OrbitalDynamics.Schema.ResourceSummaryJsonSchema.row_from_context(
      stable_id_pattern: stable_id_pattern,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0
    )
  end

  defp call(dependencies, name), do: dependencies |> Map.fetch!(name) |> apply([])
end
