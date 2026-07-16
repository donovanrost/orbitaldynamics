defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.Report.StatusFields do
  @moduledoc false

  alias __MODULE__.StatusContactFields
  alias __MODULE__.StatusOutcomeFields

  def allocated_contact_ids(report) do
    StatusContactFields.allocated_contact_ids(report)
  end

  def allocated_contact_count(report) do
    StatusContactFields.allocated_contact_count(report)
  end

  def allocated_contact_ids_by_station(report) do
    StatusContactFields.allocated_contact_ids_by_station(report)
  end

  def returned_allocated_contact_ids(report) do
    StatusContactFields.returned_allocated_contact_ids(report)
  end

  def returned_allocated_contact_count(report) do
    StatusContactFields.returned_allocated_contact_count(report)
  end

  def returned_allocated_contact_ids_by_station(report) do
    StatusContactFields.returned_allocated_contact_ids_by_station(report)
  end

  def deferred_contact_ids(report) do
    StatusContactFields.deferred_contact_ids(report)
  end

  def deferred_contact_count(report) do
    StatusContactFields.deferred_contact_count(report)
  end

  def deferred_contact_ids_by_station(report) do
    StatusContactFields.deferred_contact_ids_by_station(report)
  end

  def blocked_contact_ids(report) do
    StatusContactFields.blocked_contact_ids(report)
  end

  def blocked_contact_count(report) do
    StatusContactFields.blocked_contact_count(report)
  end

  def blocked_contact_ids_by_station(report) do
    StatusContactFields.blocked_contact_ids_by_station(report)
  end

  def policy_blocked_contact_ids(report) do
    StatusContactFields.policy_blocked_contact_ids(report)
  end

  def policy_blocked_allocated_contact_count(report) do
    StatusContactFields.policy_blocked_allocated_contact_count(report)
  end

  def policy_blocked_contact_ids_by_station(report) do
    StatusContactFields.policy_blocked_contact_ids_by_station(report)
  end

  def status_blocked_contact_ids(report) do
    StatusOutcomeFields.status_blocked_contact_ids(report)
  end

  def status_blocked_contact_count(report) do
    StatusOutcomeFields.status_blocked_contact_count(report)
  end

  def resource_blocked_contact_ids(report) do
    StatusOutcomeFields.resource_blocked_contact_ids(report)
  end

  def resource_blocked_contact_count(report) do
    StatusOutcomeFields.resource_blocked_contact_count(report)
  end

  def resource_blocking_dimension_counts(report) do
    StatusOutcomeFields.resource_blocking_dimension_counts(report)
  end

  def resource_blocked_contact_ids_by_dimension(report) do
    StatusOutcomeFields.resource_blocked_contact_ids_by_dimension(report)
  end

  def resource_blocked_contact_ids_by_spacecraft(report) do
    StatusOutcomeFields.resource_blocked_contact_ids_by_spacecraft(report)
  end

  def review_contact_ids(report) do
    StatusOutcomeFields.review_contact_ids(report)
  end

  def contact_ids_by_allocation_reason(report) do
    StatusOutcomeFields.contact_ids_by_allocation_reason(report)
  end

  def invalid_contact_input_ids(report) do
    StatusOutcomeFields.invalid_contact_input_ids(report)
  end

  def invalid_contact_input_count(report) do
    StatusOutcomeFields.invalid_contact_input_count(report)
  end

  def duplicate_contact_id_count(report) do
    StatusOutcomeFields.duplicate_contact_id_count(report)
  end
end
