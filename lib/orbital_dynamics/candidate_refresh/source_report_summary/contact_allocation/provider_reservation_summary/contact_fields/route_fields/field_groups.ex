defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.ProviderReservationSummary.ContactFields.RouteFields.FieldGroups do
  @moduledoc false

  alias __MODULE__.DirectionFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.ProviderReservation

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.ProviderReservationSummary.ContactFields.RouteFields.RouteMaps

  def station_fields(reports) do
    %{
      "provider_reservation_request_contact_ids_by_ground_station" =>
        RouteMaps.string_list_maps(
          reports,
          &ProviderReservation.request_contact_ids_by_station/1
        ),
      "provider_reservation_review_contact_ids_by_ground_station" =>
        RouteMaps.string_list_maps(
          reports,
          &ProviderReservation.review_contact_ids_by_station/1
        )
    }
  end

  def direction_fields(reports) do
    DirectionFields.direction_fields(reports)
  end

  def nested_direction_station_fields(reports) do
    DirectionFields.nested_direction_station_fields(reports)
  end
end
