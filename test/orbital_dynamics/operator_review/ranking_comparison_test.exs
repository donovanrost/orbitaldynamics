defmodule OrbitalDynamics.OperatorReview.RankingComparisonTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "ranking comparison report source ids fall back through defaults" do
    assert %{"source_artifact_id" => "ranking-comparison:report"} =
             OperatorReview.from_ranking_comparison_report(%{
               id: :"ranking-comparison:report"
             })

    assert %{"source_artifact_id" => "ranking-comparison:source"} =
             OperatorReview.from_ranking_comparison_report(%{
               source: :"ranking-comparison:source"
             })

    assert %{"source_artifact_id" => "ranking_comparison_report"} =
             OperatorReview.from_ranking_comparison_report(%{})
  end

  test "builds review package from standalone ranking comparison report rows" do
    report = %{
      "schema_contract" => "ranking_comparison_report.v1",
      "model" => "deterministic_pairwise_ranked_scenario_comparison",
      "source" => "optimizer.compare_rankings",
      "objective" => "expected_score",
      "objective_direction" => "maximize",
      "left_label" => "baseline",
      "right_label" => "repair",
      "left_count" => 2,
      "right_count" => 2,
      "matched_count" => 2,
      "left_only_count" => 0,
      "right_only_count" => 0,
      "row_count" => 2,
      "winner_changed" => true,
      "winner" => %{
        "left_scenario_id" => "burn_a",
        "right_scenario_id" => "burn_b",
        "changed" => true
      },
      "rows" => [
        %{
          "scenario_id" => "burn_a",
          "status" => "matched",
          "left_rank" => 1,
          "right_rank" => 2,
          "rank_delta" => -1,
          "left_value" => 92.0,
          "right_value" => 89.0,
          "value_delta" => -3.0
        },
        %{
          "scenario_id" => "burn_b",
          "status" => "matched",
          "left_rank" => 2,
          "right_rank" => 1,
          "rank_delta" => 1,
          "left_value" => 84.0,
          "right_value" => 99.0,
          "value_delta" => 15.0
        }
      ],
      "assumptions" => %{"rank_delta" => "left_rank_minus_right_rank"}
    }

    package = OperatorReview.from_ranking_comparison_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "ranking_comparison_report.v1",
             "source_artifact_id" => "optimizer.compare_rankings",
             "review_count" => 2,
             "ranking_comparison_count" => 2,
             "tradeoff_count" => 0
           } = package

    row = Enum.find(package["rows"], &(&1["scenario_id"] == "burn_b"))

    assert %{
             "review_type" => "ranking_comparison_review",
             "source" => "ranking_comparison_report.rows",
             "subject_id" => "burn_b",
             "scenario_id" => "burn_b",
             "required_operator_action" => "review_ranking_comparison",
             "approval_status" => "operator_review_required",
             "status" => "matched",
             "left_rank" => 2,
             "right_rank" => 1,
             "rank_delta" => 1,
             "left_value" => 84.0,
             "right_value" => 99.0,
             "value_delta" => 15.0,
             "source_ranking_comparison" => %{"scenario_id" => "burn_b"}
           } = row

    assert row["reason"] ==
             "review ranking comparison for burn_b: matched, rank delta 1, value delta 15.0"

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_evidence =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"scenario_id" => "burn_b", "source_ranking_comparison" => %{}} = row ->
            put_in(row, ["source_ranking_comparison", "value_delta"], 12.0)

          row ->
            row
        end)
      end)

    assert {:error, stale_source_report} = Schema.validate_artifact(stale_source_evidence)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.value_delta$/ and
                 &1["message"] == "must match source_ranking_comparison.value_delta")
           )
  end
end
