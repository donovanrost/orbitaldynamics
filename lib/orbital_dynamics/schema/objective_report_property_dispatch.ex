defmodule OrbitalDynamics.Schema.ObjectiveReportPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.ObjectiveReportJsonSchema

  @satisfaction_report "objective_satisfaction_report.v1"
  @tradeoff_report "objective_tradeoff_report.v1"

  def property(field, contract_name, contract, deps)
      when contract_name in [@satisfaction_report, @tradeoff_report] do
    if ObjectiveReportJsonSchema.property_field?(field, contract_name) do
      deps
      |> context(contract_name)
      |> ObjectiveReportJsonSchema.property_fun_from_context()
      |> then(& &1.(field))
    else
      Keyword.fetch!(deps, :default_property).(field, contract_name, contract)
    end
  end

  defp context(deps, contract_name) do
    [
      contract_name: contract_name,
      satisfaction_row_schema: Keyword.fetch!(deps, :satisfaction_row_schema),
      satisfaction_model_limits: Keyword.fetch!(deps, :satisfaction_model_limits),
      tradeoff_row_schema: Keyword.fetch!(deps, :tradeoff_row_schema),
      tradeoff_models: Keyword.fetch!(deps, :tradeoff_models),
      score_report_model_limits: Keyword.fetch!(deps, :score_report_model_limits)
    ]
  end
end
