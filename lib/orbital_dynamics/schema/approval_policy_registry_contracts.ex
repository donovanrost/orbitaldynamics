defmodule OrbitalDynamics.Schema.ApprovalPolicyRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "authority_context.v1" => %{
        "schema_contract" => "authority_context.v1",
        "artifact_family" => "authority_context",
        "schema_version" => 1,
        "required_fields" => OrbitalDynamics.AuthorityContext.required_fields(),
        "optional_fields" => [],
        "nested_contracts" => []
      },
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
          "eligibility_status",
          "authority_context",
          "authority_context_evaluation",
          "assumptions",
          "model_limits"
        ],
        "nested_contracts" => ["approval_requirement.v1", "authority_context.v1"]
      },
      "policy_bundle.v1" => %{
        "schema_contract" => "policy_bundle.v1",
        "artifact_family" => "policy_bundle",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "id",
          "approval_policy"
        ],
        "optional_fields" => [
          "description",
          "provenance",
          "assumptions",
          "model_limits"
        ],
        "nested_contracts" => ["policy_decision.v1", "approval_requirement.v1"]
      }
    }
  end
end
