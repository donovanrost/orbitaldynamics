defmodule OrbitalDynamics.Schema.ContactContentionPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.ContactContentionJsonSchema

  @report "contact_contention_report.v1"
  @resolution_report "contact_contention_resolution_report.v1"
  @resolution_summary "contact_contention_resolution_summary.v1"

  def property(field, contract_name, contract, deps)
      when contract_name in [@report, @resolution_report, @resolution_summary] do
    if ContactContentionJsonSchema.property_field?(field, contract_name) do
      deps
      |> context(contract_name)
      |> ContactContentionJsonSchema.property_fun_from_context()
      |> then(& &1.(field))
    else
      Keyword.fetch!(deps, :default_property).(field, contract_name, contract)
    end
  end

  defp context(deps, contract_name) do
    [
      contract_name: contract_name,
      schema_contract: @resolution_summary,
      source_artifact_type: @resolution_report,
      stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern),
      model_limits: Keyword.fetch!(deps, :model_limits),
      report_assumptions_schema: Keyword.fetch!(deps, :report_assumptions_schema),
      conflict_group_schema: Keyword.fetch!(deps, :conflict_group_schema),
      recommendation_schema: Keyword.fetch!(deps, :recommendation_schema),
      resolution_policy_schema: Keyword.fetch!(deps, :resolution_policy_schema)
    ]
  end
end
