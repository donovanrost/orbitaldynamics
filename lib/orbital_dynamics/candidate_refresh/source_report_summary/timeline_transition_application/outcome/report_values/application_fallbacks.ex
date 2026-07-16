defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.Outcome.ReportValues.ApplicationFallbacks do
  @moduledoc false

  alias __MODULE__.ApplicationPredicates
  alias __MODULE__.FallbackCounts

  def review_required_count(report, top_level_field) do
    FallbackCounts.matching_application_count(
      report,
      top_level_field,
      &ApplicationPredicates.review_required?/1
    )
  end

  def preserved_source_count(report, top_level_field) do
    FallbackCounts.matching_application_count(
      report,
      top_level_field,
      &ApplicationPredicates.preserved_source?/1
    )
  end

  def recorded_replacement_count(report, top_level_field) do
    FallbackCounts.matching_application_count(
      report,
      top_level_field,
      &ApplicationPredicates.recorded_replacement?/1
    )
  end

  def withheld_review_count(report, top_level_field) do
    FallbackCounts.matching_application_count(
      report,
      top_level_field,
      &ApplicationPredicates.withheld_review?/1
    )
  end

  def count_rows(report, top_level_field, row_field) do
    FallbackCounts.row_field_counts(report, top_level_field, row_field)
  end
end
