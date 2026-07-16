defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.StationReservationSummary.ReservationFields do
  @moduledoc false

  alias __MODULE__.Aggregates
  alias __MODULE__.IdMaps

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.StationReservation

  def fields(reports) do
    %{
      "station_reservation_match_status_counts" =>
        Aggregates.count_map_merge(reports, &StationReservation.match_status_counts/1),
      "station_reservation_status_counts" =>
        Aggregates.count_map_merge(reports, &StationReservation.status_counts/1),
      "station_reserved_by_counts" =>
        Aggregates.count_map_merge(reports, &StationReservation.reserved_by_counts/1),
      "station_reservation_ids" =>
        Aggregates.string_list_merge(reports, &StationReservation.ids/1)
    }
    |> Map.merge(IdMaps.fields(reports))
  end
end
