defmodule OrbitalDynamics.Validation.ReferenceFixtures.ObjectiveScoringArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.objective_satisfaction_report.v1" => %{
      "id" => "fixture.artifact.objective_satisfaction_report.v1",
      "model_id" => "artifact.objective_satisfaction_report.v1",
      "reference_case" => "checked-in objective satisfaction artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/objective_satisfaction_report_v1.json",
        "contract" => "objective_satisfaction_report.v1"
      },
      "expected" => %{
        "schema_contract" => "objective_satisfaction_report.v1",
        "model" => "campaign_v1_selected_activity_objective_summary",
        "source" => "campaign_plan.activities",
        "objective_count" => 4,
        "row_count" => 4,
        "selected_count_total" => 2,
        "satisfied_count_total" => 2,
        "required_count_total" => 4,
        "status_counts" => %{
          "no_candidate_window" => 1,
          "partial" => 1,
          "selected" => 1,
          "unmet" => 1
        },
        "objective_type_counts" => %{
          "downlink_completion" => 1,
          "target_commitment" => 2,
          "target_coverage" => 1
        },
        "objective_ids_by_status" => %{
          "no_candidate_window" => ["objective:target_commitment:target_b"],
          "partial" => ["objective:target_coverage"],
          "selected" => ["objective:target_commitment:target_a"],
          "unmet" => ["objective:downlink_completion"]
        },
        "execution_status" => "planned_not_executed",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "objective_count" => 0,
        "row_count" => 0,
        "selected_count_total" => 0,
        "satisfied_count_total" => 0,
        "required_count_total" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not objective-achievement validation",
        "checks objective satisfaction counts, status routing maps, planned-not-executed boundary, and model-limit boundary only"
      ]
    },
    "fixture.artifact.objective_tradeoff_report.v1" => %{
      "id" => "fixture.artifact.objective_tradeoff_report.v1",
      "model_id" => "artifact.objective_tradeoff_report.v1",
      "reference_case" => "checked-in objective tradeoff artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/objective_tradeoff_report_v1.json",
        "contract" => "objective_tradeoff_report.v1"
      },
      "expected" => %{
        "schema_contract" => "objective_tradeoff_report.v1",
        "model" => "ranked_timeline_score_term_tradeoffs",
        "objective" => "maximize weighted observation value and contact value",
        "ranking_count" => 1,
        "tradeoff_row_count" => 1,
        "score_term_key_count" => 7,
        "activity_count_total" => 1,
        "selected_observation_count_total" => 1,
        "selected_contact_count_total" => 0,
        "score_total" => 1417.2731832107565,
        "score_delta_from_selected_total" => 0.0,
        "scenario_ids_by_rank" => %{"1" => ["leo_1"]},
        "score_term_key_counts" => %{
          "activity_count_penalty" => 1,
          "activity_score" => 1,
          "contact_value" => 1,
          "eclipse_penalty" => 1,
          "selected_contact_count" => 1,
          "selected_observation_count" => 1,
          "target_value" => 1
        },
        "selection_assumption" => "best_ranked_timeline_is_selected",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "ranking_count" => 0,
        "tradeoff_row_count" => 0,
        "score_term_key_count" => 0,
        "activity_count_total" => 0,
        "selected_observation_count_total" => 0,
        "selected_contact_count_total" => 0,
        "score_total" => 0.0,
        "score_delta_from_selected_total" => 0.0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not optimizer validation",
        "checks objective tradeoff counts, score-term shape, selected-ranking assumptions, and model-limit boundary only"
      ]
    },
    "fixture.artifact.score_term_report.v1" => %{
      "id" => "fixture.artifact.score_term_report.v1",
      "model_id" => "artifact.score_term_report.v1",
      "reference_case" => "checked-in score term artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/score_term_report_v1.json",
        "contract" => "score_term_report.v1"
      },
      "expected" => %{
        "schema_contract" => "score_term_report.v1",
        "model" => "ranked_timeline_score_terms",
        "source" => "campaign_plan.ranked_timelines",
        "row_count" => 7,
        "derived_row_count" => 7,
        "selected_row_count" => 7,
        "score_term_key_count" => 7,
        "score_term_key_counts" => %{
          "activity_count_penalty" => 1,
          "activity_score" => 1,
          "contact_value" => 1,
          "eclipse_penalty" => 1,
          "selected_contact_count" => 1,
          "selected_observation_count" => 1,
          "target_value" => 1
        },
        "row_derived_score_term_key_counts" => %{
          "activity_count_penalty" => 1,
          "activity_score" => 1,
          "contact_value" => 1,
          "eclipse_penalty" => 1,
          "selected_contact_count" => 1,
          "selected_observation_count" => 1,
          "target_value" => 1
        },
        "term_value_total" => 2835.546366421513,
        "timeline_score_total" => 9920.912282475295,
        "score_term_source" => "ranked_timeline.score_terms",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "row_count" => 0,
        "derived_row_count" => 0,
        "selected_row_count" => 0,
        "score_term_key_count" => 0,
        "term_value_total" => 0.0,
        "timeline_score_total" => 0.0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not score-policy validation",
        "checks score-term row counts, key shape, selected-row counts, score totals, and model-limit boundary only"
      ]
    },
    "fixture.artifact.ranking_comparison_report.v1" => %{
      "id" => "fixture.artifact.ranking_comparison_report.v1",
      "model_id" => "artifact.ranking_comparison_report.v1",
      "reference_case" => "checked-in ranking comparison artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/ranking_comparison_report_v1.json",
        "contract" => "ranking_comparison_report.v1"
      },
      "expected" => %{
        "schema_contract" => "ranking_comparison_report.v1",
        "model" => "scenario_ranking_pairwise_delta",
        "source" => "study_benchmark.rankings",
        "objective" => "final_radius_km",
        "objective_direction" => "maximize",
        "left_count" => 2,
        "right_count" => 2,
        "matched_count" => 1,
        "left_only_count" => 1,
        "right_only_count" => 1,
        "row_count" => 3,
        "derived_row_count" => 3,
        "status_counts" => %{"left_only" => 1, "matched" => 1, "right_only" => 1},
        "scenario_ids_by_status" => %{
          "left_only" => ["burn_a"],
          "matched" => ["burn_b"],
          "right_only" => ["burn_c"]
        },
        "rank_delta_total" => 1,
        "value_delta_total" => 15,
        "winner_changed" => true,
        "external_solver" => false,
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "left_count" => 0,
        "right_count" => 0,
        "matched_count" => 0,
        "left_only_count" => 0,
        "right_only_count" => 0,
        "row_count" => 0,
        "derived_row_count" => 0,
        "rank_delta_total" => 0,
        "value_delta_total" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not optimizer validation",
        "checks ranking comparison counts, status routing, winner-change evidence, and model-limit boundary only"
      ]
    }
  }

  def all, do: @fixtures
end
