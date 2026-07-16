defmodule OrbitalDynamics.Schema.ObjectiveAnalysisRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "objective_tradeoff_report.v1" => %{
        "schema_contract" => "objective_tradeoff_report.v1",
        "artifact_family" => "objective_tradeoff_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "objective",
          "ranking_count",
          "score_term_keys",
          "tradeoffs",
          "assumptions"
        ],
        "optional_fields" => ["model_limits", "policy"],
        "nested_contracts" => []
      },
      "objective_satisfaction_report.v1" => %{
        "schema_contract" => "objective_satisfaction_report.v1",
        "artifact_family" => "objective_satisfaction_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source",
          "objective_count",
          "rows",
          "assumptions"
        ],
        "optional_fields" => ["model_limits"],
        "nested_contracts" => []
      },
      "ranking_comparison_report.v1" => %{
        "schema_contract" => "ranking_comparison_report.v1",
        "artifact_family" => "ranking_comparison_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source",
          "objective",
          "left_label",
          "right_label",
          "left_count",
          "right_count",
          "matched_count",
          "left_only_count",
          "right_only_count",
          "row_count",
          "winner",
          "rows",
          "assumptions"
        ],
        "optional_fields" => ["model_limits", "objective_direction"],
        "nested_contracts" => []
      },
      "pareto_frontier_report.v1" => %{
        "schema_contract" => "pareto_frontier_report.v1",
        "artifact_family" => "pareto_frontier_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source",
          "alternative_count",
          "objective_count",
          "frontier_count",
          "dominated_count",
          "frontier_ids",
          "dominated_ids",
          "objective_directions",
          "rows",
          "assumptions"
        ],
        "optional_fields" => ["model_limits"],
        "nested_contracts" => []
      }
    }
  end
end
