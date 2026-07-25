defmodule OrbitalDynamics.Schema.OperationalTimelineValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2, require_fields: 4]

  @operational_timeline_report "operational_timeline_report.v1"

  def validate_report(issues, path, report) do
    issues
    |> require_fields(path, report, required_fields())
    |> OrbitalDynamics.Schema.OperationalTimelineReportContracts.validate(
      path,
      report,
      timeline_report_model_limits(),
      &validate_row/3
    )
  end

  def validate_optional_report(issues, nil), do: issues

  def validate_optional_report(issues, %{} = report),
    do: validate_report([], "$", report) ++ issues

  def validate_optional_report(issues, _report),
    do: [error("$.operational_timeline_report", "must be an object") | issues]

  def validate_optional_report_at_path(issues, _path, nil), do: issues

  def validate_optional_report_at_path(issues, path, %{} = report),
    do: validate_report(issues, path, report)

  def validate_optional_report_at_path(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  def validate_optional_report(issues, nil, _validate_contract), do: issues

  def validate_optional_report(issues, %{} = report, validate_contract),
    do: validate_contract.(report) ++ issues

  def validate_optional_report(issues, _report, _validate_contract),
    do: [error("$.operational_timeline_report", "must be an object") | issues]

  def validate_row(issues, path, row),
    do: validate_row(issues, path, row, default_callbacks())

  def validate_row(issues, path, row, callbacks) do
    OrbitalDynamics.Schema.OperationalTimelineRowContracts.validate(
      issues,
      path,
      row,
      Keyword.fetch!(callbacks, :validate_optional_timeline_preconditions),
      Keyword.fetch!(callbacks, :validate_optional_activity_context),
      &OrbitalDynamics.Schema.TimelineIntegrityEvidenceContracts.validate/3,
      Keyword.fetch!(callbacks, :validate_timeline_identity)
    )
  end

  defp default_callbacks do
    [
      validate_optional_timeline_preconditions:
        &OrbitalDynamics.Schema.TimelineContextValidation.validate_optional_timeline_preconditions/4,
      validate_optional_activity_context:
        &OrbitalDynamics.Schema.TimelineContextValidation.validate_optional_activity_context/4,
      validate_timeline_identity:
        &OrbitalDynamics.Schema.TimelineContextValidation.validate_timeline_identity/3
    ]
  end

  defp required_fields do
    OrbitalDynamics.Schema.OperationalTimelineRegistryContracts.contracts()
    |> Map.fetch!(@operational_timeline_report)
    |> Map.fetch!("required_fields")
  end

  defp timeline_report_model_limits,
    do: OrbitalDynamics.Schema.TimelineCapabilityContext.timeline_report_model_limits()
end
