defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.SourceFields.SourceMetadata.TrustBoundaries do
  @moduledoc false

  alias __MODULE__.ReportValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [normalize_trust_boundaries: 1]

  def fields(reports) do
    trust_boundaries = trust_boundaries(reports)

    %{
      "trust_boundary_status" => trust_boundary_status(trust_boundaries),
      "trust_boundaries" => trust_boundaries
    }
  end

  defp trust_boundaries(reports) when is_list(reports) do
    reports
    |> Enum.flat_map(&ReportValues.trust_boundaries/1)
    |> normalize_trust_boundaries()
  end

  defp trust_boundary_status([]), do: "missing"
  defp trust_boundary_status(_trust_boundaries), do: "declared"
end
