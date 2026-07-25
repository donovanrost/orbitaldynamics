defmodule OrbitalDynamics.Schema.StationReservationValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2, require_fields: 4]

  def validate_artifact(issues, path, artifact, contract_name) do
    issues
    |> require_fields(path, artifact, required_fields(contract_name))
    |> validate_registered_artifact(path, artifact, contract_name)
  end

  def validate_report_artifact(issues, path, artifact),
    do: validate_artifact(issues, path, artifact, "station_reservation_report.v1")

  def validate_optional_report(issues, _path, nil), do: issues

  def validate_optional_report(issues, path, %{} = report),
    do: validate_report_artifact(issues, path, report)

  def validate_optional_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  def validate_review_artifact(issues, path, artifact),
    do: validate_artifact(issues, path, artifact, "station_reservation_review_summary.v1")

  def validate_hold_artifact(issues, path, artifact),
    do: validate_artifact(issues, path, artifact, "station_reservation_hold_summary.v1")

  def validate_hold_import_artifact(issues, path, artifact),
    do:
      validate_artifact(
        issues,
        path,
        artifact,
        "station_reservation_hold_import_readiness_summary.v1"
      )

  def validate_calendar_provider_artifact(issues, path, artifact),
    do: validate_artifact(issues, path, artifact, "station_calendar_provider.v1")

  def validate_optional_calendar_provider(issues, _path, nil), do: issues

  def validate_optional_calendar_provider(issues, path, %{} = provider),
    do: validate_calendar_provider_artifact(issues, path, provider)

  def validate_optional_calendar_provider(issues, path, _provider),
    do: [error(path, "must be an object") | issues]

  def validate_calendar_report_artifact(issues, path, artifact),
    do: validate_artifact(issues, path, artifact, "station_calendar_report.v1")

  def validate_calendar_precedence_artifact(issues, path, artifact),
    do: validate_artifact(issues, path, artifact, "station_calendar_precedence_summary.v1")

  def validate_optional_calendar_precedence_summary(issues, _path, nil), do: issues

  def validate_optional_calendar_precedence_summary(issues, path, %{} = summary),
    do: validate_calendar_precedence_artifact(issues, path, summary)

  def validate_optional_calendar_precedence_summary(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

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

  def validate_optional_review_summary(issues, _path, nil), do: issues

  def validate_optional_review_summary(issues, path, %{} = summary),
    do: validate_review_artifact(issues, path, summary)

  def validate_optional_review_summary(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  def validate_hold_summary(issues, path, summary) do
    OrbitalDynamics.Schema.StationReservationSummaryContracts.validate_hold(
      issues,
      path,
      summary,
      model_limits()
    )
  end

  def validate_optional_hold_summary(issues, _path, nil), do: issues

  def validate_optional_hold_summary(issues, path, %{} = summary),
    do: validate_hold_artifact(issues, path, summary)

  def validate_optional_hold_summary(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  def validate_hold_import_readiness_summary(issues, path, summary) do
    OrbitalDynamics.Schema.StationReservationSummaryContracts.validate_hold_import_readiness(
      issues,
      path,
      summary,
      model_limits()
    )
  end

  def validate_optional_hold_import_readiness_summary(issues, _path, nil), do: issues

  def validate_optional_hold_import_readiness_summary(issues, path, %{} = summary),
    do: validate_hold_import_artifact(issues, path, summary)

  def validate_optional_hold_import_readiness_summary(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  defp validate_registered_artifact(issues, path, artifact, "station_reservation_report.v1") do
    OrbitalDynamics.Schema.StationReservationReportContracts.validate(
      issues,
      path,
      artifact,
      OrbitalDynamics.Schema.StationReservationReportJsonSchema.models()
    )
  end

  defp validate_registered_artifact(
         issues,
         path,
         artifact,
         "station_reservation_review_summary.v1"
       ),
       do: validate_review_summary(issues, path, artifact)

  defp validate_registered_artifact(
         issues,
         path,
         artifact,
         "station_reservation_hold_summary.v1"
       ),
       do: validate_hold_summary(issues, path, artifact)

  defp validate_registered_artifact(
         issues,
         path,
         artifact,
         "station_reservation_hold_import_readiness_summary.v1"
       ),
       do: validate_hold_import_readiness_summary(issues, path, artifact)

  defp validate_registered_artifact(issues, path, artifact, "station_calendar_provider.v1"),
    do: OrbitalDynamics.Schema.StationCalendarProviderContracts.validate(issues, path, artifact)

  defp validate_registered_artifact(issues, path, artifact, "station_calendar_report.v1"),
    do: validate_optional_calendar_report(issues, path, artifact)

  defp validate_registered_artifact(
         issues,
         path,
         artifact,
         "station_calendar_precedence_summary.v1"
       ) do
    OrbitalDynamics.Schema.StationCalendarPrecedenceSummaryContracts.validate(
      issues,
      path,
      artifact,
      model_limits()
    )
  end

  defp required_fields(contract_name) do
    [
      OrbitalDynamics.Schema.StationReservationRegistryContracts,
      OrbitalDynamics.Schema.StationReservationHoldRegistryContracts,
      OrbitalDynamics.Schema.StationCalendarRegistryContracts
    ]
    |> Enum.reduce(%{}, &Map.merge(&2, &1.contracts()))
    |> OrbitalDynamics.Schema.Registry.fetch!(contract_name)
    |> Map.fetch!("required_fields")
  end

  defp model_limits do
    OrbitalDynamics.Schema.StationCalendarCapabilityContext.station_calendar_report_model_limits()
  end

  defp model do
    OrbitalDynamics.Schema.StationCalendarCapabilityContext.station_calendar_report_model()
  end
end
