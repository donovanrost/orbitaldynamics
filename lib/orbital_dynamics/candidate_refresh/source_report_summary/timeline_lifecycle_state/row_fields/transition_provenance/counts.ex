defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields.TransitionProvenance.Counts do
  @moduledoc false

  alias __MODULE__.CountValues

  def total(summaries) do
    CountValues.total(summaries)
  end

  def field_counts(summaries, field) do
    CountValues.field_counts(summaries, field)
  end
end
