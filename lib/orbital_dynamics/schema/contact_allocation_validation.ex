defmodule OrbitalDynamics.Schema.ContactAllocationValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2, require_fields: 4]

  def validate_artifact(issues, path, artifact, contract_name) do
    issues
    |> require_fields(path, artifact, required_fields(contract_name))
    |> validate_registered_artifact(path, artifact, contract_name)
  end

  def validate_report_artifact(issues, path, artifact),
    do: validate_artifact(issues, path, artifact, "contact_allocation_report.v1")

  def validate_summary_artifact(issues, path, artifact),
    do: validate_artifact(issues, path, artifact, "contact_allocation_summary.v1")

  def validate_reservation_conflict_artifact(issues, path, artifact),
    do:
      validate_artifact(
        issues,
        path,
        artifact,
        "contact_allocation_reservation_conflict_summary.v1"
      )

  def validate_station_pressure_artifact(issues, path, artifact),
    do:
      validate_artifact(
        issues,
        path,
        artifact,
        "contact_allocation_station_pressure_summary.v1"
      )

  def validate_capacity_pack_artifact(issues, path, artifact),
    do: validate_artifact(issues, path, artifact, "contact_allocation_capacity_pack_summary.v1")

  def validate_provider_reservation_request_artifact(issues, path, artifact),
    do:
      validate_artifact(
        issues,
        path,
        artifact,
        "contact_allocation_provider_reservation_request_summary.v1"
      )

  def validate_optional_summary(issues, _path, nil), do: issues

  def validate_optional_summary(issues, path, %{} = summary),
    do: validate_summary_artifact(issues, path, summary)

  def validate_optional_summary(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  def validate_optional_station_pressure_summary(issues, _path, nil), do: issues

  def validate_optional_station_pressure_summary(issues, path, %{} = summary),
    do: validate_station_pressure_artifact(issues, path, summary)

  def validate_optional_station_pressure_summary(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  def validate_optional_reservation_conflict_summary(issues, _path, nil), do: issues

  def validate_optional_reservation_conflict_summary(issues, path, %{} = summary),
    do: validate_reservation_conflict_artifact(issues, path, summary)

  def validate_optional_reservation_conflict_summary(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  def validate_optional_capacity_pack_summary(issues, _path, nil), do: issues

  def validate_optional_capacity_pack_summary(issues, path, %{} = summary),
    do: validate_capacity_pack_artifact(issues, path, summary)

  def validate_optional_capacity_pack_summary(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  def validate_optional_provider_reservation_request_summary(issues, _path, nil), do: issues

  def validate_optional_provider_reservation_request_summary(issues, path, %{} = summary),
    do: validate_provider_reservation_request_artifact(issues, path, summary)

  def validate_optional_provider_reservation_request_summary(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  def validate_optional_report(issues, report),
    do: validate_optional_report(issues, report, default_callbacks())

  def validate_optional_report(issues, nil, _callbacks), do: issues

  def validate_optional_report(issues, %{} = report, callbacks),
    do: validate_report(issues, "$.contact_allocation_report", report, callbacks)

  def validate_optional_report(issues, _report, _callbacks),
    do: [error("$.contact_allocation_report", "must be an object") | issues]

  def validate_optional_report_at(issues, _path, nil), do: issues

  def validate_optional_report_at(issues, path, %{} = report),
    do: validate_report(issues, path, report)

  def validate_optional_report_at(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  def validate_report(issues, path, report),
    do: validate_report(issues, path, report, default_callbacks())

  def validate_report(issues, path, report, callbacks) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.validate_report(
      issues,
      path,
      report,
      model_limits(),
      callbacks
    )
  end

  def validate_row(issues, path, row),
    do: validate_row(issues, path, row, default_callbacks())

  def validate_row(issues, path, row, callbacks),
    do:
      OrbitalDynamics.Schema.ContactAllocationReportContracts.validate_row(
        issues,
        path,
        row,
        callbacks
      )

  def validate_capacity_pack_group(issues, path, group),
    do: validate_capacity_pack_group(issues, path, group, default_callbacks())

  def validate_capacity_pack_group(issues, path, group, callbacks),
    do:
      OrbitalDynamics.Schema.ContactAllocationReportContracts.validate_capacity_pack_group(
        issues,
        path,
        group,
        callbacks
      )

  def validate_counts(issues, path, report),
    do: validate_counts(issues, path, report, default_callbacks())

  def validate_counts(issues, path, report, callbacks),
    do:
      OrbitalDynamics.Schema.ContactAllocationReportContracts.validate_counts(
        issues,
        path,
        report,
        callbacks
      )

  def validate_summary(issues, path, summary),
    do: validate_summary(issues, path, summary, default_callbacks())

  def validate_summary(issues, path, summary, callbacks) do
    OrbitalDynamics.Schema.ContactAllocationSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      row_callback(callbacks),
      group_callback(callbacks)
    )
  end

  def validate_reservation_conflict_summary(issues, path, summary),
    do: validate_reservation_conflict_summary(issues, path, summary, default_callbacks())

  def validate_reservation_conflict_summary(issues, path, summary, callbacks),
    do:
      OrbitalDynamics.Schema.ContactAllocationReservationConflictSummaryContracts.validate_summary(
        issues,
        path,
        summary,
        row_callback(callbacks)
      )

  def validate_station_pressure_summary(issues, path, summary),
    do: validate_station_pressure_summary(issues, path, summary, default_callbacks())

  def validate_station_pressure_summary(issues, path, summary, callbacks),
    do:
      OrbitalDynamics.Schema.ContactAllocationStationPressureSummaryContracts.validate_summary(
        issues,
        path,
        summary,
        row_callback(callbacks)
      )

  def validate_capacity_pack_summary(issues, path, summary),
    do: validate_capacity_pack_summary(issues, path, summary, default_callbacks())

  def validate_capacity_pack_summary(issues, path, summary, callbacks) do
    OrbitalDynamics.Schema.ContactAllocationCapacityPackSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      row_callback(callbacks),
      group_callback(callbacks)
    )
  end

  def validate_provider_reservation_request_summary(issues, path, summary),
    do:
      validate_provider_reservation_request_summary(
        issues,
        path,
        summary,
        default_callbacks()
      )

  def validate_provider_reservation_request_summary(issues, path, summary, callbacks),
    do:
      OrbitalDynamics.Schema.ContactAllocationProviderReservationRequestSummaryContracts.validate_summary(
        issues,
        path,
        summary,
        row_callback(callbacks)
      )

  def validate_duplicate_evidence(issues, path, row),
    do: validate_duplicate_evidence(issues, path, row, default_callbacks())

  def validate_duplicate_evidence(issues, path, row, callbacks),
    do:
      OrbitalDynamics.Schema.ContactAllocationReportContracts.validate_duplicate_evidence(
        issues,
        path,
        row,
        callbacks
      )

  defp validate_registered_artifact(issues, path, artifact, "contact_allocation_report.v1"),
    do: validate_report(issues, path, artifact)

  defp validate_registered_artifact(issues, path, artifact, "contact_allocation_summary.v1"),
    do: validate_summary(issues, path, artifact)

  defp validate_registered_artifact(
         issues,
         path,
         artifact,
         "contact_allocation_reservation_conflict_summary.v1"
       ),
       do: validate_reservation_conflict_summary(issues, path, artifact)

  defp validate_registered_artifact(
         issues,
         path,
         artifact,
         "contact_allocation_station_pressure_summary.v1"
       ),
       do: validate_station_pressure_summary(issues, path, artifact)

  defp validate_registered_artifact(
         issues,
         path,
         artifact,
         "contact_allocation_capacity_pack_summary.v1"
       ),
       do: validate_capacity_pack_summary(issues, path, artifact)

  defp validate_registered_artifact(
         issues,
         path,
         artifact,
         "contact_allocation_provider_reservation_request_summary.v1"
       ),
       do: validate_provider_reservation_request_summary(issues, path, artifact)

  defp required_fields(contract_name) do
    [
      OrbitalDynamics.Schema.ContactAllocationReportRegistryContracts,
      OrbitalDynamics.Schema.ContactAllocationSummaryRegistryContracts,
      OrbitalDynamics.Schema.ContactAllocationReservationConflictRegistryContracts,
      OrbitalDynamics.Schema.ContactAllocationStationPressureRegistryContracts,
      OrbitalDynamics.Schema.ContactAllocationCapacityPackRegistryContracts,
      OrbitalDynamics.Schema.ContactAllocationProviderReservationRegistryContracts
    ]
    |> Enum.reduce(%{}, &Map.merge(&2, &1.contracts()))
    |> OrbitalDynamics.Schema.Registry.fetch!(contract_name)
    |> Map.fetch!("required_fields")
  end

  defp default_callbacks do
    [
      validate_optional_station_calendar_report:
        &OrbitalDynamics.Schema.StationReservationValidation.validate_optional_calendar_report/2,
      validate_optional_contact_filter_report:
        &OrbitalDynamics.Schema.ContactReportValidation.validate_optional_filter_report/2,
      validate_optional_contact_contention_report:
        &OrbitalDynamics.Schema.ContactReportValidation.validate_optional_contention_report/2,
      validate_optional_contact_contention_resolution_report:
        &OrbitalDynamics.Schema.ContactReportValidation.validate_optional_contention_resolution_report/2,
      validate_contact_allocation_report_counts: &validate_counts/3,
      validate_contact_allocation_row: &validate_row/3,
      validate_contact_allocation_capacity_pack_group: &validate_capacity_pack_group/3,
      validate_optional_actual_data_rate_throughput_derivation:
        &OrbitalDynamics.Schema.ExecutionMetricContracts.validate_optional_actual_data_rate_throughput_derivation/4,
      validate_contact_contention_deferred_priority:
        &OrbitalDynamics.Schema.ContactContentionReportContracts.validate_deferred_priority/3,
      validate_priority_field_evidence_counts:
        &OrbitalDynamics.Schema.PriorityOverrideContracts.validate_field_evidence_counts/3,
      validate_override_count_matches_ids:
        &OrbitalDynamics.Schema.PriorityOverrideContracts.validate_count_matches_ids/5,
      validate_station_calendar_contact_counts:
        &OrbitalDynamics.Schema.StationCalendarContactCountContracts.validate/3
    ]
  end

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
