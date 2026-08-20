defmodule OrbitalDynamics.Schema.StrategyManeuverRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "strategy_recommendation.v1" => %{
        "schema_contract" => "strategy_recommendation.v1",
        "artifact_family" => "strategy_recommendation",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "recommended_branch_id",
          "approval_status",
          "reason",
          "ranked_branch_ids",
          "tradeoffs",
          "explanation",
          "risks_remaining",
          "requires_approval"
        ],
        "optional_fields" => [
          "status",
          "eligibility_status",
          "authority_context",
          "authority_context_evaluation",
          "counterfactual"
        ],
        "nested_contracts" => ["approval_requirement.v1", "authority_context.v1"]
      },
      "maneuver_recommendation.v1" => %{
        "schema_contract" => "maneuver_recommendation.v1",
        "artifact_family" => "maneuver_recommendation",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "id",
          "scenario_id",
          "type",
          "epoch_s",
          "frame",
          "delta_v_km_s",
          "maneuver_model",
          "assumptions"
        ],
        "optional_fields" => [
          "delta_v_magnitude_km_s",
          "epoch_scale",
          "model_limits",
          "validation_level"
        ],
        "nested_contracts" => []
      },
      "maneuver_review_report.v1" => %{
        "schema_contract" => "maneuver_review_report.v1",
        "artifact_family" => "maneuver_review_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source",
          "maneuver_count",
          "review_required_count",
          "total_delta_v_km_s",
          "rows",
          "assumptions"
        ],
        "optional_fields" => [
          "approval_status_counts",
          "execution_uncertainty_declared_count",
          "execution_uncertainty_missing_count",
          "invalid_maneuver_recommendation_count",
          "invalid_maneuver_recommendation_ids",
          "model_limits",
          "required_operator_action_counts",
          "source_artifact_id"
        ],
        "nested_contracts" => ["maneuver_recommendation.v1"]
      }
    }
  end
end
