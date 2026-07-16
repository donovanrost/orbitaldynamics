defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PressureConflictSummary.ReservationConflicts do
  @moduledoc false

  alias __MODULE__.{ContactIds, MergedValues}

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.ReservationConflict,
    as: AllocationReservationConflict

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "reservation_conflict_contact_count" =>
        sum_report_count(reports, &AllocationReservationConflict.contact_count/1),
      "reservation_conflict_match_status_counts" =>
        MergedValues.count_map(reports, &AllocationReservationConflict.match_status_counts/1),
      "reservation_conflict_direction_counts" =>
        MergedValues.count_map(reports, &AllocationReservationConflict.direction_counts/1)
    }
    |> Map.merge(ContactIds.fields(reports))
    |> compact_map()
  end
end
