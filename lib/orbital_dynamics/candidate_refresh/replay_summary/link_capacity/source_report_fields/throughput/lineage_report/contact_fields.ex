defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Throughput.LineageReport.ContactFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Throughput.LineageReport.Rows,
    only: [
      count_map_or_summary: 3,
      explicit_string_list: 2,
      row_contact_ids: 2,
      row_source_window_ids: 2,
      row_station_calendar_entry_ids: 2,
      row_station_calendar_provider_entry_ids: 2,
      rows_for_summary: 1,
      sorted_non_empty_values: 1,
      string_list_or_summary: 3
    ]

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Counts

  @selected_contact_fields [
    "selected_contact_ids",
    "selected_contact_id",
    "selected_contacts",
    "selected_contact"
  ]

  @actual_throughput_contact_fields [
    "actual_throughput_contact_ids",
    "actual_throughput_contact_id",
    "actual_throughput_contacts",
    "actual_throughput_contact"
  ]

  def selected_contact_id_counts(report) do
    contact_id_counts(report, "selected_contact_ids", @selected_contact_fields)
  end

  def selected_contact_ids(report) do
    contact_ids(report, "selected_contact_ids", @selected_contact_fields)
  end

  def selected_source_window_ids(report) do
    source_window_ids(report, "selected_source_window_ids", @selected_contact_fields)
  end

  def selected_station_calendar_entry_ids(report) do
    station_calendar_entry_ids(
      report,
      "selected_station_calendar_entry_ids",
      @selected_contact_fields
    )
  end

  def selected_station_calendar_provider_entry_ids(report) do
    station_calendar_provider_entry_ids(
      report,
      "selected_station_calendar_provider_entry_ids",
      @selected_contact_fields
    )
  end

  def actual_throughput_contact_id_counts(report) do
    contact_id_counts(report, "actual_throughput_contact_ids", @actual_throughput_contact_fields)
  end

  def actual_throughput_contact_ids(report) do
    contact_ids(report, "actual_throughput_contact_ids", @actual_throughput_contact_fields)
  end

  def actual_throughput_source_window_ids(report) do
    source_window_ids(
      report,
      "actual_throughput_source_window_ids",
      @actual_throughput_contact_fields
    )
  end

  def actual_throughput_station_calendar_entry_ids(report) do
    station_calendar_entry_ids(
      report,
      "actual_throughput_station_calendar_entry_ids",
      @actual_throughput_contact_fields
    )
  end

  def actual_throughput_station_calendar_provider_entry_ids(report) do
    station_calendar_provider_entry_ids(
      report,
      "actual_throughput_station_calendar_provider_entry_ids",
      @actual_throughput_contact_fields
    )
  end

  defp contact_id_counts(report, summary_field, contact_fields) do
    count_map_or_summary(
      report,
      summary_field,
      fn report ->
        report
        |> rows_for_summary()
        |> Enum.flat_map(&row_contact_ids(&1, contact_fields))
        |> Counts.normalized_values()
      end
    )
  end

  defp contact_ids(report, summary_field, contact_fields) do
    string_list_or_summary(
      report,
      summary_field,
      fn report ->
        report
        |> rows_for_summary()
        |> Enum.flat_map(&row_contact_ids(&1, contact_fields))
        |> sorted_non_empty_values()
        |> case do
          nil -> explicit_string_list(report, summary_field)
          contact_ids -> contact_ids
        end
      end
    )
  end

  defp source_window_ids(report, fallback_field, contact_fields) do
    row_lineage_ids(report, fallback_field, contact_fields, &row_source_window_ids/2)
  end

  defp station_calendar_entry_ids(report, fallback_field, contact_fields) do
    row_lineage_ids(report, fallback_field, contact_fields, &row_station_calendar_entry_ids/2)
  end

  defp station_calendar_provider_entry_ids(report, fallback_field, contact_fields) do
    row_lineage_ids(
      report,
      fallback_field,
      contact_fields,
      &row_station_calendar_provider_entry_ids/2
    )
  end

  defp row_lineage_ids(report, fallback_field, contact_fields, lineage_fun) do
    report
    |> rows_for_summary()
    |> Enum.flat_map(fn row -> lineage_fun.(row, contact_fields) || [] end)
    |> sorted_non_empty_values()
    |> case do
      nil -> explicit_string_list(report, fallback_field)
      lineage_ids -> lineage_ids
    end
  end
end
