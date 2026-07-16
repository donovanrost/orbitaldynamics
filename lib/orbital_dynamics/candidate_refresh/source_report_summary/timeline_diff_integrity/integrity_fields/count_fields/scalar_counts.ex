defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.CountFields.ScalarCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2,
      source_rows: 1
    ]

  def row_count(report) do
    from_rows_or_fallback(
      report,
      fn -> numeric_report_count(report, "row_count") end,
      &length/1
    )
  end

  def review_count(report) do
    from_rows_or_fallback(
      report,
      fn -> numeric_report_count(report, "timeline_integrity_review_count") end,
      fn rows -> Enum.count(rows, &review_required?/1) end
    )
  end

  defp review_required?(row) do
    NormalizedToken.value(Map.get(row, "timeline_integrity_status")) == "review_required" or
      Map.get(row, "required_operator_action") not in [nil, "", "none"]
  end

  defp from_rows_or_fallback(report, fallback_fun, rows_fun) do
    case source_rows(report) do
      [] -> fallback_fun.()
      rows -> rows_fun.(rows)
    end
  end
end
