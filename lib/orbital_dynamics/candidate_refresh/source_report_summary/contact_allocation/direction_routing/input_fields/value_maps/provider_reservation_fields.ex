defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.DirectionRouting.InputFields.ValueMaps.ProviderReservationFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.ProviderReservation

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_string_list_maps: 1
    ]

  def values(reports) do
    [
      provider_reservation_no_request_contact_ids_by_direction:
        direction_string_list_map(
          reports,
          &ProviderReservation.no_request_contact_ids_by_direction/1
        ),
      provider_reservation_request_contact_ids_by_direction:
        direction_string_list_map(
          reports,
          &ProviderReservation.request_contact_ids_by_direction/1
        ),
      provider_reservation_review_contact_ids_by_direction:
        direction_string_list_map(
          reports,
          &ProviderReservation.review_contact_ids_by_direction/1
        )
    ]
  end

  defp direction_string_list_map(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_string_list_maps()
  end
end
