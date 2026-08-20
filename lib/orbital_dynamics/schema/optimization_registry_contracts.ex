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
