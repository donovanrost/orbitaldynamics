defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ReservationConflictFields.ContactIds.FieldGroups do
  @moduledoc false

  def list_fields, do: ["reservation_conflict_contact_ids"]

  def flat_fields do
    [
      "reservation_conflict_contact_ids_by_match_status",
      "reservation_conflict_contact_ids_by_direction"
    ]
  end

  def nested_fields do
    [
      "reservation_conflict_contact_ids_by_direction_and_ground_station_id",
      "reservation_conflict_contact_ids_by_direction_and_ground_station"
    ]
  end
end
