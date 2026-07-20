defmodule OrbitalDynamics.Schema.ContactIntentValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [require_fields: 4]

  def validate_intent(issues, path, artifact),
    do: validate(issues, path, artifact, "contact_intent.v1")

  def validate_summary(issues, path, artifact),
    do: validate(issues, path, artifact, "contact_intent_summary.v1")

  defp validate(issues, path, artifact, contract_name) do
    issues
    |> require_fields(path, artifact, required_fields(contract_name))
    |> validate_artifact(path, artifact, contract_name)
  end

  defp validate_artifact(issues, path, artifact, "contact_intent.v1"),
    do: OrbitalDynamics.Schema.ContactIntentContracts.validate(issues, path, artifact)

  defp validate_artifact(issues, path, artifact, "contact_intent_summary.v1"),
    do:
      OrbitalDynamics.Schema.ContactIntentSummaryContracts.validate_summary(
        issues,
        path,
        artifact
      )

  defp required_fields(contract_name) do
    OrbitalDynamics.Schema.ContactIntentRegistryContracts.contracts()
    |> OrbitalDynamics.Schema.Registry.fetch!(contract_name)
    |> Map.fetch!("required_fields")
  end
end
