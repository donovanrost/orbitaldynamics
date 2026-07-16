defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.TrustBoundaries.ReportBoundaryValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.TrustBoundaries.NormalizedValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.TrustBoundaries.ReportValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.TrustBoundaries.RowValues

  def values(report) do
    report
    |> RowValues.values()
    |> Kernel.++(ReportValues.values(report))
    |> NormalizedValues.sorted_unique()
  end
end
