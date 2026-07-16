defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.RawInputSummary.SourceMetrics.SourceMetadata.TrustBoundaryFields do
  @moduledoc false

  def fields(intents) do
    trust_boundaries = trust_boundaries(intents)

    %{
      "trust_boundary_status" => trust_boundary_status(trust_boundaries),
      "trust_boundaries" => trust_boundaries
    }
  end

  defp trust_boundary_status([]), do: "missing"
  defp trust_boundary_status(_trust_boundaries), do: "declared"

  defp trust_boundaries(intents) when is_list(intents) do
    intents
    |> Enum.map(&trust_boundary/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp trust_boundary(intent) do
    Map.get(intent, "trust_boundary") ||
      get_in(intent, ["provenance", "trust_boundary"]) ||
      get_in(intent, ["metadata", "trust_boundary"])
  end
end
