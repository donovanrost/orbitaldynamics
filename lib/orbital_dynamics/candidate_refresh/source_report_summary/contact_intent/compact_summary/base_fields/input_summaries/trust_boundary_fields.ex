defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.BaseFields.InputSummaries.TrustBoundaryFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.BaseFields.InputSummaries.AggregateValues

  def fields(summaries) do
    %{
      "trust_boundary_status" => AggregateValues.merged_trust_boundary_status(summaries),
      "trust_boundaries" => AggregateValues.string_list(summaries, "trust_boundaries")
    }
  end
end
