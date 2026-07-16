defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.ProviderReservationSummary do
  @moduledoc false

  alias __MODULE__.ContactFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.ProviderReservation

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      merge_count_maps: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "provider_reservation_candidate_contact_count" =>
        sum_report_count(reports, &ProviderReservation.candidate_contact_count/1),
      "provider_reservation_request_contact_count" =>
        sum_report_count(reports, &ProviderReservation.request_contact_count/1),
      "provider_reservation_review_contact_count" =>
        sum_report_count(reports, &ProviderReservation.review_contact_count/1),
      "provider_reservation_no_request_contact_count" =>
        sum_report_count(reports, &ProviderReservation.no_request_contact_count/1),
      "provider_reservation_request_status_counts" =>
        count_maps(reports, &ProviderReservation.request_status_counts/1)
    }
    |> Map.merge(ContactFields.fields(reports))
    |> compact_map()
  end

  defp count_maps(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_count_maps()
  end
end
