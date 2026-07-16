defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.BaseFields.InputSummaries do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.TrustBoundaryFields

  def fields(summaries) do
    summaries
    |> CountFields.fields()
    |> Map.merge(TrustBoundaryFields.fields(summaries))
  end
end
