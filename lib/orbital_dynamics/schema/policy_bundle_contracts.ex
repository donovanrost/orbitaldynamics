defmodule OrbitalDynamics.Schema.PolicyBundleContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_optional_type: 5,
      expect_type: 5,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  def validate(issues, path, bundle, policy_model_limits, action_rule_field_groups)
      when is_list(policy_model_limits) and is_list(action_rule_field_groups) do
    approval_policy = Map.get(bundle, "approval_policy", %{})

    issues
    |> validate_stable_ids(path, bundle, ["id"])
    |> expect_equal(path, bundle, "schema_contract", "policy_bundle.v1")
    |> expect_type(path, bundle, "approval_policy", :map)
    |> expect_optional_type(path, bundle, "provenance", :map)
    |> expect_optional_type(path, bundle, "assumptions", :map)
    |> expect_optional_type(path, bundle, "model_limits", :list)
    |> validate_string_list_items(path, bundle, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      bundle,
      policy_model_limits,
      "must match policy model limits"
    )
    |> validate_provenance(path, bundle)
    |> validate_assumptions(path, bundle)
    |> OrbitalDynamics.Schema.PolicyActionRuleContracts.validate_approval_policy(
      path <> ".approval_policy",
      approval_policy,
      action_rule_field_groups
    )
  end

  defp validate_provenance(issues, path, bundle) do
    bundle_id = Map.get(bundle, "id")
    provenance_bundle_id = get_in(bundle, ["provenance", "bundle_id"])

    if is_binary(bundle_id) and is_binary(provenance_bundle_id) and
         provenance_bundle_id != bundle_id do
      [error(path <> ".provenance.bundle_id", "must match bundle id") | issues]
    else
      issues
    end
  end

  defp validate_assumptions(issues, path, bundle) do
    case Map.get(bundle, "assumptions") do
      %{} = assumptions ->
        [
          {"boundary", "artifact_only_no_authority_lookup"},
          {"workflow_execution", "none"}
        ]
        |> Enum.reduce(issues, fn {field, expected}, acc ->
          if Map.has_key?(assumptions, field) and Map.get(assumptions, field) != expected do
            [
              error("#{path}.assumptions.#{field}", "must equal #{inspect(expected)}")
              | acc
            ]
          else
            acc
          end
        end)

      _assumptions ->
        issues
    end
  end
end
