defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance.CountFields.CompactCounts do
  @moduledoc false

  alias __MODULE__.ResolvedCounts

  def summary_count(summary, field) do
    ResolvedCounts.summary_count(summary, field)
  end

  def status_count(summary, status) do
    ResolvedCounts.status_count(summary, status)
  end

  def validation_level_count(summary, validation_level) do
    ResolvedCounts.validation_level_count(summary, validation_level)
  end

  def validation_level_counts(summary) do
    ResolvedCounts.validation_level_counts(summary)
  end
end
