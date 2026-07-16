defmodule OrbitalDynamics.Schema.PolicyEscalationContracts do
  @moduledoc false

  def validate(issues, path, escalation, callbacks) when is_list(callbacks) do
    issues
    |> validate_stable_ids(path, escalation, ["rule_id"], callbacks)
    |> expect_optional_type(path, escalation, "rule_id", :binary, callbacks)
    |> expect_optional_one_of(
      path,
      escalation,
      "classification",
      [
        "auto_approvable",
        "operator_review_required",
        "blocked_by_policy"
      ],
      callbacks
    )
    |> expect_optional_type(path, escalation, "escalation_level", :binary, callbacks)
    |> expect_optional_type(path, escalation, "escalation_queue", :binary, callbacks)
    |> expect_optional_type(path, escalation, "escalation_role", :binary, callbacks)
    |> expect_optional_type(path, escalation, "required_authority", :binary, callbacks)
    |> expect_optional_number(path, escalation, "sla_s", callbacks)
  end

  defp validate_stable_ids(issues, path, map, fields, callbacks),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_optional_type(issues, path, map, field, type, callbacks),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_optional_one_of(issues, path, map, field, allowed, callbacks),
    do:
      apply(require_callback(callbacks, :expect_optional_one_of), [
        issues,
        path,
        map,
        field,
        allowed
      ])

  defp expect_optional_number(issues, path, map, field, callbacks),
    do: apply(require_callback(callbacks, :expect_optional_number), [issues, path, map, field])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
