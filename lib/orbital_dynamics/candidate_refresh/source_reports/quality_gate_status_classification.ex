defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateStatusClassification do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateStatusClassificationAggregates
  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateStatusCollections

  def status_from_row_ids(%{} = row_ids_by_status, _fallback) do
    cond do
      QualityGateStatusCollections.list_values(row_ids_by_status, "blocked") != [] ->
        "blocked"

      QualityGateStatusCollections.list_values(row_ids_by_status, "analysis_only") != [] ->
        "analysis_only"

      QualityGateStatusCollections.list_values(row_ids_by_status, "review_required") != [] ->
        "review_required"

      true ->
        "passed"
    end
  end

  def status_from_row_ids(_row_ids_by_status, fallback), do: fallback

  def import_classification("blocked"), do: "blocked"
  def import_classification("analysis_only"), do: "analysis_only"
  def import_classification("review_required"), do: "review_only"
  def import_classification(_status), do: "importable"

  def readiness_level("blocked"), do: "blocked"
  def readiness_level("analysis_only"), do: "analysis_only"
  def readiness_level("review_only"), do: "operator_review"
  def readiness_level(_classification), do: "import_eligible"

  defdelegate classification_counts(row_ids_by_status),
    to: QualityGateStatusClassificationAggregates

  defdelegate ids_by_classification(ids_by_status, fallback),
    to: QualityGateStatusClassificationAggregates
end
