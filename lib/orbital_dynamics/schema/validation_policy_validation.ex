defmodule OrbitalDynamics.Schema.ValidationPolicyValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [require_fields: 4]

  def validate(issues, path, artifact, contract_name) do
    issues
    |> require_fields(path, artifact, required_fields(contract_name))
    |> validate_artifact(path, artifact, contract_name)
  end

  defp validate_artifact(issues, path, artifact, "validation_tolerance_policy.v1"),
    do:
      OrbitalDynamics.Schema.ValidationPolicyContracts.validate_tolerance_policy(
        issues,
        path,
        artifact
      )

  defp validate_artifact(issues, path, artifact, "backend_acceptance_policy.v1"),
    do:
      OrbitalDynamics.Schema.ValidationPolicyContracts.validate_backend_acceptance_policy(
        issues,
        path,
        artifact
      )

  defp required_fields(contract_name) do
    OrbitalDynamics.Schema.ValidationPolicyRegistryContracts.contracts()
    |> OrbitalDynamics.Schema.Registry.fetch!(contract_name)
    |> Map.fetch!("required_fields")
  end
end
