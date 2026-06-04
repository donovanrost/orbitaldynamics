defmodule OrbitalDynamics.OptimizerTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Optimizer, Schema}

  test "declares optimizer contract capabilities" do
    assert %{
             artifact_contract: "optimizer_contract.v1",
             validation_level: :artifact_contract,
             models: ["per_spacecraft_greedy_non_overlapping"],
             comparison_models: comparison_models,
             deterministic_ordering: deterministic_ordering,
             preserved_lineage_fields: preserved_lineage_fields,
             known_limits: known_limits
           } = Optimizer.capabilities()

    assert "scenario_ranking_pairwise_delta" in comparison_models
    assert "objective_vector_pareto_frontier" in comparison_models
    assert :score_descending in deterministic_ordering
    assert "source_window" in preserved_lineage_fields
    assert :no_milp_or_cp_sat_solver in known_limits
    assert :ranking_comparison_not_solver_search in known_limits
    assert :pareto_frontier_summary_not_solver_search in known_limits
  end

  test "builds deterministic greedy timeline optimizer contracts" do
    candidates = [
      %{
        "id" => "obs_1",
        "scenario_id" => "leo_1",
        "score_terms" => %{"target_value" => 10.0},
        "source_window_id" => "window_1"
      }
    ]

    timelines = [
      %{
        "scenario_id" => "leo_1",
        "score" => 10.0,
        "score_terms" => %{"target_value" => 10.0},
        "activities" => candidates
      }
    ]

    contract =
      Optimizer.greedy_timeline_contract(candidates, timelines,
        plan_id: "campaign_plan:leo",
        constraints: %{"max_timeline_activities" => 2},
        scoring_policy: %{"target_value_weight" => 1.0}
      )

    assert contract["id"] == "optimizer_contract:campaign_plan:leo"
    assert contract["candidate_count"] == 1
    assert contract["ranked_timeline_count"] == 1
    assert contract["selected_activity_ids"] == ["obs_1"]
    assert contract["candidate_activity_ids"] == ["obs_1"]
    assert contract["score_term_keys"] == ["target_value"]
    assert contract["constraints"] == %{"max_timeline_activities" => 2}
    assert contract["scoring_policy"] == %{"target_value_weight" => 1.0}

    assert {:ok, %{"schema_contract" => "optimizer_contract.v1"}} =
             Schema.validate_artifact(contract)
  end

  test "compares ranked scenario rows with deterministic rank and value deltas" do
    left = [
      %{scenario_id: "burn_a", objective: "final_radius_km", value: 7010.0},
      %{scenario_id: "burn_b", objective: "final_radius_km", value: 7005.0}
    ]

    right = [
      %{"scenario_id" => "burn_b", "objective" => "final_radius_km", "value" => 7020.0},
      %{"scenario_id" => "burn_c", "objective" => "final_radius_km", "value" => 7001.0}
    ]

    comparison =
      Optimizer.compare_rankings(left, right,
        left_label: "grid",
        right_label: "monte_carlo",
        objective_direction: "maximize"
      )

    assert comparison["model"] == "scenario_ranking_pairwise_delta"
    assert comparison["objective"] == "final_radius_km"
    assert comparison["objective_direction"] == "maximize"
    assert comparison["matched_count"] == 1
    assert comparison["left_only_count"] == 1
    assert comparison["right_only_count"] == 1

    assert comparison["winner"] == %{
             "left_scenario_id" => "burn_a",
             "right_scenario_id" => "burn_b",
             "changed" => true
           }

    assert [
             %{
               "scenario_id" => "burn_b",
               "status" => "matched",
               "left_rank" => 2,
               "right_rank" => 1,
               "rank_delta" => 1,
               "left_value" => 7005.0,
               "right_value" => 7020.0,
               "value_delta" => 15.0
             },
             %{"scenario_id" => "burn_c", "status" => "right_only"},
             %{"scenario_id" => "burn_a", "status" => "left_only"}
           ] = comparison["rows"]

    api_comparison = OrbitalDynamics.compare_scenario_rankings(left, right)

    assert get_in(api_comparison, ["winner", "changed"]) == true
  end

  test "normalizes clean numeric string ranking values" do
    left = [
      %{scenario_id: "burn_a", objective: "final_radius_km", value: "7010.0"},
      %{scenario_id: "burn_b", objective: "final_radius_km", value: "not_available"}
    ]

    right = [
      %{"scenario_id" => "burn_a", "objective" => "final_radius_km", "value" => "7011.5"},
      %{"scenario_id" => "burn_b", "objective" => "final_radius_km", "value" => "7001.0"}
    ]

    report =
      Optimizer.ranking_comparison_report(left, right,
        objective_direction: "maximize",
        source: "operator.supplied_rankings"
      )

    assert %{
             "scenario_id" => "burn_a",
             "left_value" => 7010.0,
             "right_value" => 7011.5,
             "value_delta" => 1.5
           } = Enum.find(report["rows"], &(&1["scenario_id"] == "burn_a"))

    assert %{
             "scenario_id" => "burn_b",
             "left_value" => nil,
             "right_value" => 7001.0,
             "value_delta" => nil
           } = Enum.find(report["rows"], &(&1["scenario_id"] == "burn_b"))

    assert {:ok, %{"schema_contract" => "ranking_comparison_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "builds schema-versioned ranking comparison reports" do
    report =
      Optimizer.ranking_comparison_report(
        [%{scenario_id: "burn_a", objective: "final_radius_km", value: 7010.0}],
        [%{scenario_id: "burn_b", objective: "final_radius_km", value: 7020.0}],
        source: "study_benchmark.rankings",
        objective_direction: "maximize"
      )

    assert report["schema_contract"] == "ranking_comparison_report.v1"
    assert report["source"] == "study_benchmark.rankings"
    assert report["row_count"] == 2
    assert report["winner"]["changed"] == true
    assert report["model_limits"] == Optimizer.ranking_comparison_model_limits()

    assert {:ok, %{"schema_contract" => "ranking_comparison_report.v1"}} =
             Schema.validate_artifact(report)

    api_report =
      OrbitalDynamics.ranking_comparison_report(
        [%{scenario_id: "burn_a", value: 7010.0}],
        [%{scenario_id: "burn_a", value: 7011.0}]
      )

    assert api_report["objective"] == "unspecified"
  end

  test "builds schema-versioned Pareto frontier reports for objective vectors" do
    rows = [
      %{
        scenario_id: "coverage_leader",
        objectives: %{coverage: 10.0, risk: 3.0}
      },
      %{
        scenario_id: "balanced",
        objectives: %{coverage: 8.0, risk: 1.0}
      },
      %{
        scenario_id: "dominated",
        objectives: %{coverage: 7.0, risk: 3.0}
      },
      %{
        scenario_id: "ignored_no_numeric",
        objectives: %{coverage: "unknown"}
      }
    ]

    report =
      Optimizer.pareto_frontier_report(rows,
        source: "strategy.branch_objectives",
        objective_directions: %{coverage: "maximize", risk: "minimize"}
      )

    assert report["schema_contract"] == "pareto_frontier_report.v1"
    assert report["model"] == "objective_vector_pareto_frontier"
    assert report["source"] == "strategy.branch_objectives"
    assert report["alternative_count"] == 4
    assert report["objective_count"] == 2
    assert report["frontier_ids"] == ["balanced", "coverage_leader", "ignored_no_numeric"]
    assert report["dominated_ids"] == ["dominated"]
    assert report["model_limits"] == Optimizer.pareto_frontier_model_limits()

    assert report["objective_directions"] == %{
             "coverage" => "maximize",
             "risk" => "minimize"
           }

    assert %{
             "id" => "dominated",
             "frontier" => false,
             "dominated_by_ids" => ["balanced", "coverage_leader"]
           } = Enum.find(report["rows"], &(&1["id"] == "dominated"))

    assert report["assumptions"]["external_solver"] == false
    assert report["assumptions"]["search_performed"] == false

    assert {:ok, %{"schema_contract" => "pareto_frontier_report.v1"}} =
             Schema.validate_artifact(report)

    assert OrbitalDynamics.pareto_frontier_report(rows,
             objective_directions: %{coverage: "maximize", risk: "minimize"}
           )["frontier_count"] == 3
  end

  test "normalizes clean numeric string objective vectors for Pareto reports" do
    rows = [
      %{
        scenario_id: "coverage_leader",
        objectives: %{coverage: "10.0", risk: "3.0", opaque: "unknown"}
      },
      %{
        scenario_id: "dominated",
        objectives: %{coverage: "7.0", risk: "3.0"}
      }
    ]

    report =
      Optimizer.pareto_frontier_report(rows,
        objective_directions: %{coverage: "maximize", risk: "minimize"}
      )

    assert %{
             "id" => "coverage_leader",
             "objective_keys" => ["coverage", "risk"],
             "objective_values" => %{"coverage" => 10.0, "risk" => 3.0},
             "frontier" => true
           } = Enum.find(report["rows"], &(&1["id"] == "coverage_leader"))

    assert report["dominated_ids"] == ["dominated"]

    assert {:ok, %{"schema_contract" => "pareto_frontier_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "schema rejects incomplete optimizer contracts" do
    invalid = %{
      "schema_contract" => "optimizer_contract.v1",
      "id" => "optimizer_contract:bad",
      "optimizer" => "per_spacecraft_greedy_non_overlapping"
    }

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.objective" and &1["message"] == "is required")
           )
  end

  test "schema rejects incomplete Pareto frontier reports" do
    invalid = %{
      "schema_contract" => "pareto_frontier_report.v1",
      "model" => "objective_vector_pareto_frontier"
    }

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.source" and &1["message"] == "is required")
           )
  end
end
