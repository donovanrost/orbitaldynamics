defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ProviderReservationRequest.Fields.ContactFields.RouteFields.NestedDirectionStationFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_nested_string_list_maps: 1
    ]

  def fields(summary) do
    %{
      "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id" =>
        nested_string_list_map_fields(summary, [
          "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id",
          "provider_reservation_no_request_contact_ids_by_direction_and_ground_station"
        ]),
      "provider_reservation_request_contact_ids_by_direction_and_ground_station_id" =>
        nested_string_list_map_fields(summary, [
          "provider_reservation_request_contact_ids_by_direction_and_ground_station_id",
          "provider_reservation_request_contact_ids_by_direction_and_ground_station"
        ]),
      "provider_reservation_review_contact_ids_by_direction_and_ground_station_id" =>
        nested_string_list_map_fields(summary, [
          "provider_reservation_review_contact_ids_by_direction_and_ground_station_id",
          "provider_reservation_review_contact_ids_by_direction_and_ground_station"
        ])
    }
  end

  defp nested_string_list_map_fields(summary, fields) do
    fields
    |> Enum.map(&Map.get(summary, &1))
    |> merge_nested_string_list_maps()
  end
end
