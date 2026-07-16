defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.DuplicateIdentity.ReportValues do
  @moduledoc false

  alias __MODULE__.ApplicationFallbacks
  alias __MODULE__.SourceValues

  @duplicate_scope_counts_field "duplicate_timeline_identity_scope_counts"

  def duplicate_timeline_identity_count(report) do
    SourceValues.count(
      report,
      "duplicate_timeline_identity_count",
      &ApplicationFallbacks.duplicate_count/2
    )
  end

  def duplicate_source_timeline_identity_count(report) do
    SourceValues.count(
      report,
      "duplicate_source_timeline_identity_count",
      &ApplicationFallbacks.duplicate_source_count/2
    )
  end

  def duplicate_replacement_timeline_identity_count(report) do
    SourceValues.count(
      report,
      "duplicate_replacement_timeline_identity_count",
      &ApplicationFallbacks.duplicate_replacement_count/2
    )
  end

  def duplicate_identity_scope_counts(report) do
    SourceValues.map(report, @duplicate_scope_counts_field, &ApplicationFallbacks.scope_counts/2)
  end
end
