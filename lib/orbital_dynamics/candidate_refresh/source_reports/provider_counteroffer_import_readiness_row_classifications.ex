defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowClassifications do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_values: 1,
      sorted_string_values: 1
    ]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowNormalization,
    as: RowNormalization

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowStatus,
    as: RowStatus

  def review_ids_from_rows(rows) do
    rows
    |> Enum.filter(&RowStatus.review_required?/1)
    |> Enum.map(&Map.get(&1, "provider_counteroffer_id"))
    |> sorted_string_values()
  end

  def no_import_required_ids_from_rows(rows) do
    rows
    |> Enum.filter(&RowStatus.import_ready?/1)
    |> Enum.map(&Map.get(&1, "provider_counteroffer_id"))
    |> sorted_string_values()
  end

  def import_readiness_status_counts_from_rows(rows) do
    rows
    |> Enum.map(&RowStatus.import_readiness_status/1)
    |> count_values()
  end

  def import_classification_counts_from_rows(rows) do
    rows
    |> Enum.map(&RowStatus.import_classification/1)
    |> count_values()
  end

  def normalized_token(value), do: RowNormalization.normalized_token(value)
end
