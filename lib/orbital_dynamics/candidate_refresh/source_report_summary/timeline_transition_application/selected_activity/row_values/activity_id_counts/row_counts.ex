defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity.RowValues.ActivityIdCounts.RowCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.ReportShape

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def values(report, fallback_field, row_values) do
    case ReportShape.application_rows(report) do
      [] ->
        Map.get(report, fallback_field)

      rows ->
        rows
        |> row_values.()
        |> count_source_report_values()
    end
  end

  def summary_source_value(report, extractor) do
    extractor.(report, ReportShape.summary_source?(report))
  end
end
