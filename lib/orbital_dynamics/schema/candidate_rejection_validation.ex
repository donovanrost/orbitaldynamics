defmodule OrbitalDynamics.Schema.CandidateRejectionValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2, require_fields: 4]

  @candidate_rejection_report "candidate_rejection_report.v1"

  def validate_report(issues, path, report),
    do: validate_report(issues, path, report, model_limits())

  def validate_report(issues, path, report, model_limits) do
    OrbitalDynamics.Schema.CandidateRejectionReportContracts.validate(
      issues,
      path,
      report,
      model_limits
    )
  end

  def validate_optional_source_row(issues, _path, nil), do: issues

  def validate_optional_source_row(issues, path, row) do
    OrbitalDynamics.Schema.CandidateRejectionReportContracts.validate_optional_source_row(
      issues,
      path,
      row
    )
  end

  def validate_optional_report(issues, path, report),
    do:
      validate_optional_report(
        issues,
        path,
        report,
        required_fields(),
        model_limits()
      )

  def validate_optional_report(issues, _path, nil, _required_fields, _model_limits),
    do: issues

  def validate_optional_report(issues, path, %{} = report, required_fields, model_limits) do
    issues
    |> require_fields(path, report, required_fields)
    |> validate_report(path, report, model_limits)
  end

  def validate_optional_report(issues, path, _report, _required_fields, _model_limits),
    do: [error(path, "must be an object") | issues]

  defp model_limits,
    do: OrbitalDynamics.Schema.CandidateRejectionReportJsonSchema.model_limits()

  defp required_fields do
    OrbitalDynamics.Schema.PlanChangeRegistryContracts.contracts()
    |> Map.fetch!(@candidate_rejection_report)
    |> Map.fetch!("required_fields")
  end
end
