defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.ProviderReservationSummary.ContactFields.MatchStatusFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.ProviderReservation

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_string_list_maps: 1]

  def fields(reports) do
    %{
      "provider_reservation_request_contact_ids_by_match_status" =>
        string_list_maps(
          reports,
          &ProviderReservation.request_contact_ids_by_match_status/1
        ),
      "provider_reservation_review_contact_ids_by_match_status" =>
        string_list_maps(
          reports,
          &ProviderReservation.review_contact_ids_by_match_status/1
        ),
      "provider_reservation_request_ids_by_match_status" =>
        string_list_maps(reports, &ProviderReservation.request_ids_by_match_status/1),
      "provider_reservation_review_ids_by_match_status" =>
        string_list_maps(reports, &ProviderReservation.review_ids_by_match_status/1)
    }
  end

  defp string_list_maps(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_string_list_maps()
  end
end
