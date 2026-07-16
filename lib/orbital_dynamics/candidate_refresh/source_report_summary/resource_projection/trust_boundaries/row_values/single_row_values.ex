defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.TrustBoundaries.RowValues.SingleRowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.TrustBoundaries.RowValues.DirectValues

  def values(row) do
    row = EncodedValue.stringify_keys(row)

    [
      DirectValues.trust_boundary(row),
      row["source_trust_boundary"],
      get_in(row, ["source_resource_summary", "trust_boundary"]),
      get_in(row, ["source_resource_summary", "provenance", "trust_boundary"]),
      get_in(row, ["source_resource_projection", "resource_trust_boundary"]),
      get_in(row, ["source_resource_projection", "provenance", "trust_boundary"])
    ]
  end
end
