defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.ProviderReservation do
  @moduledoc false

  alias __MODULE__.RequestSummary

  def candidate_contact_count(report) do
    RequestSummary.candidate_contact_count(report)
  end

  def request_contact_count(report) do
    RequestSummary.request_contact_count(report)
  end

  def review_contact_count(report) do
    RequestSummary.review_contact_count(report)
  end

  def no_request_contact_count(report) do
    RequestSummary.no_request_contact_count(report)
  end

  def request_status_counts(report) do
    RequestSummary.request_status_counts(report)
  end

  def request_contact_ids(report) do
    RequestSummary.request_contact_ids(report)
  end

  def review_contact_ids(report) do
    RequestSummary.review_contact_ids(report)
  end

  def no_request_contact_ids(report) do
    RequestSummary.no_request_contact_ids(report)
  end

  def request_contact_ids_by_station(report) do
    RequestSummary.request_contact_ids_by_station(report)
  end

  def review_contact_ids_by_station(report) do
    RequestSummary.review_contact_ids_by_station(report)
  end

  def no_request_contact_ids_by_direction(report) do
    RequestSummary.no_request_contact_ids_by_direction(report)
  end

  def request_contact_ids_by_direction(report) do
    RequestSummary.request_contact_ids_by_direction(report)
  end

  def review_contact_ids_by_direction(report) do
    RequestSummary.review_contact_ids_by_direction(report)
  end

  def no_request_contact_ids_by_direction_and_station(report) do
    RequestSummary.no_request_contact_ids_by_direction_and_station(report)
  end

  def request_contact_ids_by_direction_and_station(report) do
    RequestSummary.request_contact_ids_by_direction_and_station(report)
  end

  def review_contact_ids_by_direction_and_station(report) do
    RequestSummary.review_contact_ids_by_direction_and_station(report)
  end

  def request_contact_ids_by_match_status(report) do
    RequestSummary.request_contact_ids_by_match_status(report)
  end

  def review_contact_ids_by_match_status(report) do
    RequestSummary.review_contact_ids_by_match_status(report)
  end

  def request_ids_by_match_status(report) do
    RequestSummary.request_ids_by_match_status(report)
  end

  def review_ids_by_match_status(report) do
    RequestSummary.review_ids_by_match_status(report)
  end
end
