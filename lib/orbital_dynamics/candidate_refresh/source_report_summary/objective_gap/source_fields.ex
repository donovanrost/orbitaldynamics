defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.SourceFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.TrustBoundaries

  def fields(family, contract, sources, reports) do
    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => contract,
      "count" => length(sources),
      "trust_boundary_status" => TrustBoundaries.status(family, reports),
      "trust_boundaries" => TrustBoundaries.values(family, reports)
    }
  end
end
