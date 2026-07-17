defmodule OrbitalDynamics.Schema.OptimizerReportPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.OptimizerReportJsonSchema

  @ranking_report "ranking_comparison_report.v1"
  @pareto_report "pareto_frontier_report.v1"

  def property(field, contract_name, contract, deps)
      when contract_name in [@ranking_report, @pareto_report] do
    if OptimizerReportJsonSchema.property_field?(field, contract_name) do
      deps
      |> context(contract_name)
      |> OptimizerReportJsonSchema.property_fun_from_context()
      |> then(& &1.(field))
    else
      Keyword.fetch!(deps, :default_property).(field, contract_name, contract)
    end
  end

  defp context(deps, contract_name) do
    [
      contract_name: contract_name,
      ranking_row_schema: Keyword.fetch!(deps, :ranking_row_schema),
      ranking_winner_schema: Keyword.fetch!(deps, :ranking_winner_schema),
      ranking_model_limits: Keyword.fetch!(deps, :ranking_model_limits),
      pareto_row_schema: Keyword.fetch!(deps, :pareto_row_schema),
      pareto_model_limits: Keyword.fetch!(deps, :pareto_model_limits),
      stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern)
    ]
  end
end
