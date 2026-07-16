defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.BaseFields.InputSummaries.AggregateValues.CountValues do
  @moduledoc false

  alias __MODULE__.MapCounts
  alias __MODULE__.ScalarCounts

  defdelegate count(summaries, field), to: ScalarCounts
  defdelegate count_map(summaries, field), to: MapCounts
end
