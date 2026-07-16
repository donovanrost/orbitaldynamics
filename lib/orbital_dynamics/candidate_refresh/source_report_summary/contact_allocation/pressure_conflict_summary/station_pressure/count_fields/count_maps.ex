defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PressureConflictSummary.StationPressure.CountFields.CountMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.StationPressure,
    as: AllocationStationPressure

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1
    ]

  def fields(reports) do
    %{
      "station_pressure_ground_station_counts" =>
        count_map_merge(reports, &AllocationStationPressure.ground_station_counts/1),
      "station_pressure_availability_counts" =>
        count_map_merge(reports, &AllocationStationPressure.availability_counts/1),
      "station_pressure_precedence_availability_counts" =>
        count_map_merge(reports, &AllocationStationPressure.precedence_availability_counts/1),
      "station_pressure_precedence_rank_counts" =>
        count_map_merge(reports, &AllocationStationPressure.precedence_rank_counts/1),
      "station_pressure_status_counts" =>
        count_map_merge(reports, &AllocationStationPressure.status_counts/1),
      "station_pressure_direction_counts" =>
        count_map_merge(reports, &AllocationStationPressure.direction_counts/1)
    }
  end

  defp count_map_merge(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_count_maps()
  end
end
