defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ProviderReservationRequest.Fields.ContactFields.RouteFields.DirectionFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ProviderReservationRequest.Fields.ContactFields.RouteFields.ValueMaps

  def fields(summary) do
    %{
      "provider_reservation_no_request_contact_ids_by_direction" =>
        ValueMaps.string_list_map(
          summary,
          "provider_reservation_no_request_contact_ids_by_direction"
        ),
      "provider_reservation_request_contact_ids_by_direction" =>
        ValueMaps.string_list_map(
          summary,
          "provider_reservation_request_contact_ids_by_direction"
        ),
      "provider_reservation_review_contact_ids_by_direction" =>
        ValueMaps.string_list_map(
          summary,
          "provider_reservation_review_contact_ids_by_direction"
        )
    }
  end
end
