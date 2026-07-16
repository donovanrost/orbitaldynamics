defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.Report.SummaryFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Counts

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.Report.Rows

  import Rows,
    only: [
      effective_status: 1,
      explicit_count_map: 2,
      grouped_contact_counts: 1,
      grouped_contact_ids: 1,
      id_map_counts: 1,
      map_value_lists: 1,
      non_empty_map: 1,
      rows_for_summary: 1,
      summary_contact_id: 1,
      summary_direction: 1
    ]

  def row_count(report), do: length(Map.get(report, "rows", []))

  def blocked_row_count(report) do
    report
    |> rows_for_summary()
    |> Enum.count(
      &(effective_status(&1) in [
          "blocked",
          "policy_blocked",
          "blocked_by_policy"
        ])
    )
  end

  def deferred_row_count(report) do
    report
    |> rows_for_summary()
    |> Enum.count(&(effective_status(&1) == "deferred"))
  end

  def status_counts(report) do
    case rows_for_summary(report) do
      [] ->
        explicit_count_map(report, "allocation_status_counts")

      rows ->
        Counts.normalized_rows(rows, "allocation_status")
    end
  end

  def effective_status_counts(report) do
    case rows_for_summary(report) do
      [] ->
        explicit_count_map(report, "effective_allocation_status_counts")

      rows ->
        rows
        |> Enum.reduce(%{}, fn row, counts ->
          case effective_status(row) do
            status when status in [nil, ""] -> counts
            status -> Map.update(counts, status, 1, &(&1 + 1))
          end
        end)
        |> non_empty_map()
    end
  end

  def reason_counts(report) do
    report
    |> Map.get("rows", [])
    |> Counts.normalized_rows("allocation_reason")
  end

  def direction_counts(report) do
    case rows_for_summary(report) do
      [] ->
        report
        |> Map.get("contact_ids_by_direction")
        |> id_map_counts()

      rows ->
        rows
        |> Enum.map(fn row -> {summary_direction(row), summary_contact_id(row)} end)
        |> grouped_contact_counts()
    end
  end

  def contact_ids_by_direction(report) do
    case rows_for_summary(report) do
      [] ->
        report
        |> Map.get("contact_ids_by_direction")
        |> map_value_lists()

      rows ->
        rows
        |> Enum.map(fn row -> {summary_direction(row), summary_contact_id(row)} end)
        |> grouped_contact_ids()
    end
  end
end
