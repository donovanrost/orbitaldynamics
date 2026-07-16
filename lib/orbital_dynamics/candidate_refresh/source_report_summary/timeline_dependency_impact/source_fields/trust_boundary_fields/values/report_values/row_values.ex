defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.SourceFields.TrustBoundaryFields.Values.ReportValues.RowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.Rows

  def values(row) do
    row = Rows.stringify(row)

    [
      row["source_trust_boundary"],
      row["trust_boundary"],
      get_in(row, ["source_timeline_dependency_impact", "trust_boundary"]),
      get_in(row, ["source_timeline_dependency_impact", "provenance", "trust_boundary"])
    ]
  end
end
