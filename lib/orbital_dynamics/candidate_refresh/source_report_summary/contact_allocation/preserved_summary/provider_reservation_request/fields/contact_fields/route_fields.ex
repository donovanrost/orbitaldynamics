defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ProviderReservationRequest.Fields.ContactFields.RouteFields do
  @moduledoc false

  alias __MODULE__.DirectionFields
  alias __MODULE__.NestedDirectionStationFields
  alias __MODULE__.ValueMaps

  def fields(summary) do
    %{}
    |> Map.merge(station_fields(summary))
    |> Map.merge(DirectionFields.fields(summary))
    |> Map.merge(NestedDirectionStationFields.fields(summary))
  end

  defp station_fields(summary) do
    %{
      "provider_reservation_request_contact_ids_by_ground_station_id" =>
        ValueMaps.string_list_map(
          summary,
          "provider_reservation_request_contact_ids_by_ground_station_id"
        ),
      "provider_reservation_review_contact_ids_by_ground_station_id" =>
        ValueMaps.string_list_map(
          summary,
          "provider_reservation_review_contact_ids_by_ground_station_id"
        )
    }
  end
end
