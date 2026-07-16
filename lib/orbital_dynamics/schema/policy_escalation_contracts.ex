defmodule OrbitalDynamics.Schema.PolicyEscalationContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [expect_optional_number: 4, expect_optional_one_of: 5, expect_optional_type: 5]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  def validate(issues, path, escalation) do
    issues
    |> validate_stable_ids(path, escalation, ["rule_id"])
    |> expect_optional_type(path, escalation, "rule_id", :binary)
    |> expect_optional_one_of(
      path,
      escalation,
      "classification",
      [
        "auto_approvable",
        "operator_review_required",
        "blocked_by_policy"
      ]
    )
    |> expect_optional_type(path, escalation, "escalation_level", :binary)
    |> expect_optional_type(path, escalation, "escalation_queue", :binary)
    |> expect_optional_type(path, escalation, "escalation_role", :binary)
    |> expect_optional_type(path, escalation, "required_authority", :binary)
    |> expect_optional_number(path, escalation, "sla_s")
  end
end
