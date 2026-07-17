defmodule OrbitalDynamics.Validation.ReferenceFixtures.DecisionSupportArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.maneuver_review_report.v1" => %{
      "id" => "fixture.artifact.maneuver_review_report.v1",
      "model_id" => "artifact.maneuver_review_report.v1",
      "reference_case" => "checked-in maneuver review artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/maneuver_review_report_v1.json",
        "contract" => "maneuver_review_report.v1"
      },
      "expected" => %{
        "schema_contract" => "maneuver_review_report.v1",
        "model" => "artifact_only_maneuver_review_report",
        "source" => "study_results/mission_plan_checkout.json.maneuver_recommendations",
        "source_artifact_id" => "mission_plan_checkout",
        "maneuver_count" => 1,
        "row_count" => 1,
        "review_required_count" => 1,
        "invalid_maneuver_recommendation_count" => 0,
        "invalid_maneuver_recommendation_id_count" => 0,
        "execution_uncertainty_declared_count" => 0,
        "execution_uncertainty_missing_count" => 1,
        "total_delta_v_km_s" => 0.01,
        "approval_status_counts" => %{"operator_review_required" => 1},
        "required_operator_action_counts" => %{"review_maneuver_recommendation" => 1},
        "execution_uncertainty_status_counts" => %{"missing" => 1},
        "maneuver_review_ids_by_required_operator_action" => %{
          "review_maneuver_recommendation" => ["maneuver_review:ops_checkout:trim_burn"]
        },
        "execution_boundary" => "recommendation_only_no_command_execution",
        "review_boundary" => "review_only_no_command_execution",
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "maneuver_count" => 0,
        "row_count" => 0,
        "review_required_count" => 0,
        "invalid_maneuver_recommendation_count" => 0,
        "invalid_maneuver_recommendation_id_count" => 0,
        "execution_uncertainty_declared_count" => 0,
        "execution_uncertainty_missing_count" => 0,
        "total_delta_v_km_s" => 0.0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not maneuver execution validation",
        "checks maneuver review counts, operator-action routing, and no-command boundary only"
      ]
    },
    "fixture.artifact.monte_carlo_reproducibility_report.v1" => %{
      "id" => "fixture.artifact.monte_carlo_reproducibility_report.v1",
      "model_id" => "artifact.monte_carlo_reproducibility_report.v1",
      "reference_case" => "checked-in Monte Carlo reproducibility artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/monte_carlo_reproducibility_report_v1.json",
        "contract" => "monte_carlo_reproducibility_report.v1"
      },
      "expected" => %{
        "schema_contract" => "monte_carlo_reproducibility_report.v1",
        "model" => "seeded_independent_normal_cartesian_dispersion",
        "source" => "study_metadata.monte_carlo",
        "generator" => "state_vector_dispersion",
        "requested_count" => 20,
        "generated_scenario_count" => 20,
        "generated_scenario_id_count" => 20,
        "first_generated_scenario_id" => "dispersion_1",
        "last_generated_scenario_id" => "dispersion_20",
        "deterministic_seed" => true,
        "seed" => 12345,
        "rng" => "rand_exsss",
        "sampling_method" => "box_muller_transform",
        "id_prefix" => "dispersion",
        "position_sigma_km" => [0.1, 0.1, 0.05],
        "velocity_sigma_km_s" => [0.0001, 0.0001, 0.00005],
        "distribution" => "independent normal per Cartesian component",
        "covariance_model" => "none",
        "model_limit_count" => 4,
        "known_limit_count" => 4
      },
      "tolerances" => %{
        "requested_count" => 0,
        "generated_scenario_count" => 0,
        "generated_scenario_id_count" => 0,
        "seed" => 0,
        "position_sigma_km" => 0.0,
        "velocity_sigma_km_s" => 0.0,
        "model_limit_count" => 0,
        "known_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not statistical validation",
        "checks seeded reproducibility counts, RNG metadata, dispersion sigmas, and model-limit boundary only"
      ]
    },
    "fixture.artifact.pareto_frontier_report.v1" => %{
      "id" => "fixture.artifact.pareto_frontier_report.v1",
      "model_id" => "artifact.pareto_frontier_report.v1",
      "reference_case" => "checked-in Pareto frontier artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/pareto_frontier_report_v1.json",
        "contract" => "pareto_frontier_report.v1"
      },
      "expected" => %{
        "schema_contract" => "pareto_frontier_report.v1",
        "model" => "objective_vector_pareto_frontier",
        "source" => "strategy.branch_objectives",
        "alternative_count" => 4,
        "row_count" => 4,
        "frontier_count" => 3,
        "dominated_count" => 1,
        "objective_count" => 2,
        "objective_directions" => %{"coverage" => "maximize", "risk" => "minimize"},
        "frontier_status_counts" => %{"false" => 1, "true" => 3},
        "objective_key_count_counts" => %{"0" => 1, "2" => 3},
        "alternative_ids_by_frontier_status" => %{
          "false" => ["dominated"],
          "true" => ["balanced", "coverage_leader", "ignored_no_numeric"]
        },
        "missing_objective_policy" => "alternative_with_missing_objective_cannot_dominate",
        "search_performed" => false,
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "alternative_count" => 0,
        "row_count" => 0,
        "frontier_count" => 0,
        "dominated_count" => 0,
        "objective_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external optimizer validation",
        "checks deterministic frontier counts, dominance routing, and no-solver boundary only"
      ]
    }
  }

  def all, do: @fixtures
end
