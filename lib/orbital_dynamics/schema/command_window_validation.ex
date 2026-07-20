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

  defp required_fields do
    CommandWindowRegistryContracts.contracts()
    |> Map.fetch!(@command_window_report)
    |> Map.fetch!("required_fields")
  end
end
