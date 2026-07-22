defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.StationPressure do
  @moduledoc false

  alias __MODULE__.Summary

  def contact_count(report) do
    Summary.contact_count(report)
  end

  def contact_ids(report) do
    Summary.contact_ids(report)
  end

  def review_contact_count(report) do
    Summary.review_contact_count(report)
  end

  def review_contact_ids(report) do
    Summary.review_contact_ids(report)
  end

  def ground_station_counts(report) do
    Summary.ground_station_counts(report)
  end

  def contact_ids_by_ground_station(report) do
    Summary.contact_ids_by_ground_station(report)
  end

  def availability_counts(report) do
    Summary.availability_counts(report)
  end

  def contact_ids_by_availability(report) do
    Summary.contact_ids_by_availability(report)
  end

  def precedence_availability_counts(report) do
    Summary.precedence_availability_counts(report)
  end

  def contact_ids_by_precedence_availability(report) do
    Summary.contact_ids_by_precedence_availability(report)
  end

  def precedence_rank_counts(report) do
    Summary.precedence_rank_counts(report)
  end

  def contact_ids_by_precedence_rank(report) do
    Summary.contact_ids_by_precedence_rank(report)
  end

  def status_counts(report) do
    Summary.status_counts(report)
  end

  def contact_ids_by_status(report) do
    Summary.contact_ids_by_status(report)
  end

  def direction_counts(report) do
    Summary.direction_counts(report)
  end

  def contact_ids_by_direction(report) do
    Summary.contact_ids_by_direction(report)
  end

  def contact_ids_by_direction_and_station(report) do
    Summary.contact_ids_by_direction_and_station(report)
  end
end
