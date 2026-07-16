defmodule OrbitalDynamics.Schema.ApprovalPolicyRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "approval_requirement.v1" => %{
        "schema_contract" => "approval_requirement.v1",
        "artifact_family" => "approval_requirement",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "activity_id",
          "activity_type",
          "action",
          "reason"
        ],
        "optional_fields" => [
          "activity_context",
          "approval_rule_matches",
          "policy_bundle_id",
          "policy_classification",
          "policy_decision",
          "required_authority",
          "requirement_type",
          "rule_id"
        ],
        "nested_contracts" => []
      },
      "policy_decision.v1" => %{
        "schema_contract" => "policy_decision.v1",
        "artifact_family" => "policy_decision",
        "schema_version" => 1,
        "required_fields" => ["schema_contract", "classification"],
        "optional_fields" => [
          "policy_bundle_id",
          "rule_matches",
          "escalations",
          "approval_requirement_count",
          "risk_count",
          "fallback_policy",
          "assumptions",
          "model_limits"
        ],
        "nested_contracts" => ["approval_requirement.v1"]
      }
    }
  end
end
