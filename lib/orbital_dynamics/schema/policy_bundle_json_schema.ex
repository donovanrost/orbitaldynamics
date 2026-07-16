defmodule OrbitalDynamics.Schema.PolicyBundleJsonSchema do
  @moduledoc false

  @property_fields [
    "approval_policy",
    "model_limits"
  ]

  def property_field?(field) when field in @property_fields, do: true
  def property_field?(_field), do: false

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property_from_context(field, deps)
    end
  end

  def property_opts("approval_policy", deps) do
    [policy_action_rule_schema: fetch_dep!(deps, :policy_action_rule_schema)]
  end

  def property_opts("model_limits", deps) do
    [policy_model_limits: fetch_dep!(deps, :policy_model_limits)]
  end

  def property_opts(_field, _deps), do: []

  def property("approval_policy", opts) do
    OrbitalDynamics.Schema.PolicyDecisionJsonSchema.approval_policy(
      policy_action_rule_schema: Keyword.fetch!(opts, :policy_action_rule_schema)
    )
  end

  def property("model_limits", opts) do
    OrbitalDynamics.Schema.PolicyDecisionJsonSchema.property("model_limits",
      policy_model_limits: Keyword.fetch!(opts, :policy_model_limits)
    )
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
