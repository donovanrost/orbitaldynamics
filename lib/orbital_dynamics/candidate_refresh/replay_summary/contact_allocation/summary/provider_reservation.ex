defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.Summary.ProviderReservation do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.Summary.Normalization,
    only: [summary_integer: 2]

  def fields(allocation_summary) do
    %{
      "provider_reservation_candidate_contact_count" =>
        contact_count(allocation_summary, "provider_reservation_candidate_contact_count"),
      "provider_reservation_request_contact_count" =>
        contact_count(allocation_summary, "provider_reservation_request_contact_count"),
      "provider_reservation_review_contact_count" =>
        contact_count(allocation_summary, "provider_reservation_review_contact_count"),
      "provider_reservation_no_request_contact_count" =>
        contact_count(allocation_summary, "provider_reservation_no_request_contact_count"),
      "provider_reservation_request_status_counts" =>
        Map.get(allocation_summary, "provider_reservation_request_status_counts"),
      "provider_reservation_request_summary_schema_contract" =>
        Map.get(allocation_summary, "provider_reservation_request_summary_schema_contract"),
      "provider_reservation_request_contact_ids" =>
        Map.get(allocation_summary, "provider_reservation_request_contact_ids"),
      "provider_reservation_review_contact_ids" =>
        Map.get(allocation_summary, "provider_reservation_review_contact_ids"),
      "provider_reservation_no_request_contact_ids" =>
        Map.get(allocation_summary, "provider_reservation_no_request_contact_ids"),
      "provider_reservation_request_contact_ids_by_ground_station" =>
        Map.get(allocation_summary, "provider_reservation_request_contact_ids_by_ground_station"),
      "provider_reservation_review_contact_ids_by_ground_station" =>
        Map.get(allocation_summary, "provider_reservation_review_contact_ids_by_ground_station"),
      "provider_reservation_no_request_contact_ids_by_direction" =>
        Map.get(allocation_summary, "provider_reservation_no_request_contact_ids_by_direction"),
      "provider_reservation_request_contact_ids_by_direction" =>
        Map.get(allocation_summary, "provider_reservation_request_contact_ids_by_direction"),
      "provider_reservation_review_contact_ids_by_direction" =>
        Map.get(allocation_summary, "provider_reservation_review_contact_ids_by_direction"),
      "provider_reservation_no_request_contact_ids_by_direction_and_ground_station" =>
        Map.get(
          allocation_summary,
          "provider_reservation_no_request_contact_ids_by_direction_and_ground_station"
        ),
      "provider_reservation_request_contact_ids_by_direction_and_ground_station" =>
        Map.get(
          allocation_summary,
          "provider_reservation_request_contact_ids_by_direction_and_ground_station"
        ),
      "provider_reservation_review_contact_ids_by_direction_and_ground_station" =>
        Map.get(
          allocation_summary,
          "provider_reservation_review_contact_ids_by_direction_and_ground_station"
        ),
      "provider_reservation_request_contact_ids_by_match_status" =>
        Map.get(allocation_summary, "provider_reservation_request_contact_ids_by_match_status"),
      "provider_reservation_review_contact_ids_by_match_status" =>
        Map.get(allocation_summary, "provider_reservation_review_contact_ids_by_match_status"),
      "provider_reservation_request_ids_by_match_status" =>
        Map.get(allocation_summary, "provider_reservation_request_ids_by_match_status"),
      "provider_reservation_review_ids_by_match_status" =>
        Map.get(allocation_summary, "provider_reservation_review_ids_by_match_status")
    }
  end

  def pressure?(replay) do
    (replay["provider_reservation_request_contact_count"] || 0) > 0 or
      (replay["provider_reservation_review_contact_count"] || 0) > 0 or
      (replay["provider_reservation_request_contact_ids"] || []) != [] or
      (replay["provider_reservation_review_contact_ids"] || []) != [] or
      Enum.any?(
        [
          "provider_reservation_request_status_counts",
          "provider_reservation_request_contact_ids_by_ground_station",
          "provider_reservation_review_contact_ids_by_ground_station",
          "provider_reservation_no_request_contact_ids_by_direction",
          "provider_reservation_request_contact_ids_by_direction",
          "provider_reservation_review_contact_ids_by_direction",
          "provider_reservation_no_request_contact_ids_by_direction_and_ground_station",
          "provider_reservation_request_contact_ids_by_direction_and_ground_station",
          "provider_reservation_review_contact_ids_by_direction_and_ground_station",
          "provider_reservation_request_contact_ids_by_match_status",
          "provider_reservation_review_contact_ids_by_match_status",
          "provider_reservation_request_ids_by_match_status",
          "provider_reservation_review_ids_by_match_status"
        ],
        &(map_size(replay[&1] || %{}) > 0)
      )
  end

  defp contact_count(allocation_summary, field) do
    case summary_integer(allocation_summary, field) do
      0 -> nil
      count -> count
    end
  end
end
