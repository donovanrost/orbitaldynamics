defmodule OrbitalDynamics.Schema.OptimizationRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "branch_comparison_report.v1" => %{
        "schema_contract" => "branch_comparison_report.v1",
        "artifact_family" => "branch_comparison_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source",
          "branch_count",
          "recommended_branch_id",
          "rows",
          "assumptions"
        ],
        "optional_fields" => [
          "model_limits",
          "recommendation_eligibility_mode",
          "recommendation_status",
          "eligible_ranked_branch_ids"
        ],
        "nested_contracts" => []
      },
      "optimizer_contract.v1" => %{
        "schema_contract" => "optimizer_contract.v1",
        "artifact_family" => "optimizer_contract",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "id",
          "optimizer",
          "objective",
          "selection_policy",
          "candidate_count",
          "ranked_timeline_count",
          "selected_activity_count",
          "selected_activity_ids",
          "assumptions"
        ],
        "optional_fields" => [
          "candidate_activity_ids",
          "ranked_scenario_ids",
          "score_term_keys",
          "deterministic_ordering",
          "preserved_lineage_fields",
          "constraints",
          "scoring_policy",
          "known_limits"
        ],
        "nested_contracts" => []
      },
      "local_search_optimization_certificate.v1" => %{
        "schema_contract" => "local_search_optimization_certificate.v1",
        "artifact_family" => "local_search_optimization_certificate",
        "schema_version" => 1,
        "additional_properties" => false,
        "required_fields" => [
          "schema_contract",
          "id",
          "model",
          "objective",
          "objective_direction",
          "claim",
          "global_optimality_claimed",
          "search_space",
          "source_evidence_registry",
          "evaluation_budget",
          "budget_used",
          "budget_remaining",
          "budget_limited",
          "search_space_exhausted",
          "termination_reason",
          "evaluated_count",
          "eligible_count",
          "rejected_count",
          "unevaluated_count",
          "selected_alternative_id",
          "selected_score",
          "eligible_ids_by_rank",
          "evaluations",
          "deterministic_ordering",
          "incumbent_update_rule",
          "model_limits",
          "assumptions"
        ],
        "optional_fields" => [],
        "nested_contracts" => []
      },
      "constraint_report.v1" => %{
        "schema_contract" => "constraint_report.v1",
        "artifact_family" => "constraint_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "constraint_count",
          "row_count",
          "status",
          "status_counts",
          "rows",
          "assumptions"
        ],
        "optional_fields" => ["model_limits"],
        "nested_contracts" => []
      },
      "score_term_report.v1" => %{
        "schema_contract" => "score_term_report.v1",
        "artifact_family" => "score_term_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source",
          "row_count",
          "score_term_keys",
          "rows",
          "assumptions"
        ],
        "optional_fields" => ["model_limits"],
        "nested_contracts" => []
      }
    }
  end
end
