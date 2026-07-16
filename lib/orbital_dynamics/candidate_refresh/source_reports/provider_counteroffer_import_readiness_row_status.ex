defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowStatus do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowClassifications,
    as: RowClassifications

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowPredicates,
    as: RowPredicates

  def import_readiness_status(row) do
    case normalized_token(Map.get(row, "import_readiness_status")) do
      status when status not in [nil, ""] ->
        status

      _blank ->
        cond do
          review_required?(row) -> "review_required"
          import_ready?(row) -> "import_ready"
          true -> nil
        end
    end
  end

  def import_classification(row) do
    case normalized_token(Map.get(row, "import_classification")) do
      classification when classification not in [nil, ""] ->
        classification

      _blank ->
        cond do
          review_required?(row) -> "review_only"
          import_ready?(row) -> "ready"
          true -> nil
        end
    end
  end

  def review_required?(row), do: RowPredicates.review_required?(row)

  def import_ready?(row), do: RowPredicates.import_ready?(row)

  defp normalized_token(value), do: RowClassifications.normalized_token(value)
end
