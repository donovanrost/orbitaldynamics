defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.DirectionRouting.InputFields.ValueMaps.BaseFields.ReportValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.Report,
    as: AllocationReport

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.ReservationConflict,
    as: AllocationReservationConflict

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.StationPressure,
    as: AllocationStationPressure

  alias __MODULE__.Aggregates

  def values(reports) do
    [
      direction_counts: Aggregates.count_map(reports, &AllocationReport.direction_counts/1),
      contact_ids_by_direction:
        Aggregates.string_list_map(reports, &AllocationReport.contact_ids_by_direction/1),
      station_pressure_direction_counts:
        Aggregates.count_map(reports, &AllocationStationPressure.direction_counts/1),
      station_pressure_contact_ids_by_direction:
        Aggregates.string_list_map(
          reports,
          &AllocationStationPressure.contact_ids_by_direction/1
        ),
      reservation_conflict_direction_counts:
        Aggregates.count_map(reports, &AllocationReservationConflict.direction_counts/1),
      reservation_conflict_contact_ids_by_direction:
        Aggregates.string_list_map(
          reports,
          &AllocationReservationConflict.contact_ids_by_direction/1
        )
    ]
  end
end
