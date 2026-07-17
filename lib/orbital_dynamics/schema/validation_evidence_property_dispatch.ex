defmodule OrbitalDynamics.Schema.ValidationEvidencePropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.ValidationJsonSchema

  def property(field, contract_name, contract, deps) do
    contracts = Keyword.fetch!(deps, :contracts)

    {property_field?, property} =
      property_dispatch(contract_name, contracts, deps)

    focused_property(field, contract_name, contract, property_field?, property, deps)
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.reference_fixture_report do
    {
      &ValidationJsonSchema.reference_fixture_report_property_field?/1,
      ValidationJsonSchema.reference_fixture_report_property_fun_from_context(
        schema_contract: contract_name,
        reference_report_schema: Keyword.fetch!(deps, :reference_report_schema)
      )
    }
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.reference_report do
    {
      &ValidationJsonSchema.reference_report_property_field?/1,
      ValidationJsonSchema.reference_report_property_fun_from_context(
        schema_contract: contract_name,
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern),
        validation_check_schema: Keyword.fetch!(deps, :validation_check_schema),
        validation_level_schema: Keyword.fetch!(deps, :validation_level_schema)
      )
    }
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.record do
    {
      &ValidationJsonSchema.record_property_field?/1,
      ValidationJsonSchema.record_property_fun_from_context(
        schema_contract: contract_name,
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern),
        validation_level_schema: Keyword.fetch!(deps, :validation_level_schema)
      )
    }
  end

  defp property_dispatch(contract_name, contracts, _deps)
       when contract_name == contracts.check do
    {
      &ValidationJsonSchema.check_property_field?/1,
      ValidationJsonSchema.check_property_fun_from_context(schema_contract: contract_name)
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
