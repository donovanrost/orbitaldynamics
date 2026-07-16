defmodule OrbitalDynamics.Schema.PolicyBundleContracts do
  @moduledoc false

  def validate(issues, path, bundle, policy_model_limits, callbacks)
      when is_list(policy_model_limits) and is_list(callbacks) do
    approval_policy = Map.get(bundle, "approval_policy", %{})

    issues
    |> validate_stable_ids(path, bundle, ["id"], callbacks)
    |> expect_equal(path, bundle, "schema_contract", "policy_bundle.v1", callbacks)
    |> expect_type(path, bundle, "approval_policy", :map, callbacks)
    |> expect_optional_type(path, bundle, "provenance", :map, callbacks)
    |> expect_optional_type(path, bundle, "assumptions", :map, callbacks)
    |> expect_optional_type(path, bundle, "model_limits", :list, callbacks)
    |> validate_string_list_items(path, bundle, "model_limits", callbacks)
    |> validate_optional_exact_model_limits(
      path,
      bundle,
      policy_model_limits,
      "must match policy model limits",
      callbacks
    )
    |> validate_provenance(path, bundle, callbacks)
    |> validate_assumptions(path, bundle, callbacks)
    |> validate_approval_policy(path <> ".approval_policy", approval_policy, callbacks)
  end

  defp validate_provenance(issues, path, bundle, callbacks) do
    bundle_id = Map.get(bundle, "id")
    provenance_bundle_id = get_in(bundle, ["provenance", "bundle_id"])

    if is_binary(bundle_id) and is_binary(provenance_bundle_id) and
         provenance_bundle_id != bundle_id do
      [error(path <> ".provenance.bundle_id", "must match bundle id", callbacks) | issues]
    else
      issues
    end
  end

  defp validate_assumptions(issues, path, bundle, callbacks) do
    case Map.get(bundle, "assumptions") do
      %{} = assumptions ->
        [
          {"boundary", "artifact_only_no_authority_lookup"},
          {"workflow_execution", "none"}
        ]
        |> Enum.reduce(issues, fn {field, expected}, acc ->
          if Map.has_key?(assumptions, field) and Map.get(assumptions, field) != expected do
            [
              error("#{path}.assumptions.#{field}", "must equal #{inspect(expected)}", callbacks)
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

  defp validate_stable_ids(issues, path, map, fields, callbacks),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_equal(issues, path, map, field, expected, callbacks),
    do: apply(require_callback(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, path, map, field, type, callbacks),
    do: apply(require_callback(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, path, map, field, type, callbacks),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp validate_string_list_items(issues, path, map, field, callbacks),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [
        issues,
        path,
        map,
        field
      ])

  defp validate_optional_exact_model_limits(issues, path, map, expected, message, callbacks),
    do:
      apply(require_callback(callbacks, :validate_optional_exact_model_limits), [
        issues,
        path,
        map,
        expected,
        message
      ])

  defp validate_approval_policy(issues, path, policy, callbacks),
    do: apply(require_callback(callbacks, :validate_approval_policy), [issues, path, policy])

  defp error(path, message, callbacks),
    do: apply(require_callback(callbacks, :error), [path, message])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
