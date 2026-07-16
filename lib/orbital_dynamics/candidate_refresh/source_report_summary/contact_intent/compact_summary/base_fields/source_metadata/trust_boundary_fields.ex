defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.BaseFields.SourceMetadata.TrustBoundaryFields do
  @moduledoc false

  alias __MODULE__.TrustBoundaries

  def trust_boundary_fields(summaries) do
    trust_boundaries = TrustBoundaries.values(summaries)

    %{
      "trust_boundary_status" => trust_boundary_status(trust_boundaries),
      "trust_boundaries" => trust_boundaries
    }
  end

  defp trust_boundary_status([]), do: "missing"
  defp trust_boundary_status(_trust_boundaries), do: "declared"
end
