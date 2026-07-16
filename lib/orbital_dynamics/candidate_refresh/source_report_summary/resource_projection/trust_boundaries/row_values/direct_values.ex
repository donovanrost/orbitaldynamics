defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.TrustBoundaries.RowValues.DirectValues do
  @moduledoc false

  def trust_boundary(row) do
    row["resource_trust_boundary"] ||
      row["trust_boundary"] ||
      get_in(row, ["resource_provenance", "trust_boundary"]) ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end
end
