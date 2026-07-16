defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.TrustBoundaries.ReportValues do
  @moduledoc false

  def values(report) do
    [
      Map.get(report, "trust_boundary"),
      get_in(report, ["provenance", "trust_boundary"])
    ]
  end
end
