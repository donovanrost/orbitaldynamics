defmodule OrbitalDynamics.OptimizerTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Optimizer, Schema}
  alias OrbitalDynamics.CampaignPlanner.LocalSearchSelection

  test "declares optimizer contract capabilities" do
    assert %{
             artifact_contract: "optimizer_contract.v1",
             validation_level: :artifact_contract,
             models: ["per_spacecraft_greedy_non_overlapping"],
             local_search_models: local_search_models,
             local_search_generator: :deterministic_bounded_single_axis_step,
             local_search_deterministic_ordering: local_search_deterministic_ordering,
             local_search_model_limits: local_search_model_limits,
             local_search_hard_feasibility: local_search_hard_feasibility,
             public_facades: [:explainable_local_search],
             comparison_models: comparison_models,
             deterministic_ordering: deterministic_ordering,
             preserved_lineage_fields: preserved_lineage_fields,
             known_limits: known_limits
           } = Optimizer.capabilities()

    assert "scenario_ranking_pairwise_delta" in comparison_models
    assert "objective_vector_pareto_frontier" in comparison_models
    assert "deterministic_bounded_axis_step_local_search" in local_search_models
    assert :generation_index_ascending in local_search_deterministic_ordering
    assert "one_neighborhood_generation" in local_search_model_limits
    assert "no_solver_execution" in local_search_model_limits

    assert local_search_hard_feasibility.evidence_registry_contract ==
             "local_search_source_evidence_registry.v1"

    assert local_search_hard_feasibility.evidence_registry_trust_boundary ==
             "caller_supplied_trusted_composition_snapshot"

    assert "caller_supplied_trusted_composition_registry_not_authentication" in local_search_hard_feasibility.model_limits

    assert "no_registry_signature_or_authentication" in local_search_hard_feasibility.model_limits

    assert LocalSearchSelection.numeric_policy_keys() == [
             "target_value_weight",
             "contact_value_weight",
             "eclipse_penalty_weight",
             "downlink_rate_mb_s",
             "activity_count_penalty",
             "required_downlink_mb",
             "downlink_completion_weight",
             "timeline_precondition_weight",
             "resource_projection_weight"
           ]

    assert LocalSearchSelection.selection_contract() ==
             "v1_outer_local_search_inner_greedy"

    assert :score_descending in deterministic_ordering
    assert "source_window" in preserved_lineage_fields
    assert :no_milp_or_cp_sat_solver in known_limits
    assert :ranking_comparison_not_solver_search in known_limits
    assert :pareto_frontier_summary_not_solver_search in known_limits
  end

  test "generates, evaluates, and selects an inspectable local alternative" do
    score_terms_fun = fn parameters ->
      %{
        "apogee_gain_proxy" => parameters["tangential_delta_v_km_s"] * 10_000.0,
        "timing_penalty" => -abs(parameters["burn_epoch_s"] - 65.0)
      }
    end

    result =
      Optimizer.explainable_local_search(
        %{burn_epoch_s: 60.0, tangential_delta_v_km_s: 0.01},
        score_terms_fun,
        steps: %{burn_epoch_s: 5.0, tangential_delta_v_km_s: 0.002},
        bounds: %{burn_epoch_s: {55.0, 65.0}, tangential_delta_v_km_s: {0.0, 0.011}},
        id_prefix: "raise_apogee",
        objective: "maximize apogee gain proxy with timing penalty"
      )

    assert result["model"] == "deterministic_bounded_axis_step_local_search"
    assert result["objective_direction"] == "maximize"
    assert result["seed_score"] == 95.0
    assert result["selected_id"] == "raise_apogee:burn_epoch_s:increase"
    assert result["selected_score"] == 100.0
    assert result["improved"] == true
    assert result["improvement_from_seed"] == 5.0
    assert result["evaluated_count"] == 4

    assert Enum.map(result["alternatives"], & &1["id"]) == [
             "raise_apogee:burn_epoch_s:increase",
             "raise_apogee:seed",
             "raise_apogee:burn_epoch_s:decrease",
             "raise_apogee:tangential_delta_v_km_s:decrease"
           ]

    assert %{
             "rank" => 1,
             "parameters" => %{
               "burn_epoch_s" => 65.0,
               "tangential_delta_v_km_s" => 0.01
             },
             "move" => %{
               "parameter" => "burn_epoch_s",
               "direction" => "increase",
               "from" => 60.0,
               "to" => 65.0
             },
             "score_terms" => %{
               "apogee_gain_proxy" => 100.0,
               "timing_penalty" => -0.0
             },
             "selected" => true,
             "selection_explanation" => "selected_best_score_then_generation_order_then_id"
           } = hd(result["alternatives"])

    assert result["rejected_moves"] == [
             %{
               "id" => "raise_apogee:tangential_delta_v_km_s:increase",
               "generation_index" => 4,
               "move" => %{
                 "type" => "axis_step",
                 "parameter" => "tangential_delta_v_km_s",
                 "direction" => "increase",
                 "delta" => 0.002,
                 "from" => 0.01,
                 "to" => 0.012
               },
               "reason" => "above_maximum_bound"
             }
           ]

    assert result["model_limits"] == Optimizer.local_search_model_limits()
    assert "score_is_sum_of_caller_supplied_terms" in result["model_limits"]

    assert "caller_must_supply_a_pure_deterministic_score_terms_function" in result[
             "model_limits"
           ]

    assert result["assumptions"]["external_solver"] == false
    assert result["assumptions"]["iterations"] == 1
  end

  test "resolves local-search score ties by generation order then alternative id" do
    result =
      Optimizer.explainable_local_search(%{x: 10.0}, fn _parameters -> %{flat: 1.0} end,
        steps: %{x: 2.0},
        id_prefix: "tie"
      )

    assert result["selected_id"] == "tie:seed"
    assert result["improved"] == false

    assert Enum.map(result["alternatives"], &{&1["id"], &1["rank"], &1["selection_explanation"]}) ==
             [
               {"tie:seed", 1, "selected_best_score_then_generation_order_then_id"},
               {"tie:x:decrease", 2, "equal_score_later_generation_order_or_id"},
               {"tie:x:increase", 3, "equal_score_later_generation_order_or_id"}
             ]
  end

  test "rejects invalid local-search scoring and direction inputs" do
    assert_raise ArgumentError, ~r/objective_direction must be/, fn ->
      Optimizer.explainable_local_search(%{x: 1.0}, fn _ -> %{score: 1.0} end,
        steps: %{x: 0.5},
        objective_direction: :sideways
      )
    end

    assert_raise ArgumentError,
                 "score_terms_fun must return a non-empty numeric map for local:seed",
                 fn ->
                   Optimizer.explainable_local_search(%{x: 1.0}, fn _ -> 1.0 end,
                     steps: %{x: 0.5}
                   )
                 end

    assert_raise ArgumentError,
                 "score_terms_fun must return named numeric contributions for local:seed",
                 fn ->
                   Optimizer.explainable_local_search(%{x: 1.0}, fn _ -> %{score: "opaque"} end,
                     steps: %{x: 0.5}
                   )
                 end
  end

  test "repeats identical local-search evaluation through the public facade" do
    score_terms_fun = fn parameters ->
      %{
        target_value: -abs(parameters["x"] - 4.0),
        fixed_cost: -0.25
      }
    end

    opts = [steps: %{x: 1.0}, bounds: %{x: {0.0, 5.0}}, id_prefix: "repeatable"]

    first = OrbitalDynamics.explainable_local_search(%{x: 3.0}, score_terms_fun, opts)
    second = OrbitalDynamics.explainable_local_search(%{"x" => 3.0}, score_terms_fun, opts)

    assert first == second
    assert first["selected_id"] == "repeatable:x:increase"
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
