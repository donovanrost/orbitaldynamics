defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionResolutionRecommendationReports do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionResolutionRecommendationRows

  def from_recommendations(_path, _source, [], _artifact), do: nil

  def from_recommendations(path, source, recommendations, artifact) do
    report =
      %{
        "schema_contract" => "contact_contention_resolution_report.v1",
        "model" => "preserved_contact_contention_resolution_recommendations",
        "source" => source,
        "recommendations" => recommendations,
        "recommendation_count" => length(recommendations)
      }
      |> maybe_put("provenance", Map.get(artifact, "provenance"))
      |> maybe_put("trust_boundary", result_artifact_trust_boundary(artifact))
      |> compact_map()

    {path, report}
  end

  def recommendation_from_review_or_import_row(%{} = row) do
    ContactContentionResolutionRecommendationRows.from_review_or_import_row(row)
  end

  defp result_artifact_trust_boundary(artifact) do
    artifact = stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp stringify_keys(value),
    do: ContactContentionResolutionRecommendationRows.stringify_keys(value)
end
