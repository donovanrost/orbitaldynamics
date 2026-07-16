defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.CapacityPack.Report do
  @moduledoc false

  alias __MODULE__.CapacityFields
  alias __MODULE__.SummaryFields

  def status_counts(report) do
    SummaryFields.status_counts(report)
  end

  def contact_status_counts(report) do
    SummaryFields.contact_status_counts(report)
  end

  def reduced_group_count(report) do
    SummaryFields.reduced_group_count(report)
  end

  def reduced_status_counts(report) do
    SummaryFields.reduced_status_counts(report)
  end

  def group_ids(report) do
    SummaryFields.group_ids(report)
  end

  def group_ids_by_status(report) do
    SummaryFields.group_ids_by_status(report)
  end

  def required_capacity_source_counts(report) do
    SummaryFields.required_capacity_source_counts(report)
  end

  def required_capacity_contact_ids_by_source(report) do
    CapacityFields.required_capacity_contact_ids_by_source(report)
  end

  def contact_ids_by_status(report) do
    CapacityFields.contact_ids_by_status(report)
  end

  def contact_count(report) do
    CapacityFields.contact_count(report)
  end

  def required_fraction(report) do
    CapacityFields.required_fraction(report)
  end

  def selected_required_fraction(report) do
    CapacityFields.selected_required_fraction(report)
  end

  def deferred_required_fraction(report) do
    CapacityFields.deferred_required_fraction(report)
  end

  def required_fraction_by_status(report) do
    CapacityFields.required_fraction_by_status(report)
  end

  def required_fraction_by_station(report) do
    CapacityFields.required_fraction_by_station(report)
  end

  def selected_required_fraction_by_station(report) do
    CapacityFields.selected_required_fraction_by_station(report)
  end

  def deferred_required_fraction_by_station(report) do
    CapacityFields.deferred_required_fraction_by_station(report)
  end

  def required_fraction_by_direction(report) do
    CapacityFields.required_fraction_by_direction(report)
  end

  def selected_required_fraction_by_direction(report) do
    CapacityFields.selected_required_fraction_by_direction(report)
  end

  def deferred_required_fraction_by_direction(report) do
    CapacityFields.deferred_required_fraction_by_direction(report)
  end

  def selected_contact_ids_by_station(report) do
    CapacityFields.selected_contact_ids_by_station(report)
  end

  def deferred_contact_ids_by_station(report) do
    CapacityFields.deferred_contact_ids_by_station(report)
  end

  def contact_ids_by_station(report) do
    CapacityFields.contact_ids_by_station(report)
  end

  def selected_contact_ids_by_direction(report) do
    CapacityFields.selected_contact_ids_by_direction(report)
  end

  def deferred_contact_ids_by_direction(report) do
    CapacityFields.deferred_contact_ids_by_direction(report)
  end

  def contact_ids_by_direction(report) do
    CapacityFields.contact_ids_by_direction(report)
  end

  def packed_contact_ids(report) do
    CapacityFields.packed_contact_ids(report)
  end

  def deferred_contact_ids(report) do
    CapacityFields.deferred_contact_ids(report)
  end
end
