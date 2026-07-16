defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ProviderReservationRequest.Fields.ContactFields do
  @moduledoc false

  alias __MODULE__.MatchStatusFields
  alias __MODULE__.RouteFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  def fields(summary) do
    summary
    |> contact_list_fields()
    |> Map.merge(RouteFields.fields(summary))
    |> Map.merge(MatchStatusFields.fields(summary))
  end

  defp contact_list_fields(summary) do
    %{
      "provider_reservation_request_contact_ids" =>
        sorted_string_values(Map.get(summary, "provider_reservation_request_contact_ids", [])),
      "provider_reservation_review_contact_ids" =>
        sorted_string_values(Map.get(summary, "provider_reservation_review_contact_ids", [])),
      "provider_reservation_no_request_contact_ids" =>
        sorted_string_values(Map.get(summary, "provider_reservation_no_request_contact_ids", []))
    }
  end
end
