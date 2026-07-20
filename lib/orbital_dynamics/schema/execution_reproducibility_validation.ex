defmodule OrbitalDynamics.Schema.ExecutionReproducibilityValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [require_fields: 4]

  def validate(issues, path, artifact, contract_name) do
    issues
    |> require_fields(path, artifact, required_fields(contract_name))
    |> validate_artifact(path, artifact, contract_name)
  end

  defp validate_artifact(issues, path, artifact, "execution_report.v1"),
    do: OrbitalDynamics.Schema.ExecutionReportContracts.validate(issues, path, artifact)

  defp validate_artifact(issues, path, artifact, "monte_carlo_reproducibility_report.v1"),
    do:
      OrbitalDynamics.Schema.MonteCarloReproducibilityContracts.validate(
        issues,
        path,
        artifact
      )

  defp required_fields(contract_name) do
    OrbitalDynamics.Schema.ExecutionReproducibilityRegistryContracts.contracts()
    |> OrbitalDynamics.Schema.Registry.fetch!(contract_name)
    |> Map.fetch!("required_fields")
  end
end
