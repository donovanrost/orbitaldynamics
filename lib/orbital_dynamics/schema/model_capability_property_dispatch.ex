defmodule OrbitalDynamics.Schema.ModelCapabilityPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.CapabilityJsonSchema

  def property(field, contract_name, contract, deps) do
    contracts = Keyword.fetch!(deps, :contracts)
    kind = capability_kind(contract_name, contracts)

    if CapabilityJsonSchema.property_field?(field, kind) do
      CapabilityJsonSchema.property_from_context(
        field,
        kind: kind,
        schema_contract: contract_name,
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern),
        validation_level_schema: Keyword.fetch!(deps, :validation_level_schema)
      )
    else
      Keyword.fetch!(deps, :default_property).(field, contract_name, contract)
    end
  end

  defp capability_kind(contract_name, contracts)
       when contract_name == contracts.environment_model,
       do: :environment_model

  defp capability_kind(contract_name, contracts)
       when contract_name == contracts.environment_provider,
       do: :environment_provider

  defp capability_kind(contract_name, contracts)
       when contract_name == contracts.subsystem_model,
       do: :subsystem_model
end
