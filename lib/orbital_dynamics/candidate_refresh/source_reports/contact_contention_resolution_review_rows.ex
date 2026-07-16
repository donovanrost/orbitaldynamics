defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionResolutionReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionResolutionRecommendationReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionResolutionRecommendationRows

  def operator_review_recommendations(%{} = package) do
    package
    |> Map.get("rows", [])
    |> recommendations_from(&operator_review_row?/1)
  end

  def cadence_import_recommendations(%{} = manifest) do
    manifest
    |> Map.get("rows", [])
    |> recommendations_from(&cadence_import_row?/1)
  end

  defp recommendations_from(rows, predicate) do
    rows
    |> Enum.map(&ContactContentionResolutionRecommendationRows.stringify_keys/1)
    |> Enum.filter(predicate)
    |> Enum.map(
      &ContactContentionResolutionRecommendationReports.recommendation_from_review_or_import_row/1
    )
    |> Enum.reject(&is_nil/1)
  end

  defp operator_review_row?(row), do: row["review_type"] == "contact_contention_recommendation"

  defp cadence_import_row?(row) do
    row["source_review_type"] == "contact_contention_recommendation" or
      row["import_action"] == "review_contact_contention_resolution"
  end
end
