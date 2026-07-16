defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.ProviderReservation.RequestSummary.ContactIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.ProviderReservation.RequestSummary.Rows
  alias __MODULE__.{MatchStatusIds, NoRequestIds, RequestReviewIds}

  import Rows,
    only: [
      candidate_row?: 1,
      request_ready_row?: 1,
      request_row?: 1
    ]

  def request_contact_ids(report) do
    RequestReviewIds.provider_contact_ids(
      report,
      "provider_reservation_request_contact_ids",
      &request_row?/1
    )
  end

  def review_contact_ids(report) do
    RequestReviewIds.provider_contact_ids(
      report,
      "provider_reservation_review_contact_ids",
      fn row -> candidate_row?(row) and not request_ready_row?(row) end
    )
  end

  def no_request_contact_ids(report) do
    NoRequestIds.no_request_contact_ids(report)
  end

  def request_contact_ids_by_station(report) do
    RequestReviewIds.contact_ids_by_field(
      report,
      [
        "provider_reservation_request_contact_ids_by_ground_station_id",
        "provider_reservation_request_contact_ids_by_ground_station"
      ],
      "ground_station_id",
      &request_row?/1
    )
  end

  def review_contact_ids_by_station(report) do
    RequestReviewIds.contact_ids_by_field(
      report,
      [
        "provider_reservation_review_contact_ids_by_ground_station_id",
        "provider_reservation_review_contact_ids_by_ground_station"
      ],
      "ground_station_id",
      fn row -> candidate_row?(row) and not request_ready_row?(row) end
    )
  end

  def no_request_contact_ids_by_direction(report) do
    NoRequestIds.no_request_contact_ids_by_direction(report)
  end

  def request_contact_ids_by_direction(report) do
    RequestReviewIds.contact_ids_by_field(
      report,
      ["provider_reservation_request_contact_ids_by_direction"],
      "direction",
      &request_row?/1
    )
  end

  def review_contact_ids_by_direction(report) do
    RequestReviewIds.contact_ids_by_field(
      report,
      ["provider_reservation_review_contact_ids_by_direction"],
      "direction",
      fn row -> candidate_row?(row) and not request_ready_row?(row) end
    )
  end

  def no_request_contact_ids_by_direction_and_station(report) do
    NoRequestIds.no_request_contact_ids_by_direction_and_station(report)
  end

  def request_contact_ids_by_direction_and_station(report) do
    RequestReviewIds.contact_ids_by_direction_and_station(
      report,
      [
        "provider_reservation_request_contact_ids_by_direction_and_ground_station_id",
        "provider_reservation_request_contact_ids_by_direction_and_ground_station"
      ],
      &request_row?/1
    )
  end

  def review_contact_ids_by_direction_and_station(report) do
    RequestReviewIds.contact_ids_by_direction_and_station(
      report,
      [
        "provider_reservation_review_contact_ids_by_direction_and_ground_station_id",
        "provider_reservation_review_contact_ids_by_direction_and_ground_station"
      ],
      fn row -> candidate_row?(row) and not request_ready_row?(row) end
    )
  end

  def request_contact_ids_by_match_status(report) do
    MatchStatusIds.request_contact_ids_by_match_status(report)
  end

  def review_contact_ids_by_match_status(report) do
    MatchStatusIds.review_contact_ids_by_match_status(report)
  end

  def request_ids_by_match_status(report) do
    MatchStatusIds.request_ids_by_match_status(report)
  end

  def review_ids_by_match_status(report) do
    MatchStatusIds.review_ids_by_match_status(report)
  end
end
