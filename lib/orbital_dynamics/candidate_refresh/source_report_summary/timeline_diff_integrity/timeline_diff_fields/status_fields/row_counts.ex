defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.StatusFields.RowCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.RowFieldCounts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1, source_rows: 1]

  def merge(reports, field) do
    reports
    |> Enum.map(&report_counts(&1, field))
    |> merge_count_maps()
  end

  def source(report, fallback_field, row_field) do
    counts_from_rows_or_fallback(report, fallback_field, fn rows ->
      row_counts(rows, row_field)
    end)
  end

  defp counts_from_rows_or_fallback(report, fallback_field, row_fun) do
    case source_rows(report) do
      [] -> Map.get(report, fallback_field)
      rows -> row_fun.(rows)
    end
  end

  defp report_counts(report, field) do
    report
    |> source_rows()
    |> row_counts(field)
  end

  defp row_counts(rows, field) do
    RowFieldCounts.counts(rows, field)
  end
end
