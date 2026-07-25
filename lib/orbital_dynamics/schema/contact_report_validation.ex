defmodule OrbitalDynamics.Schema.ContactReportValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2, require_fields: 4]

  def validate_filter_artifact(issues, path, artifact) do
    issues
    |> require_fields(path, artifact, required_fields("contact_filter_report.v1"))
    |> validate_filter_report(path, artifact)
  end

  def validate_contention_artifact(issues, path, artifact) do
    OrbitalDynamics.Schema.ContactContentionReportContracts.validate_report(
      issues,
      path,
      artifact
    )
  end

  def validate_contention_resolution_artifact(issues, path, artifact) do
    OrbitalDynamics.Schema.ContactContentionReportContracts.validate_resolution_report(
      issues,
      path,
      artifact
    )
  end

  def validate_contention_resolution_summary_artifact(issues, path, artifact) do
    issues
    |> require_fields(
      path,
      artifact,
      required_fields("contact_contention_resolution_summary.v1")
    )
    |> OrbitalDynamics.Schema.ContactContentionResolutionSummaryContracts.validate(
      path,
      artifact,
      OrbitalDynamics.Schema.ContactContentionCapabilityContext.contact_contention_report_model_limits(),
      &OrbitalDynamics.Schema.ContactContentionReportContracts.validate_resolution_policy/3
    )
  end

  def validate_optional_filter_report(issues, report),
    do: validate_optional_filter_report(issues, "$.contact_filter_report", report)

  def validate_optional_filter_report(issues, _path, nil), do: issues

  def validate_optional_filter_report(issues, path, %{} = report),
    do: validate_filter_report(issues, path, report)

  def validate_optional_filter_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  def validate_filter_report(issues, path, report) do
    OrbitalDynamics.Schema.ContactFilterReportContracts.validate(
      issues,
      path,
      report,
      &OrbitalDynamics.Schema.ResourceValidation.validate_suppressed_candidate/3
    )
  end

  def validate_optional_contention_report(issues, report),
    do: validate_optional_contention_report(issues, "$.contact_contention_report", report)

  def validate_optional_contention_report(issues, _path, nil), do: issues

  def validate_optional_contention_report(issues, path, %{} = report) do
    OrbitalDynamics.Schema.ContactContentionReportContracts.validate_report(
      issues,
      path,
      report
    )
  end

  def validate_optional_contention_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  def validate_optional_contention_resolution_report(issues, report),
    do:
      validate_optional_contention_resolution_report(
        issues,
        "$.contact_contention_resolution_report",
        report
      )

  def validate_optional_contention_resolution_report(issues, _path, nil), do: issues

  def validate_optional_contention_resolution_report(issues, path, %{} = report) do
    OrbitalDynamics.Schema.ContactContentionReportContracts.validate_resolution_report(
      issues,
      path,
      report
    )
  end

  def validate_optional_contention_resolution_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  def validate_optional_contention_resolution_summary(issues, _path, nil), do: issues

  def validate_optional_contention_resolution_summary(issues, path, %{} = summary),
    do: validate_contention_resolution_summary_artifact(issues, path, summary)

  def validate_optional_contention_resolution_summary(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  defp required_fields(contract_name) do
    [
      OrbitalDynamics.Schema.ContactFilterRegistryContracts,
      OrbitalDynamics.Schema.ContactContentionRegistryContracts
    ]
    |> Enum.reduce(%{}, &Map.merge(&2, &1.contracts()))
    |> OrbitalDynamics.Schema.Registry.fetch!(contract_name)
    |> Map.fetch!("required_fields")
  end
end
