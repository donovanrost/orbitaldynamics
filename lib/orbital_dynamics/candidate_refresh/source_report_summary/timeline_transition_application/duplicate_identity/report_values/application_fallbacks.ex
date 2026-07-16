defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.DuplicateIdentity.ReportValues.ApplicationFallbacks do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.DuplicateIdentity.ScopeRows

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.ReportShape

  def duplicate_count(report, top_level_field) do
    ReportShape.count_matching_application(report, top_level_field, &ScopeRows.duplicate?/1)
  end

  def duplicate_source_count(report, top_level_field) do
    ReportShape.count_matching_application(
      report,
      top_level_field,
      &ScopeRows.duplicate_scope?(&1, "source")
    )
  end

  def duplicate_replacement_count(report, top_level_field) do
    ReportShape.count_matching_application(
      report,
      top_level_field,
      &ScopeRows.duplicate_scope?(&1, "replacement")
    )
  end

  def scope_counts(report, top_level_field) do
    case ReportShape.application_rows(report) do
      [] -> Map.get(report, top_level_field)
      rows -> ScopeRows.counts(rows)
    end
  end
end
