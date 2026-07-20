defmodule OrbitalDynamics.Schema.CapabilityCatalogValidation do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    CapabilityCatalogContracts,
    PrimitiveValidation,
    Registry,
    RegistryCatalog,
    ValidationPolicyRegistryContracts
  }

  @capability_catalog "capability_catalog.v1"

  def validate(issues, path, artifact) do
    contracts = RegistryCatalog.contracts()

    issues
    |> PrimitiveValidation.require_fields(path, artifact, required_fields())
    |> CapabilityCatalogContracts.validate(path, artifact, contracts)
  end

  defp required_fields do
    ValidationPolicyRegistryContracts.contracts()
    |> Registry.fetch!(@capability_catalog)
    |> Map.fetch!("required_fields")
  end
end
