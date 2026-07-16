defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.BaseFields.InputSummaries.AggregateValues do
  @moduledoc false

  alias __MODULE__.CountValues
  alias __MODULE__.StringListValues
  alias __MODULE__.TrustBoundaryStatus

  def count(summaries, field) do
    CountValues.count(summaries, field)
  end

  def count_map(summaries, field) do
    CountValues.count_map(summaries, field)
  end

  def paths(summaries) do
    StringListValues.values(summaries, "paths")
  end

  def string_list(summaries, field) do
    StringListValues.values(summaries, field)
  end

  def merged_trust_boundary_status(summaries) do
    TrustBoundaryStatus.merged(summaries)
  end
end
