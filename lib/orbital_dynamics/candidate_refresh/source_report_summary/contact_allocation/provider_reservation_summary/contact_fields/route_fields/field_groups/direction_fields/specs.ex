defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.ProviderReservationSummary.ContactFields.RouteFields.FieldGroups.DirectionFields.Specs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.ProviderReservation

  @direction_fields [
    {"provider_reservation_no_request_contact_ids_by_direction",
     &ProviderReservation.no_request_contact_ids_by_direction/1},
    {"provider_reservation_request_contact_ids_by_direction",
     &ProviderReservation.request_contact_ids_by_direction/1},
    {"provider_reservation_review_contact_ids_by_direction",
     &ProviderReservation.review_contact_ids_by_direction/1}
  ]

  @nested_direction_station_fields [
    {"provider_reservation_no_request_contact_ids_by_direction_and_ground_station",
     &ProviderReservation.no_request_contact_ids_by_direction_and_station/1},
    {"provider_reservation_request_contact_ids_by_direction_and_ground_station",
     &ProviderReservation.request_contact_ids_by_direction_and_station/1},
    {"provider_reservation_review_contact_ids_by_direction_and_ground_station",
     &ProviderReservation.review_contact_ids_by_direction_and_station/1}
  ]

  def direction_fields, do: @direction_fields
  def nested_direction_station_fields, do: @nested_direction_station_fields
end
