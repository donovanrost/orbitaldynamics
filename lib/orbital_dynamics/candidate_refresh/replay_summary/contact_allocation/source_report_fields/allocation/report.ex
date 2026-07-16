defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.Report do
  @moduledoc false

  alias __MODULE__.StatusFields
  alias __MODULE__.SummaryFields

  def row_count(report) do
    SummaryFields.row_count(report)
  end

  def blocked_row_count(report) do
    SummaryFields.blocked_row_count(report)
  end

  def deferred_row_count(report) do
    SummaryFields.deferred_row_count(report)
  end

  def status_counts(report) do
    SummaryFields.status_counts(report)
  end

  def effective_status_counts(report) do
    SummaryFields.effective_status_counts(report)
  end

  def reason_counts(report) do
    SummaryFields.reason_counts(report)
  end

  def direction_counts(report) do
    SummaryFields.direction_counts(report)
  end

  def contact_ids_by_direction(report) do
    SummaryFields.contact_ids_by_direction(report)
  end

  def allocated_contact_ids(report) do
    StatusFields.allocated_contact_ids(report)
  end

  def allocated_contact_count(report) do
    StatusFields.allocated_contact_count(report)
  end

  def allocated_contact_ids_by_station(report) do
    StatusFields.allocated_contact_ids_by_station(report)
  end

  def returned_allocated_contact_ids(report) do
    StatusFields.returned_allocated_contact_ids(report)
  end

  def returned_allocated_contact_count(report) do
    StatusFields.returned_allocated_contact_count(report)
  end

  def returned_allocated_contact_ids_by_station(report) do
    StatusFields.returned_allocated_contact_ids_by_station(report)
  end

  def deferred_contact_ids(report) do
    StatusFields.deferred_contact_ids(report)
  end

  def deferred_contact_count(report) do
    StatusFields.deferred_contact_count(report)
  end

  def deferred_contact_ids_by_station(report) do
    StatusFields.deferred_contact_ids_by_station(report)
  end

  def blocked_contact_ids(report) do
    StatusFields.blocked_contact_ids(report)
  end

  def blocked_contact_count(report) do
    StatusFields.blocked_contact_count(report)
  end

  def blocked_contact_ids_by_station(report) do
    StatusFields.blocked_contact_ids_by_station(report)
  end

  def policy_blocked_contact_ids(report) do
    StatusFields.policy_blocked_contact_ids(report)
  end

  def policy_blocked_allocated_contact_count(report) do
    StatusFields.policy_blocked_allocated_contact_count(report)
  end

  def policy_blocked_contact_ids_by_station(report) do
    StatusFields.policy_blocked_contact_ids_by_station(report)
  end

  def status_blocked_contact_ids(report) do
    StatusFields.status_blocked_contact_ids(report)
  end

  def status_blocked_contact_count(report) do
    StatusFields.status_blocked_contact_count(report)
  end

  def resource_blocked_contact_ids(report) do
    StatusFields.resource_blocked_contact_ids(report)
  end

  def resource_blocked_contact_count(report) do
    StatusFields.resource_blocked_contact_count(report)
  end

  def resource_blocking_dimension_counts(report) do
    StatusFields.resource_blocking_dimension_counts(report)
  end

  def resource_blocked_contact_ids_by_dimension(report) do
    StatusFields.resource_blocked_contact_ids_by_dimension(report)
  end

  def resource_blocked_contact_ids_by_spacecraft(report) do
    StatusFields.resource_blocked_contact_ids_by_spacecraft(report)
  end

  def review_contact_ids(report) do
    StatusFields.review_contact_ids(report)
  end

  def contact_ids_by_allocation_reason(report) do
    StatusFields.contact_ids_by_allocation_reason(report)
  end

  def invalid_contact_input_ids(report) do
    StatusFields.invalid_contact_input_ids(report)
  end

  def invalid_contact_input_count(report) do
    StatusFields.invalid_contact_input_count(report)
  end

  def duplicate_contact_id_count(report) do
    StatusFields.duplicate_contact_id_count(report)
  end
end
