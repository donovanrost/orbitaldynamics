defmodule OrbitalDynamics.Schema.PlanningAnalysisSchemaProviders do
  @moduledoc false

  def build(stable_id_pattern) when is_binary(stable_id_pattern) do
    %{
      {:branch_comparison_row_json_schema, 0} => fn ->
        branch_comparison_row(stable_id_pattern)
      end,
      {:constraint_row_json_schema, 0} => fn -> constraint_row(stable_id_pattern) end,
      {:objective_satisfaction_row_json_schema, 0} => fn ->
        objective_satisfaction_row(stable_id_pattern)
      end,
      {:objective_tradeoff_row_json_schema, 0} => fn ->
        objective_tradeoff_row(stable_id_pattern)
      end,
      {:pareto_frontier_row_json_schema, 0} => fn -> pareto_frontier_row(stable_id_pattern) end,
      {:ranking_comparison_row_json_schema, 0} => fn ->
        ranking_comparison_row(stable_id_pattern)
      end,
      {:ranking_comparison_winner_json_schema, 0} => fn ->
        ranking_comparison_winner(stable_id_pattern)
      end,
      {:score_term_row_json_schema, 0} => fn ->
        score_term_row(stable_id_pattern)
      end
    }
  end

  def branch_comparison_source_row(stable_id_pattern) do
    stable_id_pattern
    |> branch_comparison_row()
    |> Map.delete("required")
  end

  def branch_scoped_downlink_context_properties(stable_id_pattern) do
    OrbitalDynamics.Schema.ScopedDownlinkContextJsonSchema.branch_from_context(
      stable_id_pattern: stable_id_pattern
    )
  end

  defp objective_satisfaction_row(stable_id_pattern) do
    OrbitalDynamics.Schema.ObjectiveReportJsonSchema.satisfaction_row_from_context(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: fn ->
        OrbitalDynamics.Schema.CommonJsonSchema.stable_id_array(stable_id_pattern)
      end
    )
  end

  defp objective_tradeoff_row(stable_id_pattern) do
    OrbitalDynamics.Schema.ObjectiveReportJsonSchema.tradeoff_row_from_context(
      stable_id_pattern: stable_id_pattern,
      numeric_map_schema: &OrbitalDynamics.Schema.CommonJsonSchema.numeric_map/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0
    )
  end

  defp ranking_comparison_row(stable_id_pattern) do
    OrbitalDynamics.Schema.OptimizerReportJsonSchema.ranking_comparison_row_from_context(
      stable_id_pattern: stable_id_pattern
    )
  end

  defp ranking_comparison_winner(stable_id_pattern) do
    OrbitalDynamics.Schema.OptimizerReportJsonSchema.ranking_comparison_winner_from_context(
      stable_id_pattern: stable_id_pattern
    )
  end

  defp pareto_frontier_row(stable_id_pattern) do
    OrbitalDynamics.Schema.OptimizerReportJsonSchema.pareto_frontier_row_from_context(
      stable_id_pattern: stable_id_pattern,
      numeric_map_schema: &OrbitalDynamics.Schema.CommonJsonSchema.numeric_map/0,
      stable_id_array_schema: fn ->
        OrbitalDynamics.Schema.CommonJsonSchema.stable_id_array(stable_id_pattern)
      end,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0
    )
  end

  defp constraint_row(stable_id_pattern) do
    OrbitalDynamics.Schema.ConstraintReportJsonSchema.row_from_context(
      stable_id_pattern: stable_id_pattern
    )
  end

  defp branch_comparison_row(stable_id_pattern) do
    OrbitalDynamics.Schema.BranchComparisonRowJsonSchema.row_from_context(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: fn ->
        OrbitalDynamics.Schema.CommonJsonSchema.stable_id_array(stable_id_pattern)
      end,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      numeric_map_schema: &OrbitalDynamics.Schema.CommonJsonSchema.numeric_map/0,
      branch_event_trust_boundary_status_counts_schema:
        &OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.trust_boundary_status_count_map/0,
      non_negative_integer_properties: fn ->
        OrbitalDynamics.Schema.BranchComparisonReportContracts.row_count_fields()
        |> OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_properties()
      end,
      branch_scoped_downlink_context_properties: fn ->
        branch_scoped_downlink_context_properties(stable_id_pattern)
      end
    )
  end

  defp score_term_row(stable_id_pattern) do
    OrbitalDynamics.Schema.ScoreTermReportJsonSchema.row_from_context(
      stable_id_pattern: stable_id_pattern
    )
  end
end
