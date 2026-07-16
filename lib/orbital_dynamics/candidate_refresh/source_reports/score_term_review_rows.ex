defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ScoreTermReviewRows do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ScoreTermCollectionArtifactEncoding

  def row_from_review_or_import_row(%{} = row) do
    embedded =
      cond do
        is_map(row["source_score_term"]) ->
          row["source_score_term"]

        is_map(get_in(row, ["source_review_row", "source_score_term"])) ->
          get_in(row, ["source_review_row", "source_score_term"])

        true ->
          %{}
      end

    embedded =
      case embedded do
        %{} = score_term -> stringify_keys(score_term)
        _score_term -> %{}
      end

    row
    |> Map.drop(["source_review_row"])
    |> Map.merge(embedded)
    |> Map.put_new("id", row["term_id"] || row["subject_id"] || row["id"])
    |> Map.put_new("term_key", row["term_key"] || row["score_term_key"])
    |> Map.put_new("value", row["value"] || row["score_term_value"])
    |> compact_map()
    |> case do
      score_term_row when is_map(score_term_row) ->
        if score_term_key(score_term_row) not in [nil, ""], do: score_term_row

      _score_term_row ->
        nil
    end
  end

  def score_term_key(row) do
    row["term_key"] ||
      row["score_term_key"] ||
      row["metric"] ||
      row["name"] ||
      row["key"]
  end

  def stringify_keys(value), do: ScoreTermCollectionArtifactEncoding.stringify_keys(value)
end
