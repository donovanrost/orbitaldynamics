defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.ProviderReservation.RequestSummary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common
  alias __MODULE__.ContactIds
  alias __MODULE__.Rows

  import Common, only: [numeric_report_count: 2]

  import Rows,
    only: [
      candidate_rows: 1,
      no_request_rows: 1,
      request_rows: 1,
      request_summary_rows?: 1,
      review_rows: 1,
      rows_for_summary: 1
    ]

  def candidate_contact_count(report) do
    case candidate_rows(report) do
      [] -> numeric_report_count(report, "provider_reservation_candidate_contact_count")
      rows -> length(rows)
    end
  end

  def request_contact_count(report) do
    case request_rows(report) do
      [] -> numeric_report_count(report, "provider_reservation_request_contact_count")
      rows -> length(rows)
    end
  end

  def review_contact_count(report) do
    case review_rows(report) do
      [] -> numeric_report_count(report, "provider_reservation_review_contact_count")
      rows -> length(rows)
    end
  end

  def no_request_contact_count(report) do
    rows = rows_for_summary(report)

    cond do
      request_summary_rows?(report) and rows != [] ->
        rows |> no_request_rows() |> length()

      true ->
        case numeric_report_count(report, "provider_reservation_no_request_contact_count") do
          count when count > 0 ->
            count

          _count ->
            case candidate_rows(report) do
              [] -> 0
              candidate_rows -> length(rows) - length(candidate_rows)
            end
        end
    end
  end

  def request_status_counts(report) do
    case Map.get(report, "provider_reservation_request_status") do
      status when is_binary(status) and status != "" ->
        %{status => 1}

      _status ->
        cond do
          review_contact_count(report) > 0 -> %{"review_required" => 1}
          request_contact_count(report) > 0 -> %{"request_ready" => 1}
          true -> nil
        end
    end
  end

  def request_contact_ids(report) do
    ContactIds.request_contact_ids(report)
  end

  def review_contact_ids(report) do
    ContactIds.review_contact_ids(report)
  end

  def no_request_contact_ids(report) do
    ContactIds.no_request_contact_ids(report)
  end

  def request_contact_ids_by_station(report) do
    ContactIds.request_contact_ids_by_station(report)
  end

  def review_contact_ids_by_station(report) do
    ContactIds.review_contact_ids_by_station(report)
  end

  def no_request_contact_ids_by_direction(report) do
    ContactIds.no_request_contact_ids_by_direction(report)
  end

  def request_contact_ids_by_direction(report) do
    ContactIds.request_contact_ids_by_direction(report)
  end

  def review_contact_ids_by_direction(report) do
    ContactIds.review_contact_ids_by_direction(report)
  end

  def no_request_contact_ids_by_direction_and_station(report) do
    ContactIds.no_request_contact_ids_by_direction_and_station(report)
  end

  def request_contact_ids_by_direction_and_station(report) do
    ContactIds.request_contact_ids_by_direction_and_station(report)
  end

  def review_contact_ids_by_direction_and_station(report) do
    ContactIds.review_contact_ids_by_direction_and_station(report)
  end

  def request_contact_ids_by_match_status(report) do
    ContactIds.request_contact_ids_by_match_status(report)
  end

  def review_contact_ids_by_match_status(report) do
    ContactIds.review_contact_ids_by_match_status(report)
  end

  def request_ids_by_match_status(report) do
    ContactIds.request_ids_by_match_status(report)
  end

  def review_ids_by_match_status(report) do
    ContactIds.review_ids_by_match_status(report)
  end
end
