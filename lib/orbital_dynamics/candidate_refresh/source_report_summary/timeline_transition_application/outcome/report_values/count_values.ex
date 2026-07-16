defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.Outcome.ReportValues.CountValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.Outcome.ReportValues.ApplicationFallbacks

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.Outcome.ReportValues.SourceValues

  def review_required_count(report) do
    SourceValues.count(
      report,
      "review_required_count",
      &ApplicationFallbacks.review_required_count/2
    )
  end

  def preserved_source_count(report) do
    SourceValues.count(
      report,
      "preserved_source_count",
      &ApplicationFallbacks.preserved_source_count/2
    )
  end

  def recorded_replacement_count(report) do
    SourceValues.count(
      report,
      "recorded_replacement_count",
      &ApplicationFallbacks.recorded_replacement_count/2
    )
  end

  def withheld_review_count(report) do
    SourceValues.count(
      report,
      "withheld_review_count",
      &ApplicationFallbacks.withheld_review_count/2
    )
  end
end
