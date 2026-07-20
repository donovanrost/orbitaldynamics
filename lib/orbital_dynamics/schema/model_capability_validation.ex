defmodule OrbitalDynamics.Schema.ModelCapabilityValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [require_fields: 4]

  def validate(issues, path, artifact, contract_name) do
    issues
    |> require_fields(path, artifact, required_fields(contract_name))
    |> validate_artifact(path, artifact, contract_name)
  end

  defp validate_artifact(issues, path, artifact, "environment_model_capability.v1"),
    do:
      OrbitalDynamics.Schema.ModelCapabilityContracts.validate_environment_model(
        issues,
        path,
        artifact
      )

  defp validate_artifact(issues, path, artifact, "environment_provider_capability.v1"),
    do:
      OrbitalDynamics.Schema.ModelCapabilityContracts.validate_environment_provider(
        issues,
        path,
        artifact
      )

  defp validate_artifact(issues, path, artifact, "subsystem_model_capability.v1"),
    do:
      OrbitalDynamics.Schema.ModelCapabilityContracts.validate_subsystem_model(
        issues,
        path,
        artifact
      )

  defp required_fields(contract_name) do
    OrbitalDynamics.Schema.ModelCapabilityRegistryContracts.contracts()
    |> OrbitalDynamics.Schema.Registry.fetch!(contract_name)
    |> Map.fetch!("required_fields")
  end
end
