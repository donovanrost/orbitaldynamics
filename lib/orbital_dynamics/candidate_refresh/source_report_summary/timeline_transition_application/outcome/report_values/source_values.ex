defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.Outcome.ReportValues.SourceValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.ReportShape

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.Outcome.ReportValues.ApplicationFallbacks

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [numeric_report_count: 2]

  def count(report, top_level_field, fallback) do
    case ReportShape.summary_source?(report) do
      true -> numeric_report_count(report, top_level_field)
      false -> fallback.(report, top_level_field)
    end
  end

  def map(report, top_level_field, row_field) do
    case ReportShape.summary_source?(report) do
      true -> Map.get(report, top_level_field)
      false -> ApplicationFallbacks.count_rows(report, top_level_field, row_field)
    end
  end
end
