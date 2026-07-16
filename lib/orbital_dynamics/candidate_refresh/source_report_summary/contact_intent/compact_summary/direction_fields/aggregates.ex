defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.DirectionFields.Aggregates do
  @moduledoc false

  alias __MODULE__.DirectionValues
  alias __MODULE__.MapValues

  def from_compact_summaries(summaries) do
    summaries
    |> DirectionValues.from_compact_summaries()
    |> Map.merge(MapValues.from_compact_summaries(summaries))
  end

  def from_input_summaries(summaries) do
    summaries
    |> DirectionValues.from_input_summaries()
    |> Map.merge(MapValues.from_input_summaries(summaries))
  end
end
