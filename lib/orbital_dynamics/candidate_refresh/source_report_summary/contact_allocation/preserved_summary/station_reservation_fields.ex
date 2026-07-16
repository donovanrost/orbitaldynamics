defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.StationReservationFields do
  @moduledoc false

  alias __MODULE__.{ExpirationFields, StringListMaps}

  def fields(summary) do
    %{
      "station_reservation_match_status_counts" =>
        Map.get(summary, "station_reservation_match_status_counts"),
      "station_reservation_status_counts" =>
        Map.get(summary, "station_reservation_status_counts"),
      "station_reserved_by_counts" => Map.get(summary, "station_reserved_by_counts")
    }
    |> Map.merge(StringListMaps.fields(summary))
    |> Map.merge(ExpirationFields.fields(summary))
  end
end
