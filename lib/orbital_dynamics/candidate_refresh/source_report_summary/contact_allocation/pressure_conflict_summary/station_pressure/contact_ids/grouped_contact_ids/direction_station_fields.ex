defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PressureConflictSummary.StationPressure.ContactIds.GroupedContactIds.DirectionStationFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.StationPressure,
    as: AllocationStationPressure

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PressureConflictSummary.StationPressure.ContactIds.GroupedContactIds.MergedMaps

  def fields(reports) do
    %{
      "station_pressure_contact_ids_by_direction_and_ground_station" =>
        MergedMaps.nested_string_list(
          reports,
          &AllocationStationPressure.contact_ids_by_direction_and_station/1
        )
    }
  end
end
