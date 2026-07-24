defmodule OrbitalDynamics.Schema.ProviderCounterofferValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2, require_fields: 4]

  def validate_optional_report(issues, _path, nil), do: issues

  def validate_optional_report(issues, path, %{} = report),
    do: validate_report(issues, path, report)

  def validate_optional_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  def validate_optional_plan_impact_summary(issues, _path, nil), do: issues

  def validate_optional_plan_impact_summary(issues, path, %{} = summary),
    do: validate_plan_impact_summary(issues, path, summary)

  def validate_optional_plan_impact_summary(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  def validate_report(issues, path, artifact),
    do: validate(issues, path, artifact, "provider_counteroffer_report.v1")

  def validate_review_summary(issues, path, artifact),
    do: validate(issues, path, artifact, "provider_counteroffer_review_summary.v1")

  def validate_import_readiness_summary(issues, path, artifact),
    do: validate(issues, path, artifact, "provider_counteroffer_import_readiness_summary.v1")

  def validate_plan_impact_summary(issues, path, artifact),
    do: validate(issues, path, artifact, "provider_counteroffer_plan_impact_summary.v1")

  defp validate(issues, path, artifact, contract_name) do
    issues
    |> require_fields(path, artifact, required_fields(contract_name))
    |> validate_artifact(path, artifact, contract_name)
  end

  defp validate_artifact(issues, path, artifact, "provider_counteroffer_report.v1"),
    do:
      OrbitalDynamics.Schema.ProviderCounterofferReportContracts.validate(issues, path, artifact)

  defp validate_artifact(issues, path, artifact, "provider_counteroffer_review_summary.v1"),
    do:
      OrbitalDynamics.Schema.ProviderCounterofferSummaryContracts.validate_review(
        issues,
        path,
        artifact
      )

  defp validate_artifact(
         issues,
         path,
         artifact,
         "provider_counteroffer_import_readiness_summary.v1"
       ),
       do:
         OrbitalDynamics.Schema.ProviderCounterofferSummaryContracts.validate_import_readiness(
           issues,
           path,
           artifact
         )

  defp validate_artifact(issues, path, artifact, "provider_counteroffer_plan_impact_summary.v1"),
    do:
      OrbitalDynamics.Schema.ProviderCounterofferSummaryContracts.validate_plan_impact(
        issues,
        path,
        artifact
      )

  defp required_fields(contract_name) do
    OrbitalDynamics.Schema.ProviderCounterofferRegistryContracts.contracts()
    |> OrbitalDynamics.Schema.Registry.fetch!(contract_name)
    |> Map.fetch!("required_fields")
  end
end
