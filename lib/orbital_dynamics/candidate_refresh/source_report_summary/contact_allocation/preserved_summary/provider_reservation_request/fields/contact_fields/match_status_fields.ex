defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ProviderReservationRequest.Fields.ContactFields.MatchStatusFields do
  @moduledoc false

  alias __MODULE__.ValueMaps

  def fields(summary) do
    %{
      "provider_reservation_request_contact_ids_by_match_status" =>
        string_list_map(
          summary,
          "provider_reservation_request_contact_ids_by_match_status"
        ),
      "provider_reservation_review_contact_ids_by_match_status" =>
        string_list_map(
          summary,
          "provider_reservation_review_contact_ids_by_match_status"
        ),
      "provider_reservation_request_ids_by_match_status" =>
        string_list_map(summary, "provider_reservation_request_ids_by_match_status"),
      "provider_reservation_review_ids_by_match_status" =>
        string_list_map(summary, "provider_reservation_review_ids_by_match_status")
    }
  end

  defp string_list_map(summary, field) do
    summary
    |> Map.get(field)
    |> ValueMaps.value_lists()
  end
end
