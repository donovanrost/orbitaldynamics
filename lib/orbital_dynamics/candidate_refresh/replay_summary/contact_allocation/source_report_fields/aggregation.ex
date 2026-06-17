defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Aggregation do
  @moduledoc false

  alias __MODULE__.ContactCount
  alias __MODULE__.SourceReports
  alias __MODULE__.Values

  def source_report_station_pressure_contact_count(source_reports) do
    SourceReports.contact_count(
      source_reports,
      &contact_allocation_station_pressure_contact_count/1
    )
  end

  def source_report_station_pressure_review_contact_count(source_reports) do
    SourceReports.contact_count(
      source_reports,
      &contact_allocation_station_pressure_review_contact_count/1
    )
  end

  def source_report_reservation_conflict_contact_count(source_reports) do
    SourceReports.contact_count(
      source_reports,
      &contact_allocation_reservation_conflict_contact_count/1
    )
  end

  def source_report_family_count(source_reports, field) do
    SourceReports.count(source_reports, field)
  end

  def source_report_family_identity_count(source_reports, field) do
    SourceReports.identity_count(source_reports, field)
  end

  def source_report_family_identity_field(source_reports, field) do
    SourceReports.identity_field(source_reports, field)
  end

  def source_report_family_field(source_reports, field) do
    SourceReports.field(source_reports, field)
  end

  def source_report_family_numeric_sum(source_reports, field) do
    SourceReports.numeric_sum(source_reports, field)
  end

  def source_report_family_numeric_min(source_reports, field) do
    SourceReports.numeric_min(source_reports, field)
  end

  def source_report_capacity_pack_contact_count(source_reports) do
    SourceReports.contact_count(source_reports, &contact_allocation_capacity_pack_contact_count/1)
  end

  def source_report_family_merge_count_maps(source_reports, field) do
    SourceReports.merge_count_maps(source_reports, field)
  end

  def source_report_family_merge_numeric_maps(source_reports, field) do
    SourceReports.merge_numeric_maps(source_reports, field)
  end

  def source_report_family_merge_numeric_lists(source_reports, field) do
    SourceReports.merge_numeric_lists(source_reports, field)
  end

  def source_report_family_merge_string_list_maps(source_reports, field) do
    SourceReports.merge_string_list_maps(source_reports, field)
  end

  def source_report_family_merge_string_list_map_fields(source_reports, fields) do
    SourceReports.merge_string_list_map_fields(source_reports, fields)
  end

  def source_report_family_merge_nested_string_list_maps(source_reports, field) do
    SourceReports.merge_nested_string_list_maps(source_reports, field)
  end

  def source_report_family_merge_nested_string_list_map_fields(source_reports, fields) do
    SourceReports.merge_nested_string_list_map_fields(source_reports, fields)
  end

  def source_report_family_merge_string_lists(source_reports, field) do
    SourceReports.merge_string_lists(source_reports, field)
  end

  def contact_allocation_capacity_pack_contact_count(summary) do
    ContactCount.capacity_pack_contact_count(summary)
  end

  def contact_allocation_station_pressure_contact_count(summary) do
    ContactCount.station_pressure_contact_count(summary)
  end

  def contact_allocation_station_pressure_review_contact_count(summary) do
    ContactCount.station_pressure_review_contact_count(summary)
  end

  def contact_allocation_reservation_conflict_contact_count(summary) do
    ContactCount.reservation_conflict_contact_count(summary)
  end

  def summary_nested_string_list_map_fields(summary, fields) do
    fields
    |> Enum.map(&Map.get(summary, &1))
    |> Values.merge_nested_string_list_maps()
  end
end
