defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.ProviderReservationSummary.ContactFields do
  @moduledoc false

  alias __MODULE__.MatchStatusFields
  alias __MODULE__.RouteFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.ProviderReservation

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_string_lists: 1]

  def fields(reports) do
    reports
    |> list_fields()
    |> Map.merge(RouteFields.fields(reports))
    |> Map.merge(MatchStatusFields.fields(reports))
  end

  defp list_fields(reports) do
    %{
      "provider_reservation_request_contact_ids" =>
        string_lists(reports, &ProviderReservation.request_contact_ids/1),
      "provider_reservation_review_contact_ids" =>
        string_lists(reports, &ProviderReservation.review_contact_ids/1),
      "provider_reservation_no_request_contact_ids" =>
        string_lists(reports, &ProviderReservation.no_request_contact_ids/1)
    }
  end

  defp string_lists(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_string_lists()
  end
end
