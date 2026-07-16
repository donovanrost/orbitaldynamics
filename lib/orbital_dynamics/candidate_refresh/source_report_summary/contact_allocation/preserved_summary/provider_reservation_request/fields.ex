defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ProviderReservationRequest.Fields do
  @moduledoc false

  alias __MODULE__.ContactFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2
    ]

  def fields(%{} = summary, request_rows, review_rows) do
    %{
      "provider_reservation_candidate_contact_count" =>
        summary_count(
          summary,
          "provider_reservation_candidate_contact_count",
          length(request_rows) + length(review_rows)
        ),
      "provider_reservation_request_contact_count" =>
        summary_count(summary, "provider_reservation_request_contact_count", length(request_rows)),
      "provider_reservation_review_contact_count" =>
        summary_count(summary, "provider_reservation_review_contact_count", length(review_rows)),
      "provider_reservation_no_request_contact_count" =>
        numeric_report_count(summary, "provider_reservation_no_request_contact_count"),
      "provider_reservation_request_status" =>
        Map.get(summary, "provider_reservation_request_status")
    }
    |> Map.merge(ContactFields.fields(summary))
  end

  defp summary_count(summary, field, fallback_count) do
    case numeric_report_count(summary, field) do
      0 -> fallback_count
      count -> count
    end
  end
end
