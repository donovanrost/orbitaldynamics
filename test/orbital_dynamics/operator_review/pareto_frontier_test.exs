defmodule OrbitalDynamics.OperatorReview.ParetoFrontierTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "Pareto frontier report source ids fall back through defaults" do
    assert %{"source_artifact_id" => "pareto-frontier:report"} =
             OperatorReview.from_pareto_frontier_report(%{
               id: :"pareto-frontier:report"
             })

    assert %{"source_artifact_id" => "pareto-frontier:source"} =
             OperatorReview.from_pareto_frontier_report(%{
               source: :"pareto-frontier:source"
             })

    assert %{"source_artifact_id" => "pareto_frontier_report"} =
             OperatorReview.from_pareto_frontier_report(%{})
  end

  test "builds review package from standalone Pareto frontier report rows" do
    report = %{
      "schema_contract" => "pareto_frontier_report.v1",
      "model" => "objective_vector_pareto_frontier",
      "source" => "campaign_strategy.branch_comparison_report",
      "alternative_count" => 2,
      "objective_count" => 2,
      "frontier_count" => 1,
      "dominated_count" => 1,
      "frontier_ids" => ["baseline"],
      "dominated_ids" => ["risky"],
      "objective_directions" => %{"score" => "maximize", "risk_count" => "minimize"},
      "rows" => [
        %{
          "id" => "baseline",
          "scenario_id" => "baseline",
          "objective_values" => %{"score" => 95.0, "risk_count" => 0},
          "objective_keys" => ["risk_count", "score"],
          "frontier" => true,
          "dominated_by_ids" => [],
          "dominates_ids" => ["risky"]
        },
        %{
          "id" => "risky",
          "scenario_id" => "risky",
          "objective_values" => %{"score" => 80.0, "risk_count" => 1},
          "objective_keys" => ["risk_count", "score"],
          "frontier" => false,
          "dominated_by_ids" => ["baseline"],
          "dominates_ids" => []
        }
      ],
      "assumptions" => %{"external_solver" => false}
    }

    package = OperatorReview.from_pareto_frontier_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "pareto_frontier_report.v1",
             "source_artifact_id" => "campaign_strategy.branch_comparison_report",
             "review_count" => 2,
             "pareto_frontier_count" => 2
           } = package

    assert %{
             "review_type" => "pareto_frontier_review",
             "source" => "pareto_frontier_report.rows",
             "subject_id" => "risky",
             "scenario_id" => "risky",
             "branch_id" => "risky",
             "required_operator_action" => "review_pareto_frontier",
             "frontier" => false,
             "dominated_by_ids" => ["baseline"],
             "source_pareto_frontier" => %{"scenario_id" => "risky"}
           } = Enum.find(package["rows"], &(&1["scenario_id"] == "risky"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_evidence =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"scenario_id" => "risky", "source_pareto_frontier" => %{}} = row ->
            put_in(row, ["source_pareto_frontier", "dominated_by_ids"], [])

          row ->
            row
        end)
      end)

    assert {:error, stale_source_report} = Schema.validate_artifact(stale_source_evidence)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.dominated_by_ids$/ and
                 &1["message"] == "must match source_pareto_frontier.dominated_by_ids")
           )
  end
end
