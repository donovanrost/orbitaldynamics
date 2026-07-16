defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PressureConflictSummary.ReservationConflicts.ContactIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PressureConflictSummary.ReservationConflicts.MergedValues

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.ReservationConflict,
    as: AllocationReservationConflict

  def fields(reports) do
    %{
      "reservation_conflict_contact_ids" =>
        MergedValues.string_list(reports, &AllocationReservationConflict.contact_ids/1),
      "reservation_conflict_contact_ids_by_match_status" =>
        MergedValues.string_list_map(
          reports,
          &AllocationReservationConflict.contact_ids_by_match_status/1
        ),
      "reservation_conflict_reservation_ids_by_match_status" =>
        MergedValues.string_list_map(
          reports,
          &AllocationReservationConflict.reservation_ids_by_match_status/1
        ),
      "reservation_conflict_contact_ids_by_direction" =>
        MergedValues.string_list_map(
          reports,
          &AllocationReservationConflict.contact_ids_by_direction/1
        ),
      "reservation_conflict_contact_ids_by_direction_and_ground_station" =>
        MergedValues.nested_string_list_map(
          reports,
          &AllocationReservationConflict.contact_ids_by_direction_and_station/1
        )
    }
  end
end
