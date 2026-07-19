defmodule OrbitalDynamics.Schema.ContactReportValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

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

  def validate_optional_contention_report(issues, nil), do: issues

  def validate_optional_contention_report(issues, %{} = report) do
    OrbitalDynamics.Schema.ContactContentionReportContracts.validate_report(
      issues,
      "$.contact_contention_report",
      report
    )
  end

  def validate_optional_contention_report(issues, _report),
    do: [error("$.contact_contention_report", "must be an object") | issues]

  def validate_optional_contention_resolution_report(issues, nil), do: issues

  def validate_optional_contention_resolution_report(issues, %{} = report) do
    OrbitalDynamics.Schema.ContactContentionReportContracts.validate_resolution_report(
      issues,
      "$.contact_contention_resolution_report",
      report
    )
  end

  def validate_optional_contention_resolution_report(issues, _report),
    do: [error("$.contact_contention_resolution_report", "must be an object") | issues]
end
