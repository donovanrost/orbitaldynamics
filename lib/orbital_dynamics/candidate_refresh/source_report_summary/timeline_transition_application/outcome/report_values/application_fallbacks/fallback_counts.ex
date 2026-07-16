defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.Outcome.ReportValues.ApplicationFallbacks.FallbackCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.ReportShape

  def matching_application_count(report, top_level_field, row_predicate) do
    ReportShape.count_matching_application(report, top_level_field, row_predicate)
  end

  def row_field_counts(report, top_level_field, row_field) do
    case ReportShape.application_rows(report) do
      [] -> Map.get(report, top_level_field)
      rows -> ReportShape.count_rows(rows, row_field)
    end
  end
end
