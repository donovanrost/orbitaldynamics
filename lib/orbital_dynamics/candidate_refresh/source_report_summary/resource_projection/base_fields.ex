defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.BaseFields do
  @moduledoc false

  alias __MODULE__.ReportCounts
  alias __MODULE__.SourceCounts
  alias __MODULE__.SourcePaths
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.InvalidInputs

  def fields(sources, reports) do
    %{
      "paths" => SourcePaths.values(sources),
      "contract" => "resource_projection_report.v1",
      "count" => length(sources)
    }
    |> Map.merge(ReportCounts.fields(reports))
    |> Map.merge(SourceCounts.fields(reports))
    |> Map.merge(InvalidInputs.fields(reports))
  end
end
