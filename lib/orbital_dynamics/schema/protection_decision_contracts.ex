defmodule OrbitalDynamics.Schema.ProtectionDecisionContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation
  alias OrbitalDynamics.Schema.StableIdValidation

  def validate_optional(issues, path, map, field) when is_map(map) do
    case Map.get(map, field) do
      %{} = decision -> validate_decision(issues, "#{path}.#{field}", decision)
      _value -> issues
    end
  end

  def validate_lifecycle_state_consistency(issues, path, state, prefix) when is_map(state) do
    field = "#{prefix}_protection_decision"

    case Map.get(state, field) do
      %{} = decision ->
        decision_path = "#{path}.#{field}"

        issues
        |> expect_lifecycle_protection_locked_flag(decision_path, state, decision, prefix)
        |> expect_lifecycle_protection_approved_flag(decision_path, state, decision, prefix)
        |> expect_lifecycle_protection_category(decision_path, state, decision, prefix)

      _decision ->
        issues
    end
  end

  defp validate_decision(issues, path, decision) do
    issues
    |> StableIdValidation.validate_stable_ids(path, decision, ["activity_id", "timeline_id"])
    |> PrimitiveValidation.expect_optional_type(path, decision, "status", :binary)
    |> PrimitiveValidation.expect_optional_type(path, decision, "approval_status", :binary)
    |> PrimitiveValidation.expect_optional_type(path, decision, "locked", :boolean)
    |> PrimitiveValidation.expect_optional_type(path, decision, "approved", :boolean)
    |> PrimitiveValidation.expect_optional_type(path, decision, "timeline_identity", :map)
    |> PrimitiveValidation.expect_optional_type(
      path,
      decision,
      "invalid_activity_input",
      :boolean
    )
    |> PrimitiveValidation.expect_optional_type(
      path,
      decision,
      "invalid_activity_input_reason",
      :binary
    )
    |> PrimitiveValidation.expect_optional_type(path, decision, "protection_decision", :binary)
    |> PrimitiveValidation.expect_optional_type(path, decision, "protection_category", :binary)
    |> PrimitiveValidation.expect_optional_type(path, decision, "reason", :binary)
  end

  defp expect_lifecycle_protection_locked_flag(issues, path, state, decision, prefix) do
    case Map.get(state, "#{prefix}_locked") do
      locked when is_boolean(locked) ->
        PrimitiveValidation.expect_optional_field_equals(
          issues,
          path,
          decision,
          "locked",
          locked,
          "must equal lifecycle-state #{prefix}_locked"
        )

      _locked ->
        issues
    end
  end

  defp expect_lifecycle_protection_approved_flag(issues, path, state, decision, prefix) do
    expected =
      case Map.get(state, "#{prefix}_approval_category") do
        "protected" -> true
        category when is_binary(category) -> false
        _category -> nil
      end

    if is_boolean(expected) do
      PrimitiveValidation.expect_optional_field_equals(
        issues,
        path,
        decision,
        "approved",
        expected,
        "must equal lifecycle-state #{prefix}_approval_category"
      )
    else
      issues
    end
  end

  defp expect_lifecycle_protection_category(issues, path, state, decision, prefix) do
    cond do
      Map.get(state, "#{prefix}_executed") == true ->
        issues
        |> PrimitiveValidation.expect_optional_field_equals(
          path,
          decision,
          "protection_decision",
          "preserve",
          "must preserve executed lifecycle-state protection"
        )
        |> PrimitiveValidation.expect_optional_field_equals(
          path,
          decision,
          "protection_category",
          "executed",
          "must classify executed lifecycle-state protection"
        )

      lifecycle_state_locked_or_approved?(state, prefix) ->
        issues
        |> PrimitiveValidation.expect_optional_field_equals(
          path,
          decision,
          "protection_category",
          "locked_or_approved",
          "must classify locked or approved lifecycle-state protection"
        )
        |> expect_lifecycle_locked_or_approved_decision(path, decision)

      decision["invalid_activity_input"] == true ->
        issues
        |> PrimitiveValidation.expect_optional_field_equals(
          path,
          decision,
          "protection_decision",
          "review_change",
          "must review invalid lifecycle-state protection"
        )
        |> PrimitiveValidation.expect_optional_field_equals(
          path,
          decision,
          "protection_category",
          "invalid_activity_input",
          "must classify invalid lifecycle-state protection"
        )

      true ->
        issues
    end
  end

  defp lifecycle_state_locked_or_approved?(state, prefix) do
    Map.get(state, "#{prefix}_locked") == true or
      Map.get(state, "#{prefix}_approval_category") == "protected"
  end

  defp expect_lifecycle_locked_or_approved_decision(issues, path, decision) do
    if Map.has_key?(decision, "protection_decision") and
         decision["protection_decision"] not in ["preserve", "review_change"] do
      [
        PrimitiveValidation.error(
          "#{path}.protection_decision",
          "must preserve or review locked or approved lifecycle-state protection"
        )
        | issues
      ]
    else
      issues
    end
  end
end
