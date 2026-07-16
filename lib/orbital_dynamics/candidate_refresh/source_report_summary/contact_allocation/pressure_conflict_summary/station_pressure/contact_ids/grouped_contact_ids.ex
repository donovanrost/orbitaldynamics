defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PressureConflictSummary.StationPressure.ContactIds.GroupedContactIds do
  @moduledoc false

  alias __MODULE__.DirectionStationFields
  alias __MODULE__.MergedMaps

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.StationPressure,
    as: AllocationStationPressure

  def fields(reports) do
    %{
      "station_pressure_contact_ids_by_ground_station" =>
        MergedMaps.string_list(
          reports,
          &AllocationStationPressure.contact_ids_by_ground_station/1
        ),
      "station_pressure_contact_ids_by_availability" =>
        MergedMaps.string_list(reports, &AllocationStationPressure.contact_ids_by_availability/1),
      "station_pressure_contact_ids_by_precedence_availability" =>
        MergedMaps.string_list(
          reports,
          &AllocationStationPressure.contact_ids_by_precedence_availability/1
        ),
      "station_pressure_contact_ids_by_precedence_rank" =>
        MergedMaps.string_list(
          reports,
          &AllocationStationPressure.contact_ids_by_precedence_rank/1
        ),
      "station_pressure_contact_ids_by_status" =>
        MergedMaps.string_list(reports, &AllocationStationPressure.contact_ids_by_status/1),
      "station_pressure_contact_ids_by_direction" =>
        MergedMaps.string_list(reports, &AllocationStationPressure.contact_ids_by_direction/1)
    }
    |> Map.merge(DirectionStationFields.fields(reports))
  end
end
