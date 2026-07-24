defmodule OrbitalDynamics.Schema.ValidationArtifactValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2, require_fields: 4]

  alias OrbitalDynamics.Schema.{
    ValidationAcceptanceReportContracts,
    ValidationCapabilityContext,
    ValidationRecordContracts,
    ValidationReferenceContracts
  }

  def validate_optional_model_acceptance_report(issues, _path, nil), do: issues

  def validate_optional_model_acceptance_report(issues, path, %{} = report),
    do: validate(issues, path, report, "model_acceptance_report.v1")

  def validate_optional_model_acceptance_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  def validate(issues, path, artifact, "validation_reference_fixture_report.v1" = name),
    do:
      ValidationReferenceContracts.validate_fixture_report(issues, path, artifact, contract(name))

  def validate(issues, path, artifact, contract_name) do
    issues
    |> require_fields(path, artifact, contract(contract_name)["required_fields"])
    |> validate_artifact(path, artifact, contract_name)
  end

  defp validate_artifact(issues, path, artifact, "validation_reference_report.v1"),
    do: ValidationReferenceContracts.validate_report(issues, path, artifact)

  defp validate_artifact(issues, path, artifact, "validation_check.v1"),
    do: ValidationReferenceContracts.validate_check(issues, path, artifact)

  defp validate_artifact(issues, path, artifact, "validation_record.v1"),
    do: ValidationRecordContracts.validate(issues, path, artifact)

  defp validate_artifact(issues, path, artifact, "model_acceptance_report.v1"),
    do:
      ValidationAcceptanceReportContracts.validate_model_acceptance_report(
        issues,
        path,
        artifact,
        ValidationCapabilityContext.model_acceptance_report_model_limits()
      )

  defp validate_artifact(issues, path, artifact, "validation_safety_case_summary.v1"),
    do:
      ValidationAcceptanceReportContracts.validate_validation_safety_case_summary(
        issues,
        path,
        artifact,
        ValidationCapabilityContext.model_acceptance_report_model_limits()
      )

  defp contract(contract_name) do
    [
      OrbitalDynamics.Schema.ValidationRegistryContracts,
      OrbitalDynamics.Schema.ValidationAcceptanceRegistryContracts
    ]
    |> Enum.reduce(%{}, &Map.merge(&2, &1.contracts()))
    |> OrbitalDynamics.Schema.Registry.fetch!(contract_name)
  end
end
