defmodule OrbitalDynamics.Schema.ValidationAssessmentPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    ModelAcceptanceReportJsonSchema,
    ValidationSafetyCaseSummaryJsonSchema
  }

  def property(field, contract_name, contract, deps) do
    contracts = Keyword.fetch!(deps, :contracts)

    {property_field?, property} =
      property_dispatch(contract_name, contracts, deps)

    focused_property(field, contract_name, contract, property_field?, property, deps)
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.model_acceptance_report do
    {
      &ModelAcceptanceReportJsonSchema.property_field?/1,
      ModelAcceptanceReportJsonSchema.property_fun_from_context(
        intended_uses: fn -> OrbitalDynamics.Validation.capabilities().intended_uses end,
        acceptance_statuses: fn ->
          OrbitalDynamics.Validation.capabilities().acceptance_statuses
        end,
        row_statuses: fn -> OrbitalDynamics.Validation.capabilities().row_statuses end,
        model_limits: Keyword.fetch!(deps, :model_limits),
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern),
        validation_record_schema: Keyword.fetch!(deps, :validation_record_schema),
        row_schema: Keyword.fetch!(deps, :model_acceptance_row_schema)
      )
    }
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.validation_safety_case_summary do
    {
      &ValidationSafetyCaseSummaryJsonSchema.property_field?/1,
      ValidationSafetyCaseSummaryJsonSchema.property_fun_from_context(
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern),
        model_limits: Keyword.fetch!(deps, :model_limits),
        safety_case_statuses: fn ->
          OrbitalDynamics.Validation.capabilities().safety_case_statuses
        end,
        evidence_row_schema: Keyword.fetch!(deps, :safety_case_evidence_row_schema)
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
