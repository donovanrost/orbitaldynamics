defmodule OrbitalDynamics.Schema.PlanningAnalysisSchemaProviders do
  @moduledoc false

  def build(stable_id_pattern) when is_binary(stable_id_pattern) do
    %{
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
      end
    }
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
end
