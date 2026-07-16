defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.DirectionFields do
  @moduledoc false

  alias __MODULE__.Aggregates
  alias __MODULE__.RoutingFields

  def from_compact_summaries(summaries) do
    RoutingFields.fields(summaries, Aggregates.from_compact_summaries(summaries))
  end

  def from_input_summaries(summaries) do
    RoutingFields.fields(summaries, Aggregates.from_input_summaries(summaries))
  end
end
