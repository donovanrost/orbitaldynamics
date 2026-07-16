defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.BaseFields.SourceMetadata.TrustBoundaryFields.TrustBoundaries do
  @moduledoc false

  def values(intents) when is_list(intents) do
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
