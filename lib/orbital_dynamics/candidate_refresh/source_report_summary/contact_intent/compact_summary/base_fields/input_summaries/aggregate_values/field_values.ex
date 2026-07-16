defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.BaseFields.InputSummaries.AggregateValues.FieldValues do
  @moduledoc false

  def values(summaries, field) do
    Enum.map(summaries, &Map.get(&1, field))
  end
end
