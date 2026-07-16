defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.SummaryFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.{
    BaseFields,
    CapacityFields,
    DirectionFields
  }

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def from_compact_sources(sources, summaries) do
    BaseFields.from_compact_sources(sources, summaries)
    |> Map.merge(CapacityFields.from_compact_summaries(summaries))
    |> Map.merge(DirectionFields.from_compact_summaries(summaries))
    |> compact_map()
  end

  def from_input_summaries(summaries) do
    BaseFields.from_input_summaries(summaries)
    |> Map.merge(CapacityFields.from_input_summaries(summaries))
    |> Map.merge(DirectionFields.from_input_summaries(summaries))
    |> compact_map()
  end
end
