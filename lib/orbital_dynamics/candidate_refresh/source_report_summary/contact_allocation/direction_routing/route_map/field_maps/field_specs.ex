defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.DirectionRouting.RouteMap.FieldMaps.FieldSpecs do
  @moduledoc false

  @route_field_names [
    :direction_counts,
    :contact_ids_by_direction,
    :station_pressure_direction_counts,
    :station_pressure_contact_ids_by_direction,
    :reservation_conflict_direction_counts,
    :reservation_conflict_contact_ids_by_direction,
    :provider_reservation_no_request_contact_ids_by_direction,
    :provider_reservation_request_contact_ids_by_direction,
    :provider_reservation_review_contact_ids_by_direction
  ]

  @route_identity_field_names @route_field_names --
                                [
                                  :direction_counts,
                                  :station_pressure_direction_counts,
                                  :reservation_conflict_direction_counts
                                ]

  def route_field_names, do: @route_field_names
  def route_identity_field_names, do: @route_identity_field_names
end
