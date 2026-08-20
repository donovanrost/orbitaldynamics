defmodule OrbitalDynamics.CadenceImport.StrategyArtifactImport do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.StrategyRecommendationEligibility

  alias OrbitalDynamics.CadenceImport.{
    JsonNormalization,
    ReviewSummaryContext,
    StrategyReview
  }

  def build(artifact, opts, callbacks) do
    artifact = JsonNormalization.stringify_keys(artifact)

    source_id =
      Keyword.get(
        opts,
        :source_artifact_id,
        get_in(artifact, ["strategy_metadata", "strategy_id"])
      )

    recommendation =
      artifact
      |> Map.get("recommendation", %{})
      |> StrategyRecommendationEligibility.normalize_recommendation_json_values()

    comparison_rows = get_in(artifact, ["branch_comparison_report", "rows"]) || []

    review_package = StrategyReview.package(artifact)

    feedback_context =
      callback(callbacks, :feedback_context).(artifact["operational_feedback_provenance"])

    rows =
      comparison_rows
      |> Enum.map(fn row ->
        row
        |> JsonNormalization.stringify_keys()
        |> StrategyRecommendationEligibility.normalize_comparison_row_json_values()
      end)
      |> Enum.sort_by(&{Map.get(&1, "rank", 0), Map.get(&1, "branch_id", "")})
      |> Enum.with_index(1)
      |> Enum.map(fn {row, rank} ->
        callback(callbacks, :strategy_row).(row, recommendation, rank, feedback_context)
      end)

    review_rows =
      StrategyReview.manifest_rows(
        review_package,
        length(rows) + 1,
        callback(callbacks, :review_row)
      )

    summary_context = ReviewSummaryContext.build(review_package)

    callback(callbacks, :build_manifest).(
      rows ++ review_rows,
      %{
        "source" => "OrbitalDynamics.CadenceImport.from_strategy_artifact",
        "source_artifact_type" => "campaign_strategy.v3",
        "source_artifact_id" => source_id,
        "source_plan_id" => artifact["source_plan_id"],
        "source_repair_id" => artifact["source_repair_id"],
        "recommended_branch_id" => recommendation["recommended_branch_id"],
        "source_branch_count" => length(comparison_rows),
        "source_review_count" => StrategyReview.count(review_package),
        "eligibility_status" => recommendation["eligibility_status"],
        "authority_context" => recommendation["authority_context"],
        "authority_context_evaluation" => recommendation["authority_context_evaluation"],
        "operator_review_package_source" =>
          if(Map.has_key?(artifact, "operator_review_package"), do: "embedded", else: "derived")
      }
      |> Map.merge(summary_context),
      %{
        "source_artifact_type" => "campaign_strategy.v3",
        "source_artifact_id" => source_id,
        "eligibility_status" => recommendation["eligibility_status"],
        "authority_context" => recommendation["authority_context"],
        "authority_context_evaluation" => recommendation["authority_context_evaluation"],
        "row_source" =>
          "campaign_strategy.branch_comparison_report.rows_and_operator_review_package.rows",
        "deterministic_ordering" => "branch_comparison_rank_then_branch_id"
      }
      |> Map.merge(summary_context)
    )
  end

  defp callback(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
