defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.SourceFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.CountFields
  alias __MODULE__.TrustBoundaryFields

  def fields(sources, reports) do
    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "timeline_dependency_impact_summary.v1",
      "count" => length(sources),
      "row_count" => CountFields.row_count(reports)
    }
    |> Map.merge(TrustBoundaryFields.fields(reports))
  end
end
