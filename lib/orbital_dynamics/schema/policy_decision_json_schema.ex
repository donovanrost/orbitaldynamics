defmodule OrbitalDynamics.Schema.PolicyDecisionJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @policy_classifications [
    "auto_approvable",
    "operator_review_required",
    "blocked_by_policy"
  ]

  @property_fields [
    "classification",
    "rule_matches",
    "escalations",
    "approval_requirement_count",
    "risk_count",
    "assumptions",
    "model_limits"
  ]

  def property_field?(field) when field in @property_fields, do: true
  def property_field?(_field), do: false

  def property_opts("rule_matches", deps) do
    [policy_decision_rule_match_schema: fetch_dep!(deps, :policy_decision_rule_match_schema)]
  end

  def property_opts("escalations", deps) do
    [policy_escalation_schema: fetch_dep!(deps, :policy_escalation_schema)]
  end

  def property_opts("model_limits", deps) do
    [policy_model_limits: fetch_dep!(deps, :policy_model_limits)]
  end

  def property_opts(_field, _deps), do: []

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property_from_context(field, deps)
    end
  end

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

  def evidence(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "schema_contract" => %{"const" => "policy_decision.v1", "type" => "string"},
        "policy_bundle_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "classification" => %{
          "type" => "string",
          "enum" => @policy_classifications
        },
        "escalations" => %{
          "type" => "array",
          "items" => Keyword.fetch!(opts, :policy_escalation_schema)
        },
        "assumptions" => %{"type" => "object", "additionalProperties" => true},
        "model_limits" => CommonJsonSchema.string_array()
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

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
