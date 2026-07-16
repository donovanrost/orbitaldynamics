defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.Report.StatusFields.StatusOutcomeFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Counts

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.Report.Rows

  import Common, only: [numeric_report_count: 2]

  import Rows,
    only: [
      duplicate_contact_row?: 1,
      group_key: 2,
      grouped_contact_ids: 1,
      invalid_contact_input_rows: 1,
      map_value_lists: 1,
      resource_blocked_contact_ids_by_field: 3,
      resource_blocked_rows: 1,
      review_rows: 1,
      rows_for_summary: 1,
      sorted_non_empty_values: 1,
      status_blocked_rows: 1,
      summary_contact_id: 1
    ]

  def status_blocked_contact_ids(report) do
    case status_blocked_rows(report) do
      [] ->
        report
        |> Map.get("status_blocked_contact_ids", [])
        |> List.wrap()
        |> sorted_non_empty_values()

      rows ->
        rows
        |> Enum.map(&summary_contact_id/1)
        |> sorted_non_empty_values()
    end
  end

  def status_blocked_contact_count(report) do
    case rows_for_summary(report) do
      [] -> numeric_report_count(report, "status_blocked_contact_count")
      _rows -> length(status_blocked_rows(report))
    end
  end

  def resource_blocked_contact_ids(report) do
    case resource_blocked_rows(report) do
      [] ->
        report
        |> Map.get("resource_blocked_contact_ids", [])
        |> List.wrap()
        |> sorted_non_empty_values()

      rows ->
        rows
        |> Enum.map(&summary_contact_id/1)
        |> sorted_non_empty_values()
    end
  end

  def resource_blocked_contact_count(report) do
    case rows_for_summary(report) do
      [] -> numeric_report_count(report, "resource_blocked_contact_count")
      _rows -> length(resource_blocked_rows(report))
    end
  end

  def resource_blocking_dimension_counts(report) do
    case resource_blocked_rows(report) do
      [] -> Map.get(report, "resource_blocking_dimension_counts")
      rows -> Counts.normalized_rows(rows, "resource_blocking_dimension")
    end
  end

  def resource_blocked_contact_ids_by_dimension(report) do
    resource_blocked_contact_ids_by_field(
      report,
      "resource_blocked_contact_ids_by_blocking_dimension",
      "resource_blocking_dimension"
    )
  end

  def resource_blocked_contact_ids_by_spacecraft(report) do
    resource_blocked_contact_ids_by_field(
      report,
      "resource_blocked_contact_ids_by_spacecraft_id",
      "spacecraft_id"
    )
  end

  def review_contact_ids(report) do
    case review_rows(report) do
      [] ->
        report
        |> Map.get("review_contact_ids", [])
        |> List.wrap()
        |> sorted_non_empty_values()

      rows ->
        rows
        |> Enum.map(&summary_contact_id/1)
        |> sorted_non_empty_values()
    end
  end

  def contact_ids_by_allocation_reason(report) do
    case rows_for_summary(report) do
      [] ->
        report
        |> Map.get("contact_ids_by_allocation_reason")
        |> map_value_lists()

      rows ->
        rows
        |> Enum.map(fn row -> {group_key(row, "allocation_reason"), summary_contact_id(row)} end)
        |> grouped_contact_ids()
    end
  end

  def invalid_contact_input_ids(report) do
    case invalid_contact_input_rows(report) do
      [] ->
        report
        |> Map.get("invalid_contact_input_ids", [])
        |> List.wrap()
        |> sorted_non_empty_values()

      rows ->
        rows
        |> Enum.map(&summary_contact_id/1)
        |> sorted_non_empty_values()
    end
  end

  def invalid_contact_input_count(report) do
    case rows_for_summary(report) do
      [] -> numeric_report_count(report, "invalid_contact_input_count")
      _rows -> length(invalid_contact_input_rows(report))
    end
  end

  def duplicate_contact_id_count(report) do
    case rows_for_summary(report) do
      [] ->
        numeric_report_count(report, "duplicate_contact_id_count")

      rows ->
        rows
        |> Enum.filter(&duplicate_contact_row?/1)
        |> Enum.map(&summary_contact_id/1)
        |> Enum.reject(&(&1 in [nil, ""]))
        |> Enum.uniq()
        |> length()
    end
  end
end
