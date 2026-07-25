defmodule OrbitalDynamics.Schema.SchemaOperationsValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2, require_fields: 4]

  def validate_optional_schema_validation_report(issues, _path, nil), do: issues

  def validate_optional_schema_validation_report(issues, path, %{} = report),
    do: validate(issues, path, report, "schema_validation_report.v1")

  def validate_optional_schema_validation_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  def validate_optional_schema_validation_batch_report(issues, _path, nil), do: issues

  def validate_optional_schema_validation_batch_report(issues, path, %{} = report),
    do: validate(issues, path, report, "schema_validation_batch_report.v1")

  def validate_optional_schema_validation_batch_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  def validate(issues, path, artifact, contract_name) do
    issues
    |> require_fields(path, artifact, required_fields(contract_name))
    |> validate_artifact(path, artifact, contract_name)
  end

  defp validate_artifact(issues, path, artifact, "schema_validation_report.v1"),
    do: OrbitalDynamics.Schema.ValidationReportContracts.validate_report(issues, path, artifact)

  defp validate_artifact(issues, path, artifact, "schema_validation_batch_report.v1"),
    do: OrbitalDynamics.Schema.ValidationReportContracts.validate_batch(issues, path, artifact)

  defp validate_artifact(issues, path, artifact, "schema_migration_report.v1"),
    do: OrbitalDynamics.Schema.SchemaMigrationContracts.validate(issues, path, artifact)

  defp validate_artifact(issues, path, artifact, "campaign_request_lint.v1"),
    do: OrbitalDynamics.Schema.LintContracts.validate_campaign_request(issues, path, artifact)

  defp validate_artifact(issues, path, artifact, "study_manifest_lint.v1"),
    do: OrbitalDynamics.Schema.LintContracts.validate_study_manifest(issues, path, artifact)

  defp required_fields(contract_name) do
    [
      OrbitalDynamics.Schema.ValidationRegistryContracts,
      OrbitalDynamics.Schema.LintRegistryContracts
    ]
    |> Enum.reduce(%{}, &Map.merge(&2, &1.contracts()))
    |> OrbitalDynamics.Schema.Registry.fetch!(contract_name)
    |> Map.fetch!("required_fields")
  end
end
