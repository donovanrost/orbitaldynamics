defmodule OrbitalDynamics.CadenceImport.StrategyReview do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.StrategyRecommendationEligibility
  alias OrbitalDynamics.CadenceImport.{JsonNormalization, ReviewTypePolicy}
  alias OrbitalDynamics.OperatorReview

  def manifest_rows(review_package, starting_rank, dispatch) do
    review_package
    |> Map.get("rows", [])
    |> Enum.map(fn row ->
      row
      |> JsonNormalization.stringify_keys()
      |> StrategyRecommendationEligibility.normalize_review_row_json_values()
    end)
    |> Enum.filter(&ReviewTypePolicy.strategy_manifest?/1)
    |> Enum.with_index(starting_rank)
    |> Enum.map(fn {row, rank} -> dispatch.(row, rank) end)
  end

  def package(artifact) do
    Map.get(artifact, "operator_review_package") ||
      OperatorReview.from_strategy_artifact(artifact)
  end

  def count(review_package) do
    Map.get(review_package, "review_count") ||
      length(Map.get(review_package, "rows", []))
  end
end
