defmodule OrbitalDynamics.Schema.PolicyDecisionJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @policy_classifications [
    "auto_approvable",
    "operator_review_required",
    "blocked_by_policy"
  ]

  def approval_policy(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "auto_approvable_risk_limit" => %{"type" => "number"},
        "auto_approvable_approval_count_limit" => %{"type" => "number"},
        "operator_review_risk_limit" => %{"type" => "number"},
        "blocked_risk_types" => CommonJsonSchema.string_array(),
        "action_rules" => %{
          "type" => "array",
          "items" => Keyword.fetch!(opts, :policy_action_rule_schema)
        }
      }
    }
  end

  def property("classification", _opts) do
    %{"type" => "string", "enum" => @policy_classifications}
  end

  def property("rule_matches", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :policy_decision_rule_match_schema)
    }
  end

  def property("escalations", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :policy_escalation_schema)
    }
  end

  def property(field, _opts) when field in ["approval_requirement_count", "risk_count"] do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("assumptions", _opts) do
    %{"type" => "object", "additionalProperties" => true}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :policy_model_limits)

    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end
end
