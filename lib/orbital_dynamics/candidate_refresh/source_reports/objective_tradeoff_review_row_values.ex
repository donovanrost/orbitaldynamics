defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveTradeoffReviewRowValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveTradeoffReviewRowEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveTradeoffReviewRowSources

  def row_from_review_or_import_row(%{} = row) do
    row
    |> Map.drop(["source_review_row"])
    |> Map.merge(ObjectiveTradeoffReviewRowSources.embedded_tradeoff(row))
    |> Map.put_new("id", row["tradeoff_id"] || row["subject_id"] || row["id"])
    |> Map.put_new("scenario_id", row["scenario_id"])
    |> Map.put_new("score", row["score"])
    |> Map.put_new("score_delta_from_selected", row["score_delta_from_selected"])
    |> Map.put_new("score_terms", row["score_terms"])
    |> compact_map()
  end

  def score_term_keys(rows) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> Map.get("score_terms", %{})
      |> case do
        %{} = score_terms -> Map.keys(score_terms)
        _score_terms -> []
      end
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def stringify_keys(value), do: ObjectiveTradeoffReviewRowEncoding.stringify_keys(value)
end
