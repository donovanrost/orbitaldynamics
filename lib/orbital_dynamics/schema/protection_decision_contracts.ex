defmodule OrbitalDynamics.Schema.ProtectionDecisionContracts do
  @moduledoc false

  def validate_optional(issues, path, map, field, callbacks)
      when is_map(map) and is_list(callbacks) do
    case Map.get(map, field) do
      %{} = decision -> validate_decision(issues, "#{path}.#{field}", decision, callbacks)
      _value -> issues
    end
  end

  def validate_lifecycle_state_consistency(issues, path, state, prefix, callbacks)
      when is_map(state) and is_list(callbacks) do
    field = "#{prefix}_protection_decision"

    case Map.get(state, field) do
      %{} = decision ->
        decision_path = "#{path}.#{field}"

        issues
        |> expect_lifecycle_protection_locked_flag(
          callbacks,
          decision_path,
          state,
          decision,
          prefix
        )
        |> expect_lifecycle_protection_approved_flag(
          callbacks,
          decision_path,
          state,
          decision,
          prefix
        )
        |> expect_lifecycle_protection_category(
          callbacks,
          decision_path,
          state,
          decision,
          prefix
        )

      _decision ->
        issues
    end
  end

  defp validate_decision(issues, path, decision, callbacks) do
    issues
    |> validate_stable_ids(callbacks, path, decision, ["activity_id", "timeline_id"])
    |> expect_optional_type(callbacks, path, decision, "status", :binary)
    |> expect_optional_type(callbacks, path, decision, "approval_status", :binary)
    |> expect_optional_type(callbacks, path, decision, "locked", :boolean)
    |> expect_optional_type(callbacks, path, decision, "approved", :boolean)
    |> expect_optional_type(callbacks, path, decision, "timeline_identity", :map)
    |> expect_optional_type(callbacks, path, decision, "invalid_activity_input", :boolean)
    |> expect_optional_type(callbacks, path, decision, "invalid_activity_input_reason", :binary)
    |> expect_optional_type(callbacks, path, decision, "protection_decision", :binary)
    |> expect_optional_type(callbacks, path, decision, "protection_category", :binary)
    |> expect_optional_type(callbacks, path, decision, "reason", :binary)
  end

  defp expect_lifecycle_protection_locked_flag(issues, callbacks, path, state, decision, prefix) do
    case Map.get(state, "#{prefix}_locked") do
      locked when is_boolean(locked) ->
        expect_optional_field_equals(
          issues,
          callbacks,
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

  defp expect_lifecycle_protection_approved_flag(
         issues,
         callbacks,
         path,
         state,
         decision,
         prefix
       ) do
    expected =
      case Map.get(state, "#{prefix}_approval_category") do
        "protected" -> true
        category when is_binary(category) -> false
        _category -> nil
      end

    if is_boolean(expected) do
      expect_optional_field_equals(
        issues,
        callbacks,
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

  defp expect_lifecycle_protection_category(issues, callbacks, path, state, decision, prefix) do
    cond do
      Map.get(state, "#{prefix}_executed") == true ->
        issues
        |> expect_optional_field_equals(
          callbacks,
          path,
          decision,
          "protection_decision",
          "preserve",
          "must preserve executed lifecycle-state protection"
        )
        |> expect_optional_field_equals(
          callbacks,
          path,
          decision,
          "protection_category",
          "executed",
          "must classify executed lifecycle-state protection"
        )

      lifecycle_state_locked_or_approved?(state, prefix) ->
        issues
        |> expect_optional_field_equals(
          callbacks,
          path,
          decision,
          "protection_category",
          "locked_or_approved",
          "must classify locked or approved lifecycle-state protection"
        )
        |> expect_lifecycle_locked_or_approved_decision(callbacks, path, decision)

      decision["invalid_activity_input"] == true ->
        issues
        |> expect_optional_field_equals(
          callbacks,
          path,
          decision,
          "protection_decision",
          "review_change",
          "must review invalid lifecycle-state protection"
        )
        |> expect_optional_field_equals(
          callbacks,
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

  defp expect_lifecycle_locked_or_approved_decision(issues, callbacks, path, decision) do
    if Map.has_key?(decision, "protection_decision") and
         decision["protection_decision"] not in ["preserve", "review_change"] do
      [
        error(
          callbacks,
          "#{path}.protection_decision",
          "must preserve or review locked or approved lifecycle-state protection"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [
        issues,
        path,
        map,
        field,
        type
      ])

  defp expect_optional_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(require_callback(callbacks, :expect_optional_field_equals), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp error(callbacks, path, message),
    do: apply(require_callback(callbacks, :error), [path, message])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
