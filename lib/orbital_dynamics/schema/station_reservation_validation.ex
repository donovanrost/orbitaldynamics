defmodule OrbitalDynamics.Schema.StationReservationValidation do
  @moduledoc false

  def validate_optional_calendar_report(issues, report),
    do: validate_optional_calendar_report(issues, "$.station_calendar_report", report)

  def validate_optional_calendar_report(issues, path, report) do
    OrbitalDynamics.Schema.StationCalendarReportContracts.validate_optional_report(
      issues,
      path,
      report,
      model(),
      model_limits()
    )
  end

  def validate_review_summary(issues, path, summary) do
    OrbitalDynamics.Schema.StationReservationSummaryContracts.validate_review(
      issues,
      path,
      summary,
      model_limits()
    )
  end

  def validate_hold_summary(issues, path, summary) do
    OrbitalDynamics.Schema.StationReservationSummaryContracts.validate_hold(
      issues,
      path,
      summary,
      model_limits()
    )
  end

  def validate_hold_import_readiness_summary(issues, path, summary) do
    OrbitalDynamics.Schema.StationReservationSummaryContracts.validate_hold_import_readiness(
      issues,
      path,
      summary,
      model_limits()
    )
  end

  defp model_limits do
    OrbitalDynamics.Communications.StationCalendar.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp model, do: "campaign_ground_network_interval_overlay"
end
