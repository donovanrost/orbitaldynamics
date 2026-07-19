defmodule OrbitalDynamics.Schema.ContactAllocationValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  def validate_optional_report(issues, nil, _callbacks), do: issues

  def validate_optional_report(issues, %{} = report, callbacks),
    do: validate_report(issues, "$.contact_allocation_report", report, callbacks)

  def validate_optional_report(issues, _report, _callbacks),
    do: [error("$.contact_allocation_report", "must be an object") | issues]

  def validate_report(issues, path, report, callbacks) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.validate_report(
      issues,
      path,
      report,
      model_limits(),
      callbacks
    )
  end

  def validate_row(issues, path, row, callbacks),
    do:
      OrbitalDynamics.Schema.ContactAllocationReportContracts.validate_row(
        issues,
        path,
        row,
        callbacks
      )

  def validate_capacity_pack_group(issues, path, group, callbacks),
    do:
      OrbitalDynamics.Schema.ContactAllocationReportContracts.validate_capacity_pack_group(
        issues,
        path,
        group,
        callbacks
      )

  def validate_counts(issues, path, report, callbacks),
    do:
      OrbitalDynamics.Schema.ContactAllocationReportContracts.validate_counts(
        issues,
        path,
        report,
        callbacks
      )

  def validate_summary(issues, path, summary, callbacks) do
    OrbitalDynamics.Schema.ContactAllocationSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      row_callback(callbacks),
      group_callback(callbacks)
    )
  end

  def validate_reservation_conflict_summary(issues, path, summary, callbacks),
    do:
      OrbitalDynamics.Schema.ContactAllocationReservationConflictSummaryContracts.validate_summary(
        issues,
        path,
        summary,
        row_callback(callbacks)
      )

  def validate_station_pressure_summary(issues, path, summary, callbacks),
    do:
      OrbitalDynamics.Schema.ContactAllocationStationPressureSummaryContracts.validate_summary(
        issues,
        path,
        summary,
        row_callback(callbacks)
      )

  def validate_capacity_pack_summary(issues, path, summary, callbacks) do
    OrbitalDynamics.Schema.ContactAllocationCapacityPackSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      row_callback(callbacks),
      group_callback(callbacks)
    )
  end

  def validate_provider_reservation_request_summary(issues, path, summary, callbacks),
    do:
      OrbitalDynamics.Schema.ContactAllocationProviderReservationRequestSummaryContracts.validate_summary(
        issues,
        path,
        summary,
        row_callback(callbacks)
      )

  def validate_duplicate_evidence(issues, path, row, callbacks),
    do:
      OrbitalDynamics.Schema.ContactAllocationReportContracts.validate_duplicate_evidence(
        issues,
        path,
        row,
        callbacks
      )

  defp row_callback(callbacks),
    do: fn issues, path, row -> validate_row(issues, path, row, callbacks) end

  defp group_callback(callbacks),
    do: fn issues, path, group -> validate_capacity_pack_group(issues, path, group, callbacks) end

  defp model_limits do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end
end
