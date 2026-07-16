defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.CapacityPack.Report.CapacityFields do
  @moduledoc false

  alias __MODULE__.ContactIdFields
  alias __MODULE__.RequiredFractionFields

  def required_capacity_contact_ids_by_source(report) do
    ContactIdFields.required_capacity_contact_ids_by_source(report)
  end

  def contact_ids_by_status(report) do
    ContactIdFields.contact_ids_by_status(report)
  end

  def contact_count(report) do
    ContactIdFields.contact_count(report)
  end

  def required_fraction(report) do
    RequiredFractionFields.required_fraction(report)
  end

  def selected_required_fraction(report) do
    RequiredFractionFields.selected_required_fraction(report)
  end

  def deferred_required_fraction(report) do
    RequiredFractionFields.deferred_required_fraction(report)
  end

  def required_fraction_by_status(report) do
    RequiredFractionFields.required_fraction_by_status(report)
  end

  def required_fraction_by_station(report) do
    RequiredFractionFields.required_fraction_by_station(report)
  end

  def selected_required_fraction_by_station(report) do
    RequiredFractionFields.selected_required_fraction_by_station(report)
  end

  def deferred_required_fraction_by_station(report) do
    RequiredFractionFields.deferred_required_fraction_by_station(report)
  end

  def required_fraction_by_direction(report) do
    RequiredFractionFields.required_fraction_by_direction(report)
  end

  def selected_required_fraction_by_direction(report) do
    RequiredFractionFields.selected_required_fraction_by_direction(report)
  end

  def deferred_required_fraction_by_direction(report) do
    RequiredFractionFields.deferred_required_fraction_by_direction(report)
  end

  def selected_contact_ids_by_station(report) do
    ContactIdFields.selected_contact_ids_by_station(report)
  end

  def deferred_contact_ids_by_station(report) do
    ContactIdFields.deferred_contact_ids_by_station(report)
  end

  def contact_ids_by_station(report) do
    ContactIdFields.contact_ids_by_station(report)
  end

  def selected_contact_ids_by_direction(report) do
    ContactIdFields.selected_contact_ids_by_direction(report)
  end

  def deferred_contact_ids_by_direction(report) do
    ContactIdFields.deferred_contact_ids_by_direction(report)
  end

  def contact_ids_by_direction(report) do
    ContactIdFields.contact_ids_by_direction(report)
  end

  def packed_contact_ids(report) do
    ContactIdFields.packed_contact_ids(report)
  end

  def deferred_contact_ids(report) do
    ContactIdFields.deferred_contact_ids(report)
  end
end
