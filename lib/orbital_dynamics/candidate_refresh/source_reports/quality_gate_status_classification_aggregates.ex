defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateStatusClassificationAggregates do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateStatusClassification
  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateStatusCollections

  def classification_counts(%{} = row_ids_by_status) do
    row_ids_by_status
    |> Enum.reduce(%{}, fn {status, ids}, acc ->
      count =
        ids
        |> QualityGateStatusCollections.list_value()
        |> length()

      classification = QualityGateStatusClassification.import_classification(status)

      if count > 0, do: Map.update(acc, classification, count, &(&1 + count)), else: acc
    end)
  end

  def classification_counts(_row_ids_by_status), do: %{}

  def ids_by_classification(%{} = ids_by_status, _fallback) do
    Enum.reduce(ids_by_status, %{}, fn {status, ids}, acc ->
      classification =
        status
        |> to_string()
        |> QualityGateStatusClassification.import_classification()

      normalized_ids =
        ids
        |> QualityGateStatusCollections.list_value()
        |> sorted_string_values()

      if normalized_ids == [] do
        acc
      else
        Map.update(acc, classification, normalized_ids, fn existing ->
          sorted_string_values(existing ++ normalized_ids)
        end)
      end
    end)
  end

  def ids_by_classification(_ids_by_status, %{} = fallback), do: fallback
  def ids_by_classification(_ids_by_status, _fallback), do: %{}
end
