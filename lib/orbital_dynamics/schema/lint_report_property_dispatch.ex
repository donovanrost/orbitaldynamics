defmodule OrbitalDynamics.Schema.LintReportPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.LintReportJsonSchema

  def property(field, contract_name, contract, deps) do
    contracts = Keyword.fetch!(deps, :contracts)

    {property_field?, property} =
      property_dispatch(contract_name, contracts, deps)

    focused_property(field, contract_name, contract, property_field?, property, deps)
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.campaign_request do
    {
      &LintReportJsonSchema.campaign_request_property_field?/1,
      LintReportJsonSchema.campaign_request_property_fun_from_context(
        validation_issue_schema: Keyword.fetch!(deps, :validation_issue_schema),
        sha256_schema: Keyword.fetch!(deps, :sha256_schema),
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern)
      )
    }
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.study_manifest do
    {
      &LintReportJsonSchema.study_manifest_property_field?/1,
      LintReportJsonSchema.study_manifest_property_fun_from_context(
        schema_version: 1,
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern),
        manifest_lint_issue_schema: Keyword.fetch!(deps, :manifest_lint_issue_schema)
      )
    }
  end

  defp focused_property(
         field,
         contract_name,
         contract,
         property_field?,
         property,
         deps
       ) do
    if property_field?.(field) do
      property.(field)
    else
      Keyword.fetch!(deps, :default_property).(field, contract_name, contract)
    end
  end
end
