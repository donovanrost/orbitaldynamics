defmodule OrbitalDynamics.CampaignPlanner.ScoreTermReviewRows do
  @moduledoc false

  def source(%{"source_score_term" => %{} = source}) when map_size(source) > 0,
    do: {source, "source_score_term"}

  def source(row), do: {row, "score_term_review"}

  def review_row?(row) do
    (row["source_review_type"] == "score_term_review" or
       row["review_type"] == "score_term_review" or
       row["import_action"] == "review_score_term") and row["term_key"] not in [nil, ""]
  end
end
