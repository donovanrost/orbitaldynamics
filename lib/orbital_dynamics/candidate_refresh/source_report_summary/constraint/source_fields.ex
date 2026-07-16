defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.SourceFields do
  @moduledoc false

  alias __MODULE__.TrustBoundaries

  def fields(sources, reports) do
    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "constraint_report.v1",
      "count" => length(sources),
      "trust_boundary_status" => TrustBoundaries.status(reports),
      "trust_boundaries" => TrustBoundaries.values(reports)
    }
  end
end
