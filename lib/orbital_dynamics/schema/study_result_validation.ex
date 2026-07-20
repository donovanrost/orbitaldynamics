defmodule OrbitalDynamics.Schema.StudyResultValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [require_fields: 4]

  def validate(issues, path, artifact, contract_name) do
    issues
    |> require_fields(path, artifact, required_fields(contract_name))
    |> validate_artifact(path, artifact, contract_name)
  end

  defp validate_artifact(issues, path, artifact, "study_benchmark.v1"),
    do: OrbitalDynamics.Schema.StudyBenchmarkContracts.validate(issues, path, artifact)

  defp validate_artifact(issues, path, artifact, "manifest_field_reference.v1"),
    do: OrbitalDynamics.Schema.ManifestFieldReferenceContracts.validate(issues, path, artifact)

  defp required_fields(contract_name) do
    OrbitalDynamics.Schema.StudyResultRegistryContracts.contracts()
    |> OrbitalDynamics.Schema.Registry.fetch!(contract_name)
    |> Map.fetch!("required_fields")
  end
end
