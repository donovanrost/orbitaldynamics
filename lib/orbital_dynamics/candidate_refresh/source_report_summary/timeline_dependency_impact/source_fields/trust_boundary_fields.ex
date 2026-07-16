defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.SourceFields.TrustBoundaryFields do
  @moduledoc false

  alias __MODULE__.Values

  def fields(reports) do
    trust_boundaries = Values.from_reports(reports)

    %{
      "trust_boundary_status" => status(trust_boundaries),
      "trust_boundaries" => trust_boundaries
    }
  end

  defp status([]), do: "missing"
  defp status(_trust_boundaries), do: "declared"
end
