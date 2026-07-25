defmodule OrbitalDynamics.Schema.CommandWindowValidation do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    CommandWindowCapabilityContext,
    CommandWindowRegistryContracts,
    CommandWindowReportContracts,
    PrimitiveValidation
  }

  @command_window_report "command_window_report.v1"

  def validate_report(issues, path, report) do
    issues
    |> PrimitiveValidation.require_fields(path, report, required_fields())
    |> CommandWindowReportContracts.validate(
      path,
      report,
      CommandWindowCapabilityContext.command_window_report_model_limits()
    )
  end

  def validate_optional_report(issues, nil), do: issues

  def validate_optional_report(issues, %{} = report) do
    validate_report(issues, "$.command_window_report", report)
  end

  def validate_optional_report(issues, _report) do
    [PrimitiveValidation.error("$.command_window_report", "must be an object") | issues]
  end

  def validate_optional_report_at_path(issues, _path, nil), do: issues

  def validate_optional_report_at_path(issues, path, %{} = report),
    do: validate_report(issues, path, report)

  def validate_optional_report_at_path(issues, path, _report),
    do: [PrimitiveValidation.error(path, "must be an object") | issues]

  defp required_fields do
    CommandWindowRegistryContracts.contracts()
    |> Map.fetch!(@command_window_report)
    |> Map.fetch!("required_fields")
  end
end
