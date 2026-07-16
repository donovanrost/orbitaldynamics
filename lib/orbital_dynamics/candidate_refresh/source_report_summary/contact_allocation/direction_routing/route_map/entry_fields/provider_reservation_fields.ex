defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.DirectionRouting.RouteMap.EntryFields.ProviderReservationFields do
  @moduledoc false

  def fields(direction, field_maps) do
    %{
      "provider_reservation_no_request_contact_ids" =>
        field_value(
          field_maps,
          :provider_reservation_no_request_contact_ids_by_direction,
          direction,
          []
        ),
      "provider_reservation_request_contact_ids" =>
        field_value(
          field_maps,
          :provider_reservation_request_contact_ids_by_direction,
          direction,
          []
        ),
      "provider_reservation_review_contact_ids" =>
        field_value(
          field_maps,
          :provider_reservation_review_contact_ids_by_direction,
          direction,
          []
        )
    }
  end

  defp field_value(field_maps, field_name, direction, default) do
    field_maps
    |> Map.fetch!(field_name)
    |> Map.get(direction, default)
  end
end
