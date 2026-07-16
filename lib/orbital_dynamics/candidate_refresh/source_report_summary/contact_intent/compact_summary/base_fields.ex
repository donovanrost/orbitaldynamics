defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.BaseFields do
  @moduledoc false

  alias __MODULE__.CompactSourceFields
  alias __MODULE__.InputSummaries
  alias __MODULE__.SourceMetadata

  def from_compact_sources(sources, summaries) do
    CompactSourceFields.fields(sources, summaries)
    |> Map.merge(SourceMetadata.trust_boundary_fields(summaries))
  end

  def from_input_summaries(summaries) do
    summaries
    |> InputSummaries.fields()
    |> Map.put("contract", SourceMetadata.contract(summaries))
  end
end
